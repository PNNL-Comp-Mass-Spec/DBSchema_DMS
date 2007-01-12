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
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@orgName varchar(50),
	@orgShortName varchar(128),
	@orgDBPath varchar(255),
	@orgDBLocalPath varchar(255),
	@orgStorageLocation varchar(256),
	@orgDBName varchar(64),
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
	@ID int output,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	declare @msg varchar(256)
	declare @DuplicateTaxologyMsg varchar(512)
	declare @MatchCount int
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @orgName = IsNull(@orgName, '')
	if Len(@orgName) < 1
	begin
		set @myError = 51000
		RAISERROR ('Organism Name cannot be blank', 10, 1)
	end
	
	set @orgActive = IsNull(@orgActive, '')
	if Len(@orgActive) = 0 Or Not IsNumeric(@orgActive) = 1
	begin
		set @myError = 51001
		RAISERROR ('Organism active state must be 0 or 1', 10, 1)
	end

	Set @orgDNATransTabID = IsNull(@orgDNATransTabID, '0')
	if Len(@orgDNATransTabID) = 0 Or Not IsNumeric(@orgDNATransTabID) = 1
	begin
		set @myError = 51002
		RAISERROR ('DNA Translation Table ID must be an integer', 10, 1)
	end

	Set @orgMitoDNATransTabID = IsNull(@orgMitoDNATransTabID, '0')
	if Len(@orgMitoDNATransTabID) = 0 Or Not IsNumeric(@orgMitoDNATransTabID) = 1
	begin
		set @myError = 51003
		RAISERROR ('Mito DNA Translation Table ID must be an integer', 10, 1)
	end

	Set @orgGenus = IsNull(@orgGenus, '')
	Set @orgSpecies = IsNull(@orgSpecies, '')
	Set @orgStrain = IsNull(@orgStrain, '')
	
	Set @ID = IsNull(@ID, 0)
	--
	if @myError <> 0
		return @myError
	
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
			RAISERROR (@msg, 10, 1)
			return 51004
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
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		--
		if @ExistingOrgName <> @orgName 
		begin
			set @msg = 'Cannot update: Organism name may not be changed from "' + @ExistingOrgName + '"'
			RAISERROR (@msg, 10, 1)
			return 51005
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
	-- Check whether an organism already exists 
	-- with the specified Genus, Species, and Strain
	---------------------------------------------------

	set @DuplicateTaxologyMsg = 'Another organism was found with Genus "' + @orgGenus + '", Species "' + @orgSpecies + '", and Strain "' + @orgStrain + '"'
	
	if @Mode = 'add'
	begin
		Set @MatchCount = 0
		SELECT @MatchCount = COUNT(*) 
		FROM T_Organisms
		WHERE IsNull(OG_Genus, '') = @orgGenus AND
			  IsNull(OG_Species, '') = @orgSpecies AND
			  IsNull(OG_Strain, '') = @orgStrain
		
		If @MatchCount <> 0
		begin
			set @msg = 'Cannot add: ' + @DuplicateTaxologyMsg
			RAISERROR (@msg, 10, 1)
			return 51006
		end
	end
	
	if @Mode = 'update'
	begin
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
			RAISERROR (@msg, 10, 1)
			return 51006
		end
	end
	

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		INSERT INTO T_Organisms (
			OG_name, 
			OG_organismDBPath, 
			OG_organismDBLocalPath, 
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
			OG_Active
		) VALUES (
			@orgName, 
			@orgDBPath, 
			@orgDBLocalPath, 
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
			@orgActive
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		end

		-- return IDof newly created entry
		--
		set @ID = IDENT_CURRENT('T_Organisms')

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
			OG_organismDBPath = @orgDBPath, 
			OG_organismDBLocalPath = @orgDBLocalPath, 
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
			OG_Active = @orgActive
		WHERE (Organism_ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		end
	end -- update mode

	return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdateOrganisms] TO [DMS_Org_Database_Admin]
GO
