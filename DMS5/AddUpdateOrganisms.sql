/****** Object:  StoredProcedure [dbo].[AddUpdateOrganisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.AddUpdateOrganisms
/****************************************************
**
**  Desc: Adds new or edits existing Organisms
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**  Date:	03/07/2006
**			01/12/2007 jds - Added support for new field OG_Active
**			01/12/2007 mem - Added validation that genus, species, and strain are not duplicated in T_Organisms
**			10/16/2007 mem - Updated to allow genus, species, and strain to all be 'na' (Ticket #562)
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**			09/12/2008 mem - Updated to call ValidateNAParameter to validate genus, species, and strain (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**			09/09/2009 mem - No longer populating field OG_organismDBLocalPath
**			11/20/2009 mem - Removed parameter @orgDBLocalPath
**			12/03/2009 mem - Now making sure that @orgDBPath starts with two slashes and ends with one slash
**			08/04/2010 grk - try-catch for error handling
**			08/01/2012 mem - Now calling RefreshCachedOrganisms in MT_Main on ProteinSeqs
**			09/25/2012 mem - Expanded @orgName and @orgDBName to varchar(128)
**			11/20/2012 mem - No longer allowing @orgDBName to contain '.fasta' 
**			05/10/2013 mem - Added @NEWTIdentifier
**			05/13/2013 mem - Now validating @NEWTIdentifier against S_V_CV_NEWT
**			05/24/2013 mem - Added @NEWTIDList
**			10/15/2014 mem - Removed @orgDBPath and added validation logic to @orgStorageLocation
**			06/25/2015 mem - Now validating that the protein collection specified by @orgDBName exists
**			09/10/2015 mem - Switch to using synonym S_MT_Main_RefreshCachedOrganisms
**			02/23/2016 mem - Add set XACT_ABORT on
**			02/26/2016 mem - Check for @orgName containing a space
**			03/01/2016 mem - Added @NCBITaxonomyID
**			03/02/2016 mem - Added @AutoDefineTaxonomy
**						   - Removed parameter @NEWTIdentifier since superseded by @NCBITaxonomyID
**			03/03/2016 mem - Now storing @AutoDefineTaxonomy in column Auto_Define_Taxonomy
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**			12/02/2016 mem - Assure that @orgName and @orgShortName do not have any spaces or commas
**			02/06/2017 mem - Auto-update @NEWTIDList to match @NCBITaxonomyID if @NEWTIDList is null or empty
**			03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**			06/13/2017 mem - Use SCOPE_IDENTITY()
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**			10/23/2017 mem - Check for the protein collection specified by @orgDBName being a valid name, but inactive
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@orgName varchar(128),
	@orgShortName varchar(128),
	@orgStorageLocation varchar(256),
	@orgDBName varchar(128),				-- Default protein collection name (prior to 2012 was default fasta file)
	@orgDescription varchar(256),
	@orgDomain varchar(64),
	@orgKingdom varchar(64),
	@orgPhylum varchar(64),
	@orgClass varchar(64),
	@orgOrder varchar(64),
	@orgFamily varchar(64),
	@orgGenus varchar(128),
	@orgSpecies varchar(128),
	@orgStrain varchar(128),
	@orgDNATransTabID varchar(6), 
	@orgMitoDNATransTabID varchar(6),
	@orgActive varchar(3),
	@NEWTIDList varchar(255),			-- If blank, this is auto-populated using @NCBITaxonomyID
	@NCBITaxonomyID int,				-- This is the preferred way to define the taxonomy ID for the organism.  NEWT ID is typically identical to taxonomy ID
	@AutoDefineTaxonomy varchar(12),	-- 'Yes', or 'No'
	@ID int output,
	@mode varchar(12) = 'add',			-- 'add' or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	set @message = ''

	declare @msg varchar(256)
	declare @DuplicateTaxologyMsg varchar(512)
	declare @MatchCount int

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateOrganisms', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @orgStorageLocation = IsNull(@orgStorageLocation, '')
	If @orgStorageLocation <> ''
	Begin
		If Not @orgStorageLocation LIKE '\\%'
			RAISERROR ('Org. Storage Path must start with \\', 11, 8)
		
		-- Make sure @orgStorageLocation does not end in \FASTA or \FASTA\
		-- That text gets auto-appended via computed column OG_organismDBPath
		If @orgStorageLocation Like '%\FASTA'
			Set @orgStorageLocation = Substring(@orgStorageLocation, 1, Len(@orgStorageLocation) - 6)

		If @orgStorageLocation Like '%\FASTA\'
			Set @orgStorageLocation = Substring(@orgStorageLocation, 1, Len(@orgStorageLocation) - 7)
			
		If Not @orgStorageLocation Like '%\'
			Set @orgStorageLocation = @orgStorageLocation + '\'
		
	End

	set @orgName = LTrim(RTrim(IsNull(@orgName, '')))
	if Len(@orgName) < 1
	begin
		RAISERROR ('Organism Name cannot be blank', 11, 0)
	end

	if @orgName Like '% %'
	begin
		RAISERROR ('Organism Name cannot contain spaces', 11, 0)
	end

	if @orgName Like '%,%'
	begin
		RAISERROR ('Organism Name cannot contain commas', 11, 0)
	end

	if Len(IsNull(@orgShortName, '')) > 0
	begin
		Set @orgShortName = LTrim(RTrim(IsNull(@orgShortName, '')))
		
		if @orgShortName Like '% %'
		begin
			RAISERROR ('Organism Short Name cannot contain spaces', 11, 0)
		end

		if @orgShortName Like '%,%'
		begin
			RAISERROR ('Organism Short Name cannot contain commas', 11, 0)
		end
	end
	
	Set @orgDBName = IsNull(@orgDBName, '')
	If @orgDBName Like '%.fasta'
	Begin
		RAISERROR ('Default Protein Collection cannot contain ".fasta"', 11, 0)
	End
		
	set @orgActive = IsNull(@orgActive, '')
	if Len(@orgActive) = 0 Or Try_Convert(Int, @orgActive) Is Null
	begin
		RAISERROR ('Organism active state must be 0 or 1', 11, 1)
	end

	Set @orgDNATransTabID = IsNull(@orgDNATransTabID, '0')
	if Len(@orgDNATransTabID) = 0 Or Try_Convert(Int, @orgDNATransTabID) Is Null
	begin
		RAISERROR ('DNA Translation Table ID must be an integer', 11, 2)
	end

	Set @orgMitoDNATransTabID = IsNull(@orgMitoDNATransTabID, '0')
	if Len(@orgMitoDNATransTabID) = 0 Or Try_Convert(Int, @orgMitoDNATransTabID) Is Null
	begin
		RAISERROR ('Mito DNA Translation Table ID must be an integer', 11, 3)
	end

	Set @orgGenus = IsNull(@orgGenus, '')
	Set @orgSpecies = IsNull(@orgSpecies, '')
	Set @orgStrain = IsNull(@orgStrain, '')
	
	Set @AutoDefineTaxonomy = IsNull(@AutoDefineTaxonomy, 'Yes')
	
	-- Organism ID
	Set @ID = IsNull(@ID, 0)
	
	Set @NEWTIDList = ISNULL(@NEWTIDList, '')
	If LEN(@NEWTIDList) > 0
	Begin
		CREATE TABLE #NEWTIDs (
			NEWT_ID_Text varchar(24),
			NEWT_ID int NULL
		)
		
		INSERT INTO #NEWTIDs (NEWT_ID_Text)
		SELECT Cast(Value as varchar(24))
		FROM dbo.udfParseDelimitedList(@NEWTIDList, ',', 'AddUpdateOrganisms')
		WHERE IsNull(Value, '') <> ''
		
		-- Look for non-numeric values
		IF Exists (Select * from #NEWTIDs Where Try_Convert(int, NEWT_ID_Text) IS NULL)
		BEGIN
			Set @msg = 'Non-numeric NEWT ID values found in the NEWT_ID List: "' + Convert(varchar(32), @NEWTIDList) + '"; see http://dms2.pnl.gov/ontology/report/NEWT'
			RAISERROR (@msg, 11, 3)
		END
		
		-- Make sure all of the NEWT IDs are Valid
		UPDATE #NEWTIDs
		SET NEWT_ID = Try_Convert(int, NEWT_ID_Text)
		
		Declare @InvalidNEWTIDs varchar(255) = null
		
		SELECT @InvalidNEWTIDs = COALESCE(@InvalidNEWTIDs + ', ', '') + #NEWTIDs.NEWT_ID_Text
		FROM #NEWTIDs
		     LEFT OUTER JOIN S_V_CV_NEWT
		       ON #NEWTIDs.NEWT_ID = S_V_CV_NEWT.identifier
		WHERE S_V_CV_NEWT.identifier IS NULL

		If LEN(ISNULL(@InvalidNEWTIDs, '')) > 0
		Begin
			Set @msg = 'Invalid NEWT ID(s) "' + @InvalidNEWTIDs + '"; see http://dms2.pnl.gov/ontology/report/NEWT'
			RAISERROR (@msg, 11, 3)
		End
		
	End 
	Else
	Begin
		-- Auto-define @NEWTIDList using @NCBITaxonomyID though only if the NEWT table has the ID 
		-- (there are numerous organisms that nave an NCBI Taxonomy ID but not a NEWT ID)
		--
		If Exists (SELECT * FROM S_V_CV_NEWT WHERE Identifier = Cast(@NCBITaxonomyID as varchar(24)))
		Begin
			Set @NEWTIDList = Cast(@NCBITaxonomyID as varchar(24))
		End
	End

	If IsNull(@NCBITaxonomyID, 0) = 0
		Set @NCBITaxonomyID = null
	Else
	Begin
		If Not Exists (Select * From [S_V_NCBI_Taxonomy_Cached] Where Tax_ID = @NCBITaxonomyID)
		Begin
			Set @msg = 'Invalid NCBI Taxonomy ID "' + Convert(varchar(24), @NCBITaxonomyID) + '"; see http://dms2.pnl.gov/ncbi_taxonomy/report'
			RAISERROR (@msg, 11, 3)
		End
	End
	
	Declare @AutoDefineTaxonomyFlag tinyint
	
	If @AutoDefineTaxonomy Like 'Y%'
		Set @AutoDefineTaxonomyFlag = 1
	Else
		Set @AutoDefineTaxonomyFlag = 0
	
	If @AutoDefineTaxonomyFlag = 1 And IsNull(@NCBITaxonomyID, 0) > 0
	Begin
	
		---------------------------------------------------
		-- Try to auto-update the taxonomy information
		-- Existing values are preserved if matches are not found
		---------------------------------------------------
		
		EXEC GetTaxonomyValueByTaxonomyID 
				@NCBITaxonomyID,
				@orgDomain=@orgDomain output,
				@orgKingdom=@orgKingdom output,
				@orgPhylum=@orgPhylum output,
				@orgClass=@orgClass output,
				@orgOrder=@orgOrder output,
				@orgFamily=@orgFamily output,
				@orgGenus=@orgGenus output,
				@orgSpecies=@orgSpecies output,
				@orgStrain=@orgStrain output,
				@previewResults = 0

	End
	
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

    declare @returnVal int
	set @returnVal = 0

	-- cannot create an entry that already exists
	--
	if @mode = 'add'
	begin
		execute @returnVal = GetOrganismID @orgName
		if @returnVal <> 0 
		begin
			set @msg = 'Cannot add: Organism "' + @orgName + '" already in database '
			RAISERROR (@msg, 11, 5)
		end
	end

	-- cannot update a non-existent entry
	--
	declare @ExistingOrgName varchar(128)
	declare @ExistingOrgID int
	
	if @mode = 'update'
	begin
		--
		SELECT @ExistingOrgID = Organism_ID, @ExistingOrgName = OG_name
		FROM  T_Organisms
		WHERE (Organism_ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @ExistingOrgID = 0 
		begin
			set @msg = 'Cannot update: Organism "' + @orgName + '" is not in database '
			RAISERROR (@msg, 11, 6)
		end
		--
		if @ExistingOrgName <> @orgName 
		begin
			set @msg = 'Cannot update: Organism name may not be changed from "' + @ExistingOrgName + '"'
			RAISERROR (@msg, 11, 7)
		end
	end
	
	---------------------------------------------------
	-- resolve DNA translation table IDs
	---------------------------------------------------
	declare @iOrgDNATransTabID int
	set @iOrgDNATransTabID = Null
	if @orgDNATransTabID <> ''
	begin
		set @iOrgDNATransTabID = convert(int, @orgDNATransTabID)
	end
	--
	declare @iOrgMitoDNATransTabID int
	set @iOrgMitoDNATransTabID = null
	if @orgMitoDNATransTabID <> ''
	begin
		set @iOrgMitoDNATransTabID = convert(int, @orgMitoDNATransTabID)
	end


	---------------------------------------------------
	-- If Genus, Species, and Strain are unknown, na, or none,
	--  then make sure all three are "na"
	---------------------------------------------------
	
	set @orgGenus =   dbo.ValidateNAParameter(@orgGenus, 1)
	set @orgSpecies = dbo.ValidateNAParameter(@orgSpecies, 1)
	set @orgStrain =  dbo.ValidateNAParameter(@orgStrain, 1)
		
	If @orgGenus   IN ('unknown', 'na', 'none') AND
	   @orgSpecies IN ('unknown', 'na', 'none') AND
	   @orgStrain  IN ('unknown', 'na', 'none')
	Begin
		Set @orgGenus = 'na'
		Set @orgSpecies = 'na'
		Set @orgStrain = 'na'
	End

	---------------------------------------------------
	-- Check whether an organism already exists 
	-- with the specified Genus, Species, and Strain
	---------------------------------------------------

	set @DuplicateTaxologyMsg = 'Another organism was found with Genus "' + @orgGenus + '", Species "' + @orgSpecies + '", and Strain "' + @orgStrain + '"; if unknown, use "na" for these values'

	if Not (@orgGenus = 'na' AND @orgSpecies = 'na' AND @orgStrain = 'na')
	Begin
		if @Mode = 'add'
		begin
			-- Make sure that an existing entry doesn't exist with the same values for Genus, Species, and Strain
			Set @MatchCount = 0
			SELECT @MatchCount = COUNT(*) 
			FROM T_Organisms
			WHERE IsNull(OG_Genus, '') = @orgGenus AND
				  IsNull(OG_Species, '') = @orgSpecies AND
				  IsNull(OG_Strain, '') = @orgStrain
			
			If @MatchCount <> 0
			begin
				set @msg = 'Cannot add: ' + @DuplicateTaxologyMsg
				RAISERROR (@msg, 11, 8)
			end
		end
		
		if @Mode = 'update'
		begin
			-- Make sure that an existing entry doesn't exist with the same values for Genus, Species, and Strain (ignoring Organism_ID = @ID)
			Set @MatchCount = 0
			SELECT @MatchCount = COUNT(*)
			FROM T_Organisms
			WHERE IsNull(OG_Genus, '') = @orgGenus AND
				  IsNull(OG_Species, '') = @orgSpecies AND
				  IsNull(OG_Strain, '') = @orgStrain AND
				  Organism_ID <> @ID
			
			If @MatchCount <> 0
			begin
				set @msg = 'Cannot update: ' + @DuplicateTaxologyMsg
				RAISERROR (@msg, 11, 9)
			end
		end
	End	

	---------------------------------------------------
	-- Validate the default protein collection
	---------------------------------------------------
	
	If @orgDBName <> ''
	Begin
		-- Protein collections in S_V_Protein_Collection_Picker are those with state 1, 2, or 3
		-- In contrast, S_V_Protein_Collections_by_Organism has all protein collections
		
		If Not Exists (SELECT * FROM S_V_Protein_Collection_Picker WHERE [Name] = @orgDBName)
		Begin
			If Exists (SELECT * FROM S_V_Protein_Collections_by_Organism WHERE Filename = @orgDBName AND Collection_State_ID = 4)
				Set @msg = 'Default protein collection is invalid because it is inactive: ' + @orgDBName
			Else			
				Set @msg = 'Protein collection not found: ' + @orgDBName

			RAISERROR (@msg, 11, 9)
		End
	End
	
	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		INSERT INTO T_Organisms (
			OG_name, 
			OG_organismDBName, 
			OG_created, 
			OG_description, 
			OG_Short_Name, 
			OG_Storage_Location, 
			OG_Domain, 
			OG_Kingdom, 
			OG_Phylum, 
			OG_Class, 
			OG_Order, 
			OG_Family, 
			OG_Genus, 
			OG_Species, 
			OG_Strain,
			OG_DNA_Translation_Table_ID, 
			OG_Mito_DNA_Translation_Table_ID,
			OG_Active,
			NEWT_ID_List,
			NCBI_Taxonomy_ID,
			Auto_Define_Taxonomy
		) VALUES (
			@orgName, 
			@orgDBName, 
			getdate(), 
			@orgDescription, 
			@orgShortName, 
			@orgStorageLocation, 
			@orgDomain, 
			@orgKingdom, 
			@orgPhylum, 
			@orgClass, 
			@orgOrder, 
			@orgFamily, 
			@orgGenus, 
			@orgSpecies, 
			@orgStrain,
			@iOrgDNATransTabID, 
			@iOrgMitoDNATransTabID,
			@orgActive,
			@NEWTIDList,
			@NCBITaxonomyID,
			@AutoDefineTaxonomyFlag
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 11, 10)
		end

		-- Return ID of newly created entry
		--
		set @ID = SCOPE_IDENTITY()

		-- If @callingUser is defined, then update Entered_By in T_Organisms_Change_History
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Organisms_Change_History', 'Organism_ID', @ID, @CallingUser

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		UPDATE T_Organisms 
		SET 
			OG_name = @orgName, 
			OG_organismDBName = @orgDBName, 
			OG_description = @orgDescription, 
			OG_Short_Name = @orgShortName, 
			OG_Storage_Location = @orgStorageLocation, 
			OG_Domain = @orgDomain, 
			OG_Kingdom = @orgKingdom, 
			OG_Phylum = @orgPhylum, 
			OG_Class = @orgClass, 
			OG_Order = @orgOrder, 
			OG_Family = @orgFamily, 
			OG_Genus = @orgGenus, 
			OG_Species = @orgSpecies, 
			OG_Strain = @orgStrain,
			OG_DNA_Translation_Table_ID = @iOrgDNATransTabID, 
			OG_Mito_DNA_Translation_Table_ID = @iOrgMitoDNATransTabID,			
			OG_Active = @orgActive,
			NEWT_ID_List = @NEWTIDList,
			NCBI_Taxonomy_ID = @NCBITaxonomyID,
			Auto_Define_Taxonomy = @AutoDefineTaxonomyFlag
		WHERE (Organism_ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 11, 11)
		end
		
		-- If @callingUser is defined, then update Entered_By in T_Organisms_Change_History
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Organisms_Change_History', 'Organism_ID', @ID, @CallingUser

	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH


	BEGIN TRY 

		-- Update the cached organism info in MT_Main on ProteinSeqs
		-- This table is used by the Protein_Sequences database and we want to assure that it is up-to-date
		-- Note that the table is auto-updated once per hour by a Sql Server Agent job running on ProteinSeqs
		-- This hourly update captures any changes manually made to table T_Organisms
		
		Exec dbo.S_MT_Main_RefreshCachedOrganisms

	END TRY
	BEGIN CATCH 
		Declare @LogMessage varchar(256)
		EXEC FormatErrorMessage @message=@LogMessage output, @myError=@myError output
		
		exec PostLogEntry 'Error', @LogMessage, 'AddUpdateOrganisms'
		
	END CATCH
	
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateOrganisms] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOrganisms] TO [DMS_Org_Database_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOrganisms] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateOrganisms] TO [Limited_Table_Write] AS [dbo]
GO
