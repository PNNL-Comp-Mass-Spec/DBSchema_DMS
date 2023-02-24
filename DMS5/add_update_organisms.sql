/****** Object:  StoredProcedure [dbo].[AddUpdateOrganisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateOrganisms]
/****************************************************
**
**  Desc:
**      Adds new or edits existing Organisms
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/07/2006
**          01/12/2007 jds - Added support for new field OG_Active
**          01/12/2007 mem - Added validation that genus, species, and strain are not duplicated in T_Organisms
**          10/16/2007 mem - Updated to allow genus, species, and strain to all be 'na' (Ticket #562)
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**          09/12/2008 mem - Updated to call ValidateNAParameter to validate genus, species, and strain (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          09/09/2009 mem - No longer populating field OG_organismDBLocalPath
**          11/20/2009 mem - Removed parameter @orgDBLocalPath
**          12/03/2009 mem - Now making sure that @orgDBPath starts with two slashes and ends with one slash
**          08/04/2010 grk - try-catch for error handling
**          08/01/2012 mem - Now calling RefreshCachedOrganisms in MT_Main on ProteinSeqs
**          09/25/2012 mem - Expanded @orgName and @orgDBName to varchar(128)
**          11/20/2012 mem - No longer allowing @orgDBName to contain '.fasta'
**          05/10/2013 mem - Added @newtIdentifier
**          05/13/2013 mem - Now validating @newtIdentifier against S_V_CV_NEWT
**          05/24/2013 mem - Added @newtIDList
**          10/15/2014 mem - Removed @orgDBPath and added validation logic to @orgStorageLocation
**          06/25/2015 mem - Now validating that the protein collection specified by @orgDBName exists
**          09/10/2015 mem - Switch to using synonym S_MT_Main_RefreshCachedOrganisms
**          02/23/2016 mem - Add Set XACT_ABORT on
**          02/26/2016 mem - Check for @orgName containing a space
**          03/01/2016 mem - Added @ncbiTaxonomyID
**          03/02/2016 mem - Added @autoDefineTaxonomy
**                         - Removed parameter @newtIdentifier since superseded by @ncbiTaxonomyID
**          03/03/2016 mem - Now storing @autoDefineTaxonomy in column Auto_Define_Taxonomy
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          12/02/2016 mem - Assure that @orgName and @orgShortName do not have any spaces or commas
**          02/06/2017 mem - Auto-update @newtIDList to match @ncbiTaxonomyID if @newtIDList is null or empty
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/23/2017 mem - Check for the protein collection specified by @orgDBName being a valid name, but inactive
**          04/09/2018 mem - Auto-define @orgStorageLocation if empty
**          06/26/2019 mem - Remove DNA translation table arguments since unused
**          04/15/2020 mem - Populate OG_Storage_URL using @orgStorageLocation
**          09/14/2020 mem - Expand the description field to 512 characters
**          12/11/2020 mem - Allow duplicate metagenome organisms
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          04/11/2022 mem - Check for whitespace in @orgName
**          07/27/2022 mem - Switch from FileName to Collection_Name when querying S_V_Protein_Collections_by_Organism
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @orgName varchar(128),
    @orgShortName varchar(128),
    @orgStorageLocation varchar(256),
    @orgDBName varchar(128),                -- Default protein collection name (prior to 2012 was default fasta file)
    @orgDescription varchar(512),
    @orgDomain varchar(64),
    @orgKingdom varchar(64),
    @orgPhylum varchar(64),
    @orgClass varchar(64),
    @orgOrder varchar(64),
    @orgFamily varchar(64),
    @orgGenus varchar(128),
    @orgSpecies varchar(128),
    @orgStrain varchar(128),
    @orgActive varchar(3),
    @newtIDList varchar(255),               -- If blank, this is auto-populated using @ncbiTaxonomyID
    @ncbiTaxonomyID int,                    -- This is the preferred way to define the taxonomy ID for the organism.  NEWT ID is typically identical to taxonomy ID
    @autoDefineTaxonomy varchar(12),        -- 'Yes' or 'No'
    @id int output,
    @mode varchar(12) = 'add',              -- 'add' or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @duplicateTaxologyMsg varchar(512)
    Declare @matchCount INT

    Declare @serverNameEndSlash int
    Declare @serverName varchar(64)
    Declare @pathForURL varchar(256)
    Declare @orgStorageURL varchar(256) = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateOrganisms', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin Try

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @orgStorageLocation = IsNull(@orgStorageLocation, '')
    If @orgStorageLocation <> ''
    Begin
        If Not @orgStorageLocation LIKE '\\%'
            RAISERROR ('Org. Storage Path must start with \\', 11, 8)

        -- Make sure @orgStorageLocation does not End in \FASTA or \FASTA\
        -- That text gets auto-appended via computed column OG_organismDBPath
        If @orgStorageLocation Like '%\FASTA'
            Set @orgStorageLocation = Substring(@orgStorageLocation, 1, Len(@orgStorageLocation) - 6)

        If @orgStorageLocation Like '%\FASTA\'
            Set @orgStorageLocation = Substring(@orgStorageLocation, 1, Len(@orgStorageLocation) - 7)

        If Not @orgStorageLocation Like '%\'
            Set @orgStorageLocation = @orgStorageLocation + '\'

        -- Auto-define @orgStorageURL

        -- Find the next slash after the 3rd character
        Set @serverNameEndSlash = CharIndex('\', @orgStorageLocation, 3)

        If @serverNameEndSlash > 3
        Begin
            Set @serverName = Substring(@orgStorageLocation, 3, @serverNameEndSlash - 3)
            Set @pathForURL = Substring(@orgStorageLocation, @serverNameEndSlash + 1, LEN(@orgStorageLocation))
            Set @orgStorageURL= 'http://' + @serverName + '/' + REPLACE(@pathForURL, '\', '/')
        End

    End

    Set @orgName = LTrim(RTrim(IsNull(@orgName, '')))
    If Len(@orgName) < 1
    Begin
        RAISERROR ('Organism Name cannot be blank', 11, 0)
    End

    If dbo.udfWhitespaceChars(@orgName, 0) > 0
    Begin
        If CharIndex(Char(9), @orgName) > 0
            RAISERROR ('Organism name cannot contain tabs', 11, 116)
        Else
            RAISERROR ('Organism  name cannot contain spaces', 11, 116)
    End

    If @orgName Like '%,%'
    Begin
        RAISERROR ('Organism Name cannot contain commas', 11, 0)
    End

    If Len(@orgStorageLocation) = 0
    Begin
        -- Auto define @orgStorageLocation
        Declare @orgDbPathBase varchar(128) = '\\gigasax\DMS_Organism_Files\'

        SELECT @orgDbPathBase = [Server]
        FROM T_MiscPaths
        WHERE [Function] = 'DMSOrganismFiles'

        Set @orgStorageLocation = dbo.udfCombinePaths(@orgDbPathBase, @orgName) + '\'
    End

    If Len(IsNull(@orgShortName, '')) > 0
    Begin
        Set @orgShortName = LTrim(RTrim(IsNull(@orgShortName, '')))

        If @orgShortName Like '% %'
        Begin
            RAISERROR ('Organism Short Name cannot contain spaces', 11, 0)
        End

        If @orgShortName Like '%,%'
        Begin
            RAISERROR ('Organism Short Name cannot contain commas', 11, 0)
        End
    End

    Set @orgDBName = IsNull(@orgDBName, '')
    If @orgDBName Like '%.fasta'
    Begin
        RAISERROR ('Default Protein Collection cannot contain ".fasta"', 11, 0)
    End

    Set @orgActive = IsNull(@orgActive, '')
    If Len(@orgActive) = 0 Or Try_Parse(@orgActive as int) Is Null
    Begin
        RAISERROR ('Organism active state must be 0 or 1', 11, 1)
    End

    Set @orgGenus = IsNull(@orgGenus, '')
    Set @orgSpecies = IsNull(@orgSpecies, '')
    Set @orgStrain = IsNull(@orgStrain, '')

    Set @autoDefineTaxonomy = IsNull(@autoDefineTaxonomy, 'Yes')

    -- Organism ID
    Set @id = IsNull(@id, 0)

    Set @newtIDList = ISNULL(@newtIDList, '')
    If LEN(@newtIDList) > 0
    Begin
        CREATE TABLE #NEWTIDs (
            NEWT_ID_Text varchar(24),
            NEWT_ID int NULL
        )

        INSERT INTO #NEWTIDs (NEWT_ID_Text)
        SELECT Cast(Value as varchar(24))
        FROM dbo.udfParseDelimitedList(@newtIDList, ',', 'AddUpdateOrganisms')
        WHERE IsNull(Value, '') <> ''

        -- Look for non-numeric values
        IF Exists (SELECT * FROM #NEWTIDs WHERE Try_Parse(NEWT_ID_Text as int) IS NULL)
        Begin
            Set @msg = 'Non-numeric NEWT ID values found in the NEWT_ID List: "' + Convert(varchar(32), @newtIDList) + '"; see http://dms2.pnl.gov/ontology/report/NEWT'
            RAISERROR (@msg, 11, 3)
        End

        -- Make sure all of the NEWT IDs are Valid
        UPDATE #NEWTIDs
        Set NEWT_ID = Try_Parse(NEWT_ID_Text as int)

        Declare @invalidNEWTIDs varchar(255) = null

        SELECT @invalidNEWTIDs = COALESCE(@invalidNEWTIDs + ', ', '') + #NEWTIDs.NEWT_ID_Text
        FROM #NEWTIDs
             LEFT OUTER JOIN S_V_CV_NEWT
               ON #NEWTIDs.NEWT_ID = S_V_CV_NEWT.identifier
        WHERE S_V_CV_NEWT.identifier IS NULL

        If LEN(ISNULL(@invalidNEWTIDs, '')) > 0
        Begin
            Set @msg = 'Invalid NEWT ID(s) "' + @invalidNEWTIDs + '"; see http://dms2.pnl.gov/ontology/report/NEWT'
            RAISERROR (@msg, 11, 3)
        End

    End
    Else
    Begin
        -- Auto-define @newtIDList using @ncbiTaxonomyID though only if the NEWT table has the ID
        -- (there are numerous organisms that nave an NCBI Taxonomy ID but not a NEWT ID)
        --
        If Exists (SELECT * FROM S_V_CV_NEWT WHERE Identifier = Cast(@ncbiTaxonomyID as varchar(24)))
        Begin
            Set @newtIDList = Cast(@ncbiTaxonomyID as varchar(24))
        End
    End

    If IsNull(@ncbiTaxonomyID, 0) = 0
        Set @ncbiTaxonomyID = null
    Else
    Begin
        If Not Exists (Select * From [S_V_NCBI_Taxonomy_Cached] Where Tax_ID = @ncbiTaxonomyID)
        Begin
            Set @msg = 'Invalid NCBI Taxonomy ID "' + Convert(varchar(24), @ncbiTaxonomyID) + '"; see http://dms2.pnl.gov/ncbi_taxonomy/report'
            RAISERROR (@msg, 11, 3)
        End
    End

    Declare @autoDefineTaxonomyFlag tinyint

    If @autoDefineTaxonomy Like 'Y%'
        Set @autoDefineTaxonomyFlag = 1
    Else
        Set @autoDefineTaxonomyFlag = 0

    If @autoDefineTaxonomyFlag = 1 And IsNull(@ncbiTaxonomyID, 0) > 0
    Begin

        ---------------------------------------------------
        -- Try to auto-update the taxonomy information
        -- Existing values are preserved if matches are not found
        ---------------------------------------------------

        EXEC GetTaxonomyValueByTaxonomyID
                @ncbiTaxonomyID,
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

    Declare @existingOrganismID Int = 0

    -- cannot create an entry that already exists
    --
    If @mode = 'add'
    Begin
        execute @existingOrganismID = GetOrganismID @orgName
        If @existingOrganismID <> 0
        Begin
            Set @msg = 'Cannot add: Organism "' + @orgName + '" already in database '
            RAISERROR (@msg, 11, 5)
        End
    End

    -- cannot update a non-existent entry
    --
    Declare @existingOrgName varchar(128)

    If @mode = 'update'
    Begin
        --
        SELECT @existingOrganismID = Organism_ID, @existingOrgName = OG_name
        FROM  T_Organisms
        WHERE (Organism_ID = @id)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @existingOrganismID = 0
        Begin
            Set @msg = 'Cannot update: Organism "' + @orgName + '" is not in database '
            RAISERROR (@msg, 11, 6)
        End
        --
        If @existingOrgName <> @orgName
        Begin
            Set @msg = 'Cannot update: Organism name may not be changed from "' + @existingOrgName + '"'
            RAISERROR (@msg, 11, 7)
        End
    End

    ---------------------------------------------------
    -- If Genus, Species, and Strain are unknown, na, or none,
    --  then make sure all three are "na"
    ---------------------------------------------------

    Set @orgGenus =   dbo.ValidateNAParameter(@orgGenus, 1)
    Set @orgSpecies = dbo.ValidateNAParameter(@orgSpecies, 1)
    Set @orgStrain =  dbo.ValidateNAParameter(@orgStrain, 1)

    If @orgGenus   IN ('unknown', 'na', 'none') AND
       @orgSpecies IN ('unknown', 'na', 'none') AND
       @orgStrain  IN ('unknown', 'na', 'none')
    Begin
        Set @orgGenus = 'na'
        Set @orgSpecies = 'na'
        Set @orgStrain = 'na'
    End

    ---------------------------------------------------
    -- Check whether an organism already exists with the specified Genus, Species, and Strain
    -- Allow exceptions for metagenome organisms
    ---------------------------------------------------

    Set @duplicateTaxologyMsg = 'Another organism was found with Genus "' + @orgGenus + '", Species "' + @orgSpecies + '", and Strain "' + @orgStrain + '"; if unknown, use "na" for these values'

    If Not (@orgGenus = 'na' AND @orgSpecies = 'na' AND @orgStrain = 'na')
    Begin
        If @mode = 'add'
        Begin
            -- Make sure that an existing entry doesn't exist with the same values for Genus, Species, and Strain
            Set @matchCount = 0
            SELECT @matchCount = COUNT(*)
            FROM T_Organisms
            WHERE IsNull(OG_Genus, '') = @orgGenus AND
                  IsNull(OG_Species, '') = @orgSpecies AND
                  IsNull(OG_Strain, '') = @orgStrain

            If @matchCount <> 0 AND Not @orgSpecies LIKE '%metagenome'
            Begin
                Set @msg = 'Cannot add: ' + @duplicateTaxologyMsg
                RAISERROR (@msg, 11, 8)
            End
        End

        If @mode = 'update'
        Begin
            -- Make sure that an existing entry doesn't exist with the same values for Genus, Species, and Strain (ignoring Organism_ID = @id)
            Set @matchCount = 0
            SELECT @matchCount = COUNT(*)
            FROM T_Organisms
            WHERE IsNull(OG_Genus, '') = @orgGenus AND
                  IsNull(OG_Species, '') = @orgSpecies AND
                  IsNull(OG_Strain, '') = @orgStrain AND
                  Organism_ID <> @id

            If @matchCount <> 0 AND Not @orgSpecies LIKE '%metagenome'
            Begin
                Set @msg = 'Cannot update: ' + @duplicateTaxologyMsg
                RAISERROR (@msg, 11, 9)
            End
        End
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
            If Exists (SELECT * FROM S_V_Protein_Collections_by_Organism WHERE Collection_Name = @orgDBName AND Collection_State_ID = 4)
                Set @msg = 'Default protein collection is invalid because it is inactive: ' + @orgDBName
            Else
                Set @msg = 'Protein collection not found: ' + @orgDBName

            RAISERROR (@msg, 11, 9)
        End
    End

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @mode = 'add'
    Begin
        INSERT INTO T_Organisms (
            OG_name,
            OG_organismDBName,
            OG_created,
            OG_description,
            OG_Short_Name,
            OG_Storage_Location,
            OG_Storage_URL,
            OG_Domain,
            OG_Kingdom,
            OG_Phylum,
            OG_Class,
            OG_Order,
            OG_Family,
            OG_Genus,
            OG_Species,
            OG_Strain,
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
            @orgStorageURL,
            @orgDomain,
            @orgKingdom,
            @orgPhylum,
            @orgClass,
            @orgOrder,
            @orgFamily,
            @orgGenus,
            @orgSpecies,
            @orgStrain,
            @orgActive,
            @newtIDList,
            @ncbiTaxonomyID,
            @autoDefineTaxonomyFlag
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed'
            RAISERROR (@message, 11, 10)
        End

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

        -- If @callingUser is defined, then update Entered_By in T_Organisms_Change_History
        If Len(@callingUser) > 0
            Exec AlterEnteredByUser 'T_Organisms_Change_History', 'Organism_ID', @id, @callingUser

    End -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        UPDATE T_Organisms
        Set
            OG_name = @orgName,
            OG_organismDBName = @orgDBName,
            OG_description = @orgDescription,
            OG_Short_Name = @orgShortName,
            OG_Storage_Location = @orgStorageLocation,
            OG_Storage_URL = @orgStorageURL,
            OG_Domain = @orgDomain,
            OG_Kingdom = @orgKingdom,
            OG_Phylum = @orgPhylum,
            OG_Class = @orgClass,
            OG_Order = @orgOrder,
            OG_Family = @orgFamily,
            OG_Genus = @orgGenus,
            OG_Species = @orgSpecies,
            OG_Strain = @orgStrain,
            OG_Active = @orgActive,
            NEWT_ID_List = @newtIDList,
            NCBI_Taxonomy_ID = @ncbiTaxonomyID,
            Auto_Define_Taxonomy = @autoDefineTaxonomyFlag
        WHERE (Organism_ID = @id)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed: "' + @id + '"'
            RAISERROR (@message, 11, 11)
        End

        -- If @callingUser is defined, then update Entered_By in T_Organisms_Change_History
        If Len(@callingUser) > 0
            Exec AlterEnteredByUser 'T_Organisms_Change_History', 'Organism_ID', @id, @callingUser

    End -- update mode

    End Try
    Begin Catch
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    End Catch

    Begin Try

        -- Update the cached organism info in MT_Main on ProteinSeqs
        -- This table is used by the Protein_Sequences database and we want to assure that it is up-to-date
        -- Note that the table is auto-updated once per hour by a Sql Server Agent job running on ProteinSeqs
        -- This hourly update captures any changes manually made to table T_Organisms

        Exec dbo.S_MT_Main_RefreshCachedOrganisms

    End Try
    Begin Catch
        Declare @logMessage varchar(256)
        EXEC FormatErrorMessage @message=@logMessage output, @myError=@myError output

        exec PostLogEntry 'Error', @logMessage, 'AddUpdateOrganisms'

    End Catch

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
