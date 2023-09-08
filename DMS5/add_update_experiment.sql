/****** Object:  StoredProcedure [dbo].[add_update_experiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_experiment]
/****************************************************
**
**  Desc:
**      Adds a new experiment to DB
**
**      Note that the Experiment Detail Report web page
**      uses do_material_item_operation to retire an experiment
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/8/2002 - initial release
**          08/25/2004 jds - updated proc to add T_Enzyme table value
**          06/10/2005 grk - added handling for sample prep request
**          10/28/2005 grk - added handling for internal standard
**          11/11/2005 grk - added handling for postdigest internal standard
**          11/21/2005 grk - fixed update error for postdigest internal standard
**          01/12/2007 grk - added verification mode
**          01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**          04/30/2007 grk - added better name validation (Ticket #450)
**          02/13/2008 mem - Now checking for @badCh = '[space]' (Ticket #602)
**          03/13/2008 grk - added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter @callingUser
**          03/25/2008 mem - Now calling alter_event_log_entry_user if @callingUser is not blank (Ticket #644)
**          07/16/2009 grk - added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          12/01/2009 grk - modified to skip checking of existing well occupancy if updating existing experiment
**          04/22/2010 grk - try-catch for error handling
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if @researcherUsername contains a person's real name rather than their username
**          05/18/2010 mem - Now validating that @internalStandard and @postdigestIntStd are active internal standards when creating a new experiment (@mode is 'add' or 'check_add')
**          11/15/2011 grk - added alkylation field
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**          03/26/2012 mem - Now validating @container
**                         - Updated to validate additional terms when @mode = 'check_add'
**          11/15/2012 mem - Now updating @biomaterialList to replace commas with semicolons
**          04/03/2013 mem - Now requiring that the experiment name be at least 6 characters in length
**          05/09/2014 mem - Expanded @campaignName from varchar(50) to varchar(64)
**          09/09/2014 mem - Added @barcode
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          07/31/2015 mem - Now updating Last_Used when key fields are updated
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Update error messages to use user-friendly entity names (e.g. campaign name instead of campaignNum)
**          09/14/2016 mem - Validate inputs
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/23/2016 mem - Include the experiment name when calling post_log_entry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          01/24/2017 mem - Fix validation of @labelling to raise an error when the label name is unknown
**          01/27/2017 mem - Change @internalStandard and @postdigestIntStd to 'none' if empty
**          03/17/2017 mem - Only call make_table_from_list_delim if @biomaterialList contains a semicolon
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/18/2017 mem - Add parameter @tissue (tissue name, e.g. hypodermis)
**          09/01/2017 mem - Allow @tissue to be a BTO ID (e.g. BTO:0000131)
**          11/29/2017 mem - Call parse_delimited_list instead of make_table_from_list_delim
**                           Rename #CC to #Tmp_ExpToCCMap
**                           No longer pass @biomaterialList to add_experiment_biomaterial since it uses #Tmp_ExpToCCMap
**                           Remove references to the Cell_Culture_List field in T_Experiments (procedure add_experiment_biomaterial calls update_cached_experiment_component_names)
**                           Add argument @referenceCompoundList
**          01/04/2018 mem - Entries in @referenceCompoundList are now assumed to be in the form Compound_ID:Compound_Name, though we also support only Compound_ID or only Compound_Name
**          07/30/2018 mem - Expand @reason and @comment to varchar(500)
**          11/27/2018 mem - Check for @referenceCompoundList having '100:(none)'
**                           Remove items from #Tmp_ExpToRefCompoundMap that map to the reference compound named (none)
**          11/30/2018 mem - Add output parameter @experimentID
**          03/27/2019 mem - Update @experimentId using @existingExperimentID
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          02/25/2021 mem - Use replace_character_codes to replace character codes with punctuation marks
**                         - Use remove_cr_lf to replace linefeeds with semicolons
**          07/06/2021 mem - Expand @organismName and @labNotebookRef to varchar(128)
**          09/30/2021 mem - Allow renaming an experiment if it does not have an associated requested run or dataset
**                         - Move argument @experimentID, making it the first argument
**                         - Rename the Experiment, Campaign, and Wellplate name arguments
**          11/26/2022 mem - Rename parameter to @biomaterialList
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**
*****************************************************/
(
    @experimentId int output,            -- Input/output; When copying an experiment, this will have the new experiment's ID; this is required if renaming an existing experiment
    @experimentName varchar(50),         -- Experiment name
    @campaignName varchar(64),
    @researcherUsername varchar(50),
    @organismName varchar(128),
    @reason varchar(500) = 'na',
    @comment varchar(500) = '',
    @sampleConcentration varchar(32) = 'na',
    @enzymeName varchar(50) = 'Trypsin',
    @labNotebookRef varchar(128) = 'na',
    @labelling varchar(64) = 'none',
    @biomaterialList varchar(2048) = '',
    @referenceCompoundList varchar(2048) = '',        -- Semicolon separated list of reference compound IDs; supports integers, or names of the form 3311:ANFTSQETQGAGK
    @samplePrepRequest int = 0,
    @internalStandard varchar(50),
    @postdigestIntStd varchar(50),
    @wellplateName varchar(64),
    @wellNumber varchar(8),
    @alkylation varchar(1),
    @mode varchar(12) = 'add',                  -- 'add, 'update', 'check_add', 'check_update'
    @message varchar(512) output,
    @container varchar(128) = 'na',
    @barcode varchar(64) = '',
    @tissue varchar(128) = '',
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @result int

    Declare @msg varchar(256)
    Declare @logErrors tinyint = 0

    Declare @invalidCCList varchar(512) = null
    Declare @invalidRefCompoundList varchar(512)

    Declare @existingExperimentID int = 0
    Declare @existingExperimentName Varchar(128) = ''
    Declare @existingRequestedRun varchar(128) = ''
    Declare @existingDataset varchar(128) = ''
    Declare @curContainerID int = 0

    BEGIN TRY

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_experiment', @raiseError = 1
    If @authorized = 0
    Begin
        RAISERROR ('Access denied', 11, 3)
    End

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @experimentID = IsNull(@experimentID, 0)
    Set @experimentName = LTrim(RTrim(IsNull(@experimentName, '')))
    Set @campaignName = LTrim(RTrim(IsNull(@campaignName, '')))
    Set @researcherUsername = LTrim(RTrim(IsNull(@researcherUsername, '')))
    Set @organismName = LTrim(RTrim(IsNull(@organismName, '')))
    Set @reason = LTrim(RTrim(IsNull(@reason, '')))
    Set @comment = LTrim(RTrim(IsNull(@comment, '')))
    Set @enzymeName = LTrim(RTrim(IsNull(@enzymeName, '')))
    Set @labelling = LTrim(RTrim(IsNull(@labelling, '')))
    Set @biomaterialList = LTrim(RTrim(IsNull(@biomaterialList, '')))
    Set @referenceCompoundList = LTrim(RTrim(IsNull(@referenceCompoundList, '')))
    Set @internalStandard = LTrim(RTrim(IsNull(@internalStandard, '')))
    Set @postdigestIntStd = LTrim(RTrim(IsNull(@postdigestIntStd, '')))
    Set @alkylation = LTrim(RTrim(IsNull(@alkylation, '')))
    Set @mode = LTrim(RTrim(IsNull(@mode, '')))

    If LEN(@experimentName) < 1
        RAISERROR ('Experiment name must be specified', 11, 30)
    --
    If LEN(@campaignName) < 1
        RAISERROR ('Campaign name must be specified', 11, 31)
    --
    If LEN(@researcherUsername) < 1
        RAISERROR ('Researcher username must be specified', 11, 32)
    --
    If LEN(@organismName) < 1
        RAISERROR ('Organism name must be specified', 11, 33)
    --
    If LEN(@reason) < 1
        RAISERROR ('Reason must be specified', 11, 34)
    --
    If LEN(@labelling) < 1
        RAISERROR ('Labelling must be specified', 11, 35)

    If Not @alkylation IN ('Y', 'N')
        RAISERROR ('Alkylation must be Y or N', 11, 35)

    -- Assure that @comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
    Set @comment = dbo.replace_character_codes(@comment)

    -- Replace instances of CRLF (or LF) with semicolons
    Set @comment = dbo.remove_cr_lf(@comment)

    -- Auto change empty internal standards to "none" since now rarely used
    If @internalStandard = ''
        Set @internalStandard = 'none'

    If @postdigestIntStd= ''
        Set @postdigestIntStd = 'none'

    ---------------------------------------------------
    -- Validate experiment name
    ---------------------------------------------------

    Declare @badCh varchar(128) = dbo.validate_chars(@experimentName, '')
    If @badCh <> ''
    Begin
        If @badCh = '[space]'
            RAISERROR ('Experiment name may not contain spaces', 11, 36)
        Else
            RAISERROR ('Experiment name may not contain the character(s) "%s"', 11, 37, @badCh)
    End

    If Len(@experimentName) < 6
    Begin
        Set @msg = 'Experiment name must be at least 6 characters in length; currently ' + Convert(varchar(12), Len(@experimentName)) + ' characters'
        RAISERROR (@msg, 11, 37)
    End

    ---------------------------------------------------
    -- Resolve @tissue to BTO identifier
    ---------------------------------------------------

    Declare @tissueIdentifier varchar(24)
    Declare @tissueName varchar(128)
    Declare @errorCode int

    EXEC @errorCode = get_tissue_id
            @tissueNameOrID=@tissue,
            @tissueIdentifier=@tissueIdentifier output,
            @tissueName=@tissueName output

    If @errorCode = 100
        RAISERROR ('Could not find entry in database for tissue "%s"', 11, 41, @tissue)
    Else If @errorCode > 0
        RAISERROR ('Could not resolve tissue name or id: "%s"', 11, 41, @tissue)

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If @mode In ('update', 'check_update') And @experimentID > 0
    Begin
        Select
            @existingExperimentID = Exp_ID,
            @existingExperimentName = Experiment_Num,
            @curContainerID = EX_Container_ID
        FROM T_Experiments
        WHERE Exp_ID = @experimentID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error looking for Experiment ID %d', 11, 38, @experimentID)

        If IsNull(@existingExperimentID, 0) = 0
        Begin
            RAISERROR ('Cannot update: Experiment ID %d is not in database', 11, 40, @experimentID)
        End

        If @existingExperimentName <> @experimentName
        Begin
            -- Allow renaming if the experiment is not associated with a dataset or requested run, and if the new name is unique

            If Exists (Select * From T_Experiments Where Experiment_Num = @experimentName)
            Begin
                SELECT
                    @existingExperimentID = Exp_ID
                FROM T_Experiments
                WHERE Experiment_Num = @experimentName
                --
                RAISERROR ('Cannot rename: Experiment "%s" already exists, with ID %d', 11, 40, @experimentName, @existingExperimentID)
            End

            If Exists (Select * From T_Dataset Where Exp_ID = @experimentID)
            Begin
                SELECT @existingDataset = Dataset_Num
                FROM T_Dataset
                WHERE Exp_ID = @experimentID
                --
                RAISERROR ('Cannot rename: Experiment ID %d is associated with dataset "%s"', 11, 40, @experimentID, @existingDataset)
            End

            If Exists (Select * From T_Requested_Run Where Exp_ID = @experimentID)
            Begin
                SELECT @existingRequestedRun = RDS_Name
                FROM T_Requested_Run
                WHERE Exp_ID = @experimentID
                --
                RAISERROR ('Cannot rename: Experiment ID %d is associated with requested run "%s"', 11, 40, @experimentID, @existingRequestedRun)
            End
        End
    End
    Else
    Begin
        -- Either @mode is 'add' or 'check_add' or @experimentID is null or 0
        -- Look for the experiment by name

        SELECT
            @existingExperimentID = Exp_ID,
            @curContainerID = EX_Container_ID
        FROM T_Experiments
        WHERE Experiment_Num = @experimentName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to resolve experiment name to ID', 11, 38)

        If @mode In ('update', 'check_update') And @existingExperimentID = 0
        Begin
            RAISERROR ('Cannot update: Experiment "%s" is not in database', 11, 40, @experimentName)
        End

        -- Assure that @experimentId is up-to-date
        Set @experimentId = @existingExperimentID
    End

    -- Cannot create an entry that already exists
    --
    If @existingExperimentID <> 0 and (@mode In ('add', 'check_add'))
    Begin
        RAISERROR ('Cannot add: Experiment "%s" already in database; cannot add', 11, 39, @experimentName)
    End

    ---------------------------------------------------
    -- Resolve campaign ID
    ---------------------------------------------------

    Declare @campaignID int
    execute @campaignID = get_campaign_id @campaignName
    If @campaignID = 0
        RAISERROR ('Could not find entry in database for campaign "%s"', 11, 41, @campaignName)

    ---------------------------------------------------
    -- Resolve researcher username
    ---------------------------------------------------

    Declare @userID int
    execute @userID = get_user_id @researcherUsername

    If @userID > 0
    Begin
        -- SP get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @researcherUsername contains simply the username
        --
        SELECT @researcherUsername = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for username @researcherUsername
        -- Try to auto-resolve the name

        Declare @matchCount int
        Declare @newUsername varchar(64)

        exec auto_resolve_name_to_username @researcherUsername, @matchCount output, @newUsername output, @userID output

        If @matchCount = 1
        Begin
            -- Single match found; update @researcherUsername
            Set @researcherUsername = @newUsername
        End
        Else
        Begin
            RAISERROR ('Could not find entry in database for researcher username "%s"', 11, 42, @researcherUsername)
            return 51037
        End

    End

    ---------------------------------------------------
    -- Resolve organism ID
    ---------------------------------------------------

    Declare @organismID int = 0
    exec @organismID = get_organism_id @organismName
    If @organismID = 0
        RAISERROR ('Could not find entry in database for organism name "%s"', 11, 43, @organismName)

    ---------------------------------------------------
    -- Set up and validate wellplate values
    ---------------------------------------------------
    Declare @totalCount INT
    Declare @wellIndex int
    --
    SELECT @totalCount = CASE WHEN @mode In ('add', 'check_add') THEN 1 ELSE 0 END
    --
    exec @myError = validate_wellplate_loading
                        @wellplateName  output,
                        @wellNumber  output,
                        @totalCount,
                        @wellIndex output,
                        @msg  output
    If @myError <> 0
        RAISERROR ('validate_wellplate_loading: %s', 11, 44, @msg)

    -- make sure we do not put two experiments in the same place
    --
    If exists (SELECT * FROM T_Experiments WHERE EX_wellplate_num = @wellplateName AND EX_well_num = @wellNumber) AND @mode In ('add', 'check_add')
        RAISERROR ('There is another experiment assigned to the same wellplate and well', 11, 45)
    --
    If exists (SELECT * FROM T_Experiments WHERE EX_wellplate_num = @wellplateName AND EX_well_num = @wellNumber AND Experiment_Num <> @experimentName) AND @mode In ('update', 'check_update')
        RAISERROR ('There is another experiment assigned to the same wellplate and well', 11, 46)

    ---------------------------------------------------
    -- Resolve enzyme ID
    ---------------------------------------------------

    Declare @enzymeID int = 0
    exec @enzymeID = get_enzyme_id @enzymeName
    If @enzymeID = 0
    Begin
        If @enzymeName = 'na'
            RAISERROR ('The enzyme cannot be "%s"; use No_Enzyme if enzymatic digestion was not used', 11, 47, @enzymeName)
        Else
            RAISERROR ('Could not find entry in database for enzyme "%s"', 11, 47, @enzymeName)
    End

    ---------------------------------------------------
    -- Resolve labelling ID
    ---------------------------------------------------

    Declare @labelID int = 0
    --
    SELECT @labelID = ID
    FROM T_Sample_Labelling
    WHERE (Label = @labelling)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myRowCount = 0
        RAISERROR ('Could not find entry in database for labelling "%s"; use "none" if unlabeled', 11, 48, @labelling)

    ---------------------------------------------------
    -- Resolve predigestion internal standard ID
    -- If creating a new experiment, make sure the internal standard is active
    ---------------------------------------------------

    Declare @internalStandardID int = 0
    Declare @internalStandardState char = 'I'
    --
    SELECT @internalStandardID = Internal_Std_Mix_ID,
           @internalStandardState = Active
    FROM T_Internal_Standards
    WHERE (Name = @internalStandard)
    --
    If @internalStandardID = 0
        RAISERROR ('Could not find entry in database for predigestion internal standard "%s"', 11, 49, @internalStandard)

    If (@mode In ('add', 'check_add')) And @internalStandardState <> 'A'
        RAISERROR ('Predigestion internal standard "%s" is not active; this standard cannot be used when creating a new experiment', 11, 49, @internalStandard)

    ---------------------------------------------------
    -- Resolve postdigestion internal standard ID
    ---------------------------------------------------
    --
    Declare @postdigestIntStdID int = 0
    Set @internalStandardState = 'I'
    --
    SELECT @postdigestIntStdID = Internal_Std_Mix_ID,
           @internalStandardState = Active
    FROM T_Internal_Standards
    WHERE (Name = @postdigestIntStd)
    --
    If @postdigestIntStdID = 0
        RAISERROR ('Could not find entry in database for postdigestion internal standard "%s"', 11, 50, @postdigestIntStd)

    If (@mode In ('add', 'check_add')) And @internalStandardState <> 'A'
        RAISERROR ('Postdigestion internal standard "%s" is not active; this standard cannot be used when creating a new experiment', 11, 49, @postdigestIntStd)

    ---------------------------------------------------
    -- Resolve container name to ID
    -- Auto-switch name from 'none' to 'na'
    ---------------------------------------------------

    If @container = 'none'
        Set @container = 'na'

    Declare @contID int = 0
    --
    SELECT @contID = ID
    FROM T_Material_Containers
    WHERE (Tag = @container)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @contID = 0 Or @myError <> 0
        RAISERROR ('Invalid container name "%s"', 11, 51, @container)

    ---------------------------------------------------
    -- Resolve current container id to name
    -- (skip if adding experiment)
    ---------------------------------------------------
    Declare @curContainerName varchar(125) = ''
    --
    If Not @mode In ('add', 'check_add')
    Begin
        SELECT @curContainerName = Tag
        FROM T_Material_Containers
        WHERE ID = @curContainerID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error resolving name of current container', 11, 53)
    End

    ---------------------------------------------------
    -- Create temporary tables to hold cell cultures and reference compounds associated with the parent experiment
    ---------------------------------------------------

    CREATE TABLE #Tmp_ExpToCCMap (
        CC_Name varchar(128) not null,
        CC_ID int null
    )

    CREATE TABLE #Tmp_ExpToRefCompoundMap (
        Compound_IDName varchar(128) not null,
        Colon_Pos int null,
        Compound_ID int null
    )

    ---------------------------------------------------
    -- Resolve cell cultures
    -- Auto-switch from 'none' or 'na' or '(none)' to ''
    ---------------------------------------------------

    If @biomaterialList IN ('none', 'na', '(none)')
        Set @biomaterialList = ''

    -- Replace commas with semicolons
    If @biomaterialList Like '%,%'
        Set @biomaterialList = Replace(@biomaterialList, ',', ';')

    -- Get names of cell cultures from list argument into table
    --
    If @biomaterialList Like '%;%'
    Begin
        INSERT INTO #Tmp_ExpToCCMap (CC_Name)
        SELECT Value
        FROM dbo.parse_delimited_list(@biomaterialList, ';', 'add_update_experiment')
    End
    Else If @biomaterialList <> ''
    Begin
        INSERT INTO #Tmp_ExpToCCMap (CC_Name)
        VALUES (@biomaterialList)
    End
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Could not populate temporary table for cell culture list', 11, 79)

    -- Verify that cell cultures exist
    --
    UPDATE #Tmp_ExpToCCMap
    SET CC_ID = Src.CC_ID
    FROM #Tmp_ExpToCCMap Target
         INNER JOIN T_Cell_Culture Src
           ON Src.CC_Name = Target.CC_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
        RAISERROR ('Error resolving cell culture name to ID', 11, 80)

    SELECT @invalidCCList = Coalesce(@invalidCCList + ', ' + CC_Name, CC_Name)
    FROM #Tmp_ExpToCCMap
    WHERE CC_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error looking for unresolved cell culture names', 11, 80)

    If IsNull(@invalidCCList, '') <> ''
        RAISERROR ('Invalid cell culture name(s): %s', 11, 81, @invalidCCList)

    ---------------------------------------------------
    -- Resolve reference compounds
    -- Auto-switch from 'none' or 'na' or '(none)' to ''
    ---------------------------------------------------

    If @referenceCompoundList IN ('none', 'na', '(none)', '100:(none)')
        Set @referenceCompoundList = ''

    -- Replace commas with semicolons
    If @referenceCompoundList Like '%,%'
        Set @referenceCompoundList = Replace(@referenceCompoundList, ',', ';')

    -- Get names of reference compounds from list argument into table
    --
    If @referenceCompoundList Like '%;%'
    Begin
        INSERT INTO #Tmp_ExpToRefCompoundMap (Compound_IDName, Colon_Pos)
        SELECT Value, CharIndex(':', Value)
        FROM dbo.parse_delimited_list(@referenceCompoundList, ';', 'add_update_experiment')
    End
    Else If @referenceCompoundList <> ''
    Begin
        INSERT INTO #Tmp_ExpToRefCompoundMap (Compound_IDName, Colon_Pos)
        VALUES (@referenceCompoundList, CharIndex(':', @referenceCompoundList))
    End
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Could not populate temporary table for reference compound list', 11, 90)

    -- Update entries in #Tmp_ExpToRefCompoundMap to remove extra text that may be present
    -- For example, switch from 3311:ANFTSQETQGAGK to 3311
    UPDATE #Tmp_ExpToRefCompoundMap
    SET Compound_IDName = Substring(Compound_IDName, 1, Colon_Pos - 1)
    WHERE Not Colon_Pos Is Null And Colon_Pos > 0

    -- Populate the Compound_ID column using any integers in Compound_IDName
    UPDATE #Tmp_ExpToRefCompoundMap
    SET Compound_ID = Try_Cast(Compound_IDName as Int)

    -- If any entries still have a null Compound_ID value, try matching via reference compound name
    -- We have numerous reference compounds with identical names, so matches found this way will be ambiguous
    --
    UPDATE #Tmp_ExpToRefCompoundMap
    SET Compound_ID = Src.Compound_ID
    FROM #Tmp_ExpToRefCompoundMap Target
         INNER JOIN T_Reference_Compound Src
           ON Src.Compound_Name = Target.Compound_IDName
    WHERE Target.Compound_ID IS Null
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
        RAISERROR ('Error resolving reference compound name to ID', 11, 91)

    -- Delete any entries to where the name is '(none)'
    DELETE #Tmp_ExpToRefCompoundMap
    FROM #Tmp_ExpToRefCompoundMap Target
         INNER JOIN T_Reference_Compound Src
           ON Src.Compound_id = Target.Compound_ID
    WHERE Src.Compound_Name = '(none)'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Look for invalid entries in #Tmp_ExpToRefCompoundMap
    ---------------------------------------------------
    --

    -- First look for entries without a Compound_ID
    --
    Set @invalidRefCompoundList = null

    SELECT @invalidRefCompoundList = Coalesce(@invalidRefCompoundList + ', ' + Compound_IDName, Compound_IDName)
    FROM #Tmp_ExpToRefCompoundMap
    WHERE Compound_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
        RAISERROR ('Error looking for unresolved reference compound names', 11, 92)

    If Len(IsNull(@invalidRefCompoundList, '')) > 0
    Begin
        RAISERROR ('Invalid reference compound name(s): %s', 11, 93, @invalidRefCompoundList)
    End

    -- Next look for entries with an invalid Compound_ID
    --
    Set @invalidRefCompoundList = null

    SELECT @invalidRefCompoundList = Coalesce(@invalidRefCompoundList + ', ' + Compound_IDName, Compound_IDName)
    FROM #Tmp_ExpToRefCompoundMap Src
         LEFT OUTER JOIN T_Reference_Compound RC
           ON Src.Compound_ID = RC.Compound_ID
    WHERE NOT Src.Compound_ID IS NULL AND
          RC.Compound_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Len(IsNull(@invalidRefCompoundList, '')) > 0
    Begin
        RAISERROR ('Invalid reference compound ID(s): %s', 11, 93, @invalidRefCompoundList)
    End

    ---------------------------------------------------
    -- Add/update the experiment
    ---------------------------------------------------

    Declare @transName varchar(32)
    Set @logErrors = 1

    If @Mode = 'add'
    Begin
        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        -- Start transaction
        --
        Set @transName = 'Add_New_Experiment'
        Begin transaction @transName

        INSERT INTO T_Experiments (
                Experiment_Num,
                EX_researcher_PRN,
                EX_organism_ID,
                EX_reason,
                EX_comment,
                EX_created,
                EX_sample_concentration,
                EX_enzyme_ID,
                EX_Labelling,
                EX_lab_notebook_ref,
                EX_campaign_ID,
                EX_sample_prep_request_ID,
                EX_internal_standard_ID,
                EX_postdigest_internal_std_ID,
                EX_Container_ID,
                EX_wellplate_num,
                EX_well_num,
                EX_Alkylation,
                EX_Barcode,
                EX_Tissue_ID,
                Last_Used
            ) VALUES (
                @experimentName,
                @researcherUsername,
                @organismID,
                @reason,
                @comment,
                GETDATE(),
                @sampleConcentration,
                @enzymeID,
                @labelling,
                @labNotebookRef,
                @campaignID,
                @samplePrepRequest,
                @internalStandardID,
                @postdigestIntStdID,
                @contID,
                @wellplateName,
                @wellNumber,
                @alkylation,
                @barcode,
                @tissueIdentifier,
                Cast(GETDATE() as Date)
            )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed: "%s"', 11, 7, @experimentName)

        -- Get the ID of newly created experiment
        Set @experimentID = SCOPE_IDENTITY()

        -- As a precaution, query T_Experiments using Experiment name to make sure we have the correct Exp_ID
        Declare @experimentIDConfirm int = 0

        SELECT @experimentIDConfirm = Exp_ID
        FROM T_Experiments
        WHERE Experiment_Num = @experimentName

        If @experimentID <> IsNull(@experimentIDConfirm, @experimentID)
        Begin
            Declare @debugMsg varchar(512)
            Set @debugMsg = 'Warning: Inconsistent identity values when adding experiment ' + @experimentName + ': Found ID ' +
                            Cast(@experimentIDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' +
                            Cast(@experimentID as varchar(12))

            exec post_log_entry 'Error', @debugMsg, 'add_update_experiment'

            Set @experimentID = @experimentIDConfirm
        End

        Declare @StateID int = 1

        -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
            Exec alter_event_log_entry_user 3, @experimentID, @StateID, @callingUser

        -- Add the experiment to cell culture mapping
        -- The stored procedure uses table #Tmp_ExpToCCMap
        --
        execute @result = add_experiment_biomaterial
                                @experimentID,
                                @updateCachedInfo=0,
                                @message=@msg output
        --
        If @result <> 0
            RAISERROR ('Could not add experiment biomaterials to database for experiment "%s" :%s', 11, 1, @experimentName, @msg)

        -- Add the experiment to reference compound mapping
        -- The stored procedure uses table #Tmp_ExpToRefCompoundMap
        --
        execute @result = add_experiment_reference_compound
                                @experimentID,
                                @updateCachedInfo=1,
                                @message=@msg output
        --
        If @result <> 0
            RAISERROR ('Could not add experiment reference compounds to database for experiment "%s" :%s', 11, 1, @experimentName, @msg)

        -- Material movement logging
        --
        If @curContainerID != @contID
        Begin
            exec post_material_log_entry
                'Experiment Move',
                @experimentName,
                'na',
                @container,
                @callingUser,
                'Experiment added'
        End

        -- We made it this far, commit
        --
        commit transaction @transName

    End -- add mode

    If @Mode = 'update'
    Begin
        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        -- Start transaction
        --
        Set @transName = 'Update_Experiment'
        Begin transaction @transName

        UPDATE T_Experiments Set
            Experiment_Num = @experimentName,
            EX_researcher_PRN = @researcherUsername,
            EX_organism_ID = @organismID,
            EX_reason = @reason,
            EX_comment = @comment,
            EX_sample_concentration = @sampleConcentration,
            EX_enzyme_ID = @enzymeID,
            EX_Labelling = @labelling,
            EX_lab_notebook_ref = @labNotebookRef,
            EX_campaign_ID = @campaignID,
            EX_sample_prep_request_ID = @samplePrepRequest,
            EX_internal_standard_ID = @internalStandardID,
            EX_postdigest_internal_std_ID = @postdigestIntStdID,
            EX_Container_ID = @contID,
            EX_wellplate_num = @wellplateName,
            EX_well_num = @wellNumber,
            EX_Alkylation = @alkylation,
            EX_Barcode = @barcode,
            EX_Tissue_ID = @tissueIdentifier,
            Last_Used = Case When EX_organism_ID <> @organismID OR
                                  EX_reason <> @reason OR
                                  EX_comment <> @comment OR
                                  EX_enzyme_ID <> @enzymeID OR
                                  EX_Labelling <> @labelling OR
                                  EX_campaign_ID <> @campaignID OR
                                  EX_sample_prep_request_ID <> @samplePrepRequest OR
                                  EX_Alkylation <> @alkylation
                             Then Cast(GetDate() as Date)
                             Else Last_Used
                        End
        WHERE Exp_ID = @experimentId
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @experimentName)

        -- Update the experiment to cell culture mapping
        -- The stored procedure uses table #Tmp_ExpToCCMap
        --
        execute @result = add_experiment_biomaterial
                                @experimentID,
                                @updateCachedInfo=0,
                                @message=@msg output
        --
        If @result <> 0
            RAISERROR ('Could not update experiment biomaterial mapping for experiment "%s" :%s', 11, 1, @experimentName, @msg)

        -- Update the experiment to reference compound mapping
        -- The stored procedure uses table #Tmp_ExpToRefCompoundMap
        --
        execute @result = add_experiment_reference_compound
                                @experimentID,
                                @updateCachedInfo=1,
                                @message=@msg output
        --
        If @result <> 0
            RAISERROR ('Could not update experiment reference compound mapping for experiment "%s" :%s', 11, 1, @experimentName, @msg)

        -- Material movement logging
        --
        If @curContainerID != @contID
        Begin
            exec post_material_log_entry
                'Experiment Move',
                @experimentName,
                @curContainerName,
                @container,
                @callingUser,
                'Experiment updated'
        End

        If Len(@existingExperimentName) > 0 And @existingExperimentName <> @experimentName
        Begin
            Set @message = 'Renamed experiment from "' + @existingExperimentName + '" to "' + @experimentName + '"'
        End

        -- We made it this far, commit
        --
        commit transaction @transName

    End -- update mode

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Experiment ' + @experimentName
            exec post_log_entry 'Error', @logMessage, 'add_update_experiment'
        End

    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_experiment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_experiment] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_experiment] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_experiment] TO [Limited_Table_Write] AS [dbo]
GO
