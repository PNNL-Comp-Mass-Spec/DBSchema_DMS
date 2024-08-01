/****** Object:  StoredProcedure [dbo].[add_update_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_dataset]
/****************************************************
**
**  Desc:
**      This procedure is called from both web pages and from other procedures
**      - The Dataset Entry page (https://dms2.pnl.gov/dataset/create) calls it with @mode = 'add_dataset_create_task'
**      - Dataset Detail Report pages call it with @mode = 'update'
**      - Spreadsheet Loader (https://dms2.pnl.gov/upload/main) calls it with with @mode as 'add_dataset_create_task, 'check_update', or 'check_add'
**      - It is also called with @mode = 'add' when the Data Import Manager (DIM) calls add_new_dataset while processing dataset trigger files
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/13/2003
**          01/10/2002
**          12/10/2003 grk - Added wellplate, internal standards, and LC column stuff
**          01/11/2005 grk - Added bad dataset stuff
**          02/23/2006 grk - Added LC cart tracking stuff and EUS stuff
**          01/12/2007 grk - Added verification mode
**          02/16/2007 grk - Added validation of dataset name (Ticket #390)
**          04/30/2007 grk - Added better name validation (Ticket #450)
**          07/26/2007 mem - Now checking dataset type (@msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**          09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          10/08/2007 jds - Added support for new mode 'add_trigger'.  Validation was taken from other stored procs from the 'add' mode
**          12/07/2007 mem - Now disallowing updates for datasets with a rating of -10 = Unreviewed (use update_dataset_dispositions instead)
**          01/08/2008 mem - Added check for @eusProposalID, @eusUsageType, or @eusUsersList being blank or 'no update' when @mode = 'add' and @requestID is 0
**          02/13/2008 mem - Now sending @datasetName to function validate_chars and checking for @badCh = '[space]' (Ticket #602)
**          02/15/2008 mem - Increased size of @folderName to varchar(128) (Ticket #645)
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          04/09/2008 mem - Added call to alter_event_log_entry_user to handle dataset rating entries (event log target type 8)
**          05/23/2008 mem - Now calling schedule_predefined_analysis_jobs if the dataset rating is changed from -5 to 5 and no jobs exist yet for this dataset (Ticket #675)
**          04/08/2009 jds - Added support for the additional parameters @secSep and @MRMAttachment to the add_update_requested_run stored procedure (Ticket #727)
**          09/16/2009 mem - Now checking dataset type (@msType) against the Instrument_Allowed_Dataset_Type table (Ticket #748)
**          01/14/2010 grk - Assign storage path on creation of dataset
**          02/28/2010 grk - Added add-auto mode for requested run
**          03/02/2010 grk - Added status field to requested run
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if @operatorUsername contains a person's real name rather than their username
**          07/27/2010 grk - Try-catch for error handling
**          08/26/2010 mem - Now passing @callingUser to schedule_predefined_analysis_jobs
**          08/27/2010 mem - Now calling validate_instrument_group_and_dataset_type to validate the instrument type for the selected instrument's instrument group
**          09/01/2010 mem - Now passing @SkipTransactionRollback to add_update_requested_run
**          09/02/2010 mem - Now allowing @msType to be blank or invalid when @mode = 'add'; The assumption is that the dataset type will be auto-updated if needed based on the results from the DatasetQuality tool, which runs during dataset capture
**                         - Expanded @msType to varchar(50)
**          09/09/2010 mem - Now passing @AutoPopulateUserListIfBlank to add_update_requested_run
**                         - Relaxed EUS validation to ignore @eusProposalID, @eusUsageType, and @eusUsersList if @requestID is non-zero
**                         - Auto-updating RequestID, experiment, and EUS information for "Blank" datasets
**          03/10/2011 mem - Tweaked text added to dataset comment when dataset type is auto-updated or auto-defined
**          05/11/2011 mem - Now calling get_instrument_storage_path_for_new_datasets
**          05/12/2011 mem - Now passing @RefDate and @AutoSwitchActiveStorage to get_instrument_storage_path_for_new_datasets
**          05/24/2011 mem - Now checking for change of rating from -5, -6, or -7 to 5
**                         - Now ignoring AJ_DatasetUnreviewed jobs when determining whether or not to call schedule_predefined_analysis_jobs
**          12/12/2011 mem - Updated call to validate_eus_usage to treat @eusUsageType as an input/output parameter
**          12/14/2011 mem - Now passing @callingUser to add_update_requested_run and consume_scheduled_run
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**          01/11/2012 mem - Added parameter @aggregationJobDataset
**          02/29/2012 mem - Now auto-updating the @eus parameters if null
**                         - Now raising an error if other key parameters are null/empty
**          09/12/2012 mem - Now auto-changing HMS-HMSn to IMS-HMS-HMSn for IMS datasets
**                         - Now requiring that the dataset name be 90 characters or less (longer names can lead to "path-too-long" errors; Windows has a 254 character path limit)
**          11/21/2012 mem - Now requiring that the dataset name be at least 6 characters in length
**          01/22/2013 mem - Now updating the dataset comment if the default dataset type is invalid for the instrument group
**          04/02/2013 mem - Now updating @LCCartName (if not blank) when updating an existing dataset
**          05/08/2013 mem - Now setting @wellplateName and @wellNumber to Null if they are blank or 'na'
**          02/27/2014 mem - Now skipping check for name ending in Raw or Wiff if @aggregationJobDataset is non-zero
**          05/07/2015 mem - Now showing URL http://dms2.pnl.gov/dataset_disposition/search if the user tries to change the rating from Unreleased to something else (previously showed http://dms2.pnl.gov/dataset_disposition/report)
**          05/29/2015 mem - Added parameter @captureSubfolder (only used if @mode is 'add' or 'bad')
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/19/2015 mem - Now auto-fixing QC_Shew names, e.g. QC_Shew_15-01 to QC_Shew_15_01
**          10/01/2015 mem - Add support for (ignore) for @eusProposalID, @eusUsageType, and @eusUsersList
**          10/14/2015 mem - Remove double quotes from error messages
**          01/29/2016 mem - Now calling get_wp_for_eus_proposal to get the best work package for the given EUS Proposal
**          02/23/2016 mem - Add Set XACT_ABORT on
**          05/23/2016 mem - Disallow certain dataset names
**          06/10/2016 mem - Try to auto-associate new datasets with an active requested run (only associate if only one active requested run matches the dataset name)
**          06/21/2016 mem - Add additional debug messages
**          08/25/2016 mem - Do not update the dataset comment if the dataset type is changed from 'GC-MS' to 'EI-HMS'
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/21/2016 mem - Pass @logDebugMessages to consume_scheduled_run
**          11/23/2016 mem - Include the dataset name when calling post_log_entry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          01/09/2017 mem - Pass @logDebugMessages to add_update_requested_run
**          02/23/2017 mem - Add parameter @lcCartConfig
**          03/06/2017 mem - Decreased maximum dataset name length from 90 characters to 80 characters
**          04/28/2017 mem - Disable logging certain messages to T_Log_Entries
**          06/13/2017 mem - Rename @operatorUsername to @requestorUsername when calling add_update_requested_run
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/29/2017 mem - Allow updating EUS info for existing datasets (calls add_update_requested_run)
**          06/12/2018 mem - Send @maxLength to append_to_text
**                         - Expand @warning to varchar(512)
**          04/15/2019 mem - Add call to update_cached_dataset_instruments
**          07/19/2019 mem - Change @eusUsageType to 'maintenance' if empty for _Tune_ or TuneMix datasets
**          11/11/2019 mem - Auto change 'Blank-' and 'blank_' to 'Blank'
**          09/15/2020 mem - Now showing 'https://dms2.pnl.gov/dataset_disposition/search' instead of http://
**          10/10/2020 mem - No longer update the comment when auto switching the dataset type
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          12/17/2020 mem - Verify that @captureSubfolder is a relative path and add debug messages
**          02/25/2021 mem - Remove the requested run comment from the dataset comment if the dataset comment starts with the requested run comment
**                         - Use replace_character_codes to replace character codes with punctuation marks
**                         - Use remove_cr_lf to replace linefeeds with semicolons
**          05/26/2021 mem - When @mode is 'add', 'check_add', or 'add_trigger', possibly override the EUSUsageType based on the campaign's EUS Usage Type
**                         - Expand @message to varchar(1024)
**          05/27/2021 mem - Refactor EUS Usage validation code into validate_eus_usage
**          10/01/2021 mem - Also check for a period when verifying that the dataset name does not end with .raw or .wiff
**          11/12/2021 mem - When @mode is update, pass @batch, @block, and @runOrder to add_update_requested_run
**          02/17/2022 mem - Rename variables and add missing Else clause
**          05/23/2022 mem - Rename @requestorUsername to @requesterUsername when calling add_update_requested_run
**          05/27/2022 mem - Expand @msg to varchar(1024)
**          08/22/2022 mem - Do not log EUS Usage validation errors to T_Log_Entries
**          11/25/2022 mem - Rename parameter to @wellplateName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2023 mem - Use new argument name, @requestName
**                         - Use calling user name for the dataset creator user
**          03/02/2023 mem - Use renamed table names
**          08/02/2023 mem - Prevent adding a dataset for an inactive instrument
**          08/03/2023 mem - Allow creation of datasets for instruments in group 'Data_Folders' (specifically, the DMS_Pipeline_Data instrument)
**          09/07/2023 mem - Update warning messages
**          10/24/2023 mem - Use update_cart_parameters to add/update Cart Config ID in T_Requested_Run
**          10/29/2023 mem - Call add_new_dataset_to_creation_queue instead of create_xml_dataset_trigger_file
**          10/30/2023 mem - Replace mode 'add_trigger' with 'add_dataset_create_task', expanding @mode to varchar(32)
**          07/31/2024 mem - Remove the leading semicolon when removing the requested run comment from the dataset comment
**
*****************************************************/
(
    @datasetName varchar(128),                  -- Dataset name
    @experimentName varchar(64),                -- Experiment name
    @operatorUsername varchar(64),
    @instrumentName varchar(64),
    @msType varchar(50),                        -- Dataset Type
    @lcColumnName varchar(64),
    @wellplateName varchar(64) = 'na',          -- Wellplate name
    @wellNumber varchar(64) = 'na',
    @secSep varchar(64) = 'na',
    @internalStandards varchar(64) = 'none',
    @comment varchar(512) = '',
    @rating varchar(32) = 'Unknown',
    @lcCartName varchar(128),
    @eusProposalID varchar(10) = 'na',
    @eusUsageType varchar(50),
    @eusUsersList varchar(1024) = '',
    @requestID int = 0,                         -- Only valid if @mode is 'add', 'check_add', or 'add_dataset_create_task'; ignored if @mode is 'update' or 'check_update'
    @workPackage varchar(50) = 'none',          -- Only valid if @mode is 'add', 'check_add', or 'add_dataset_create_task'
    @mode varchar(32) = 'add',                  -- Can be 'add', 'update', 'bad', 'check_update', 'check_add', 'add_dataset_create_task' (deprecated: 'add_trigger')
    @message varchar(1024) output,
    @callingUser varchar(128) = '',
    @aggregationJobDataset tinyint = 0,         -- Set to 1 when creating an in-silico dataset to associate with an aggregation job
    @captureSubfolder varchar(255) = '',        -- Only used when @mode is 'add' or 'bad'
    @lcCartConfig varchar(128) = '',
    @logDebugMessages tinyint = 0
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(1024)
    Declare @folderName varchar(128)
    Declare @addingDataset tinyint = 0

    Declare @result int
    Declare @warning varchar(512)
    Declare @warningAddon varchar(128)
    Declare @experimentCheck varchar(128)
    Declare @debugMsg varchar(512)
    Declare @logErrors tinyint = 0

    Declare @requestName varchar(128)
    Declare @reqRunInstSettings varchar(512)
    Declare @reqRunComment varchar(1024)
    Declare @reqRunInternalStandard varchar(50)
    Declare @mrmAttachmentID int
    Declare @reqRunStatus varchar(24)

    Declare @batch int
    Declare @block int
    Declare @runOrder int

    Declare @newValue varchar(12)

    Set @message = ''
    Set @warning = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_dataset', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @mode = LTrim(RTrim(IsNull(@mode, '')))
    Set @secSep = LTrim(RTrim(IsNull(@secSep, '')))
    Set @lcColumnName = LTrim(RTrim(IsNull(@lcColumnName, '')))
    Set @datasetName = LTrim(RTrim(IsNull(@datasetName, '')))

    Set @experimentName = LTrim(RTrim(IsNull(@experimentName, '')))
    Set @operatorUsername = LTrim(RTrim(IsNull(@operatorUsername, '')))
    Set @instrumentName = LTrim(RTrim(IsNull(@instrumentName, '')))
    Set @rating = LTrim(RTrim(IsNull(@rating, '')))

    Set @internalStandards = IsNull(@internalStandards, '')
    If @internalStandards = '' Or @internalStandards = 'na'
        Set @internalStandards = 'none'

    If IsNull(@mode, '') = ''
    Begin
        Set @msg = '@mode must be specified'
        RAISERROR (@msg, 11, 17)
    End

    If IsNull(@secSep, '') = ''
    Begin
        Set @msg = 'Separation type must be specified'
        RAISERROR (@msg, 11, 17)
    End
    --
    If IsNull(@lcColumnName, '') = ''
    Begin
        Set @msg = 'LC Column name must be specified'
        RAISERROR (@msg, 11, 16)
    End
    --
    If IsNull(@datasetName, '') = ''
    Begin
        Set @msg = 'Dataset name must be specified'
        RAISERROR (@msg, 11, 10)
    End
    --
    Set @folderName = @datasetName
    --
    If IsNull(@experimentName, '') = ''
    Begin
        Set @msg = 'Experiment name must be specified'
        RAISERROR (@msg, 11, 11)
    End
    --
    If IsNull(@folderName, '') = ''
    Begin
        Set @msg = 'Folder name must be specified'
        RAISERROR (@msg, 11, 12)
    End
    --
    If IsNull(@operatorUsername, '') = ''
    Begin
        Set @msg = 'Operator payroll number/HID must be specified'
        RAISERROR (@msg, 11, 13)
    End
    --
    If IsNull(@instrumentName, '') = ''
    Begin
        Set @msg = 'Instrument name must be specified'
        RAISERROR (@msg, 11, 14)
    End
    --
    Set @msType = IsNull(@msType, '')

    -- Allow @msType to be blank if @mode is Add or Bad but not if check_add or add_dataset_create_task or update
    If @msType = '' And NOT @mode In ('Add', 'Bad')
    Begin
        Set @msg = 'Dataset type must be specified'
        RAISERROR (@msg, 11, 15)
    End

    If IsNull(@lcCartName, '') = ''
    Begin
        Set @msg = 'LC Cart name must be specified'
        RAISERROR (@msg, 11, 15)
    End

    -- Assure that @comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
    Set @comment = dbo.replace_character_codes(@comment)

    -- Replace instances of CRLF (or LF) with semicolons
    Set @comment = dbo.remove_cr_lf(@comment)

    If IsNull(@rating, '') = ''
    Begin
        Set @msg = 'Rating must be specified'
        RAISERROR (@msg, 11, 15)
    End

    If IsNull(@wellplateName, '') IN ('', 'na')
        Set @wellplateName = NULL

    If IsNull(@wellNumber, '') IN ('', 'na')
        Set @wellNumber = NULL

    Set @workPackage   = IsNull(@workPackage, '')
    Set @eusProposalID = IsNull(@eusProposalID, '')
    Set @eusUsageType  = IsNull(@eusUsageType, '')
    Set @eusUsersList  = IsNull(@eusUsersList, '')

    Set @requestID = IsNull(@requestID, 0)
    Set @aggregationJobDataset = IsNull(@aggregationJobDataset, 0)
    Set @captureSubfolder = LTrim(RTrim(IsNull(@captureSubfolder, '')))

    If @captureSubfolder LIKE '\\%' OR @captureSubfolder LIKE '[A-Z]:\%'
    Begin
        Set @msg = 'Capture subfolder should be a subdirectory name below the source share for this instrument; it is currently a full path'
        RAISERROR (@msg, 11, 15)
    End

    Set @lcCartConfig = LTrim(RTrim(IsNull(@lcCartConfig, '')))

    If @lcCartConfig = ''
    Begin
        Set @lcCartConfig = null
    End

    Set @callingUser = IsNull(@callingUser, '')
    Set @logDebugMessages = IsNull(@logDebugMessages, 0)

    ---------------------------------------------------
    -- Determine if we are adding or check_adding a dataset
    ---------------------------------------------------
    --
    If @mode IN ('add', 'check_add', 'add_dataset_create_task', 'add_trigger')
        Set @addingDataset = 1
    Else
        Set @addingDataset = 0

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = '@mode=' + @mode + ', @dataset=' + @datasetName + ', @requestID=' + Cast(@requestID as varchar(9)) + ', @callingUser=' + @callingUser
        exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
    End

    ---------------------------------------------------
    -- Validate dataset name
    ---------------------------------------------------
    --
    Declare @badCh varchar(128) = dbo.validate_chars(@datasetName, '')

    If @badCh <> ''
    Begin
        If @badCh = '[space]'
        Begin
            Set @msg = 'Dataset name may not contain spaces'
        End
        Else
        Begin
            If Len(@badCh) = 1
                Set @msg = 'Dataset name may not contain the character ' + @badCh
            Else
                Set @msg = 'Dataset name may not contain the characters ' + @badCh
        End

        RAISERROR (@msg, 11, 1)
    End

    If @aggregationJobDataset = 0 And (@datasetName Like '%[.]raw' Or @datasetName Like '%[.]wiff' Or @datasetName Like '%[.]d')
    Begin
        Set @msg = 'Dataset name may not end in .raw, .wiff, or .d'
        RAISERROR (@msg, 11, 2)
    End

    If Len(@datasetName) > 80 And Not @mode in ('update', 'check_update')
    Begin
        Set @msg = 'Dataset name cannot be over 80 characters in length; currently ' + Convert(varchar(12), Len(@datasetName)) + ' characters'
        RAISERROR (@msg, 11, 3)
    End

    If Len(@datasetName) < 6
    Begin
        Set @msg = 'Dataset name must be at least 6 characters in length; currently ' + Convert(varchar(12), Len(@datasetName)) + ' characters'
        RAISERROR (@msg, 11, 3)
    End

    If @datasetName in (
       'Archive', 'Dispositioned', 'Processed', 'Reprocessed', 'Not-Dispositioned',
       'High-pH', 'NotDispositioned', 'Yufeng', 'Uploaded', 'Sequence', 'Sequences',
       'Peptide', 'BadData')
    Begin
        Set @msg = 'Dataset name is too generic; be more specific'
        RAISERROR (@msg, 11, 3)
    End

    ---------------------------------------------------
    -- Resolve ID for rating
    ---------------------------------------------------

    Declare @ratingID int

    If @mode = 'bad'
    Begin
        Set @ratingID = -1 -- "No Data"
        Set @mode = 'add'
        Set @addingDataset = 1
    End
    Else
    Begin
        Exec @ratingID = get_dataset_rating_id @rating

        If @ratingID = 0
        Begin
            Set @msg = 'Could not find entry in database for rating ' + @rating
            RAISERROR (@msg, 11, 18)
        End
    End


    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @datasetID int
    Declare @curDSTypeID int
    Declare @curDSInstID int
    Declare @curDSStateID int
    Declare @curDSRatingID int
    Declare @newDSStateID int

    Set @datasetID = 0
    SELECT
        @datasetID = Dataset_ID,
        @curDSInstID = DS_instrument_name_ID,
        @curDSStateID = DS_state_ID,
        @curDSRatingID = DS_Rating
    FROM T_Dataset
    WHERE Dataset_Num = @datasetName

    Set @datasetID = IsNull(@datasetID, 0)

    If @datasetID = 0
    Begin
        -- Cannot update a non-existent entry
        --
        If @mode IN ('update', 'check_update')
        Begin
            Set @msg = 'Cannot update: Dataset ' + @datasetName + ' is not in database'
            RAISERROR (@msg, 11, 4)
        End
    End
    Else
    Begin
        -- Cannot create an entry that already exists
        --
        If @addingDataset = 1
        Begin
            Set @msg = 'Cannot add dataset ' + @datasetName + ' since already in database'
            RAISERROR (@msg, 11, 5)
        End

        -- Do not allow a rating change from 'Unreviewed' to any other rating within this procedure
        --
        If @curDSRatingID = -10 And @rating <> 'Unreviewed'
        Begin
            Set @msg = 'Cannot change dataset rating from Unreviewed with this mechanism; use the Dataset Disposition process instead ("https://dms2.pnl.gov/dataset_disposition/search" or SP update_dataset_dispositions)'
            RAISERROR (@msg, 11, 6)
        End
    End

    ---------------------------------------------------
    -- Resolve ID for LC Column
    ---------------------------------------------------

    Declare @columnID int = -1

    SELECT @columnID = ID
    FROM T_LC_Column
    WHERE SC_Column_Number = @lcColumnName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @msg = 'Error trying to look up column ID'
        RAISERROR (@msg, 11, 93)
    End

    If @columnID = -1
    Begin
        Set @msg = 'Unknown LC column name: ' + @lcColumnName
        RAISERROR (@msg, 11, 94)
    End

    ---------------------------------------------------
    -- Resolve ID for LC Cart Config
    ---------------------------------------------------

    Declare @cartConfigID int

    If @lcCartConfig Is Null
    Begin
        Set @cartConfigID = null
    End
    Else
    Begin
        Set @cartConfigID = -1

        SELECT @cartConfigID = Cart_Config_ID
        FROM T_LC_Cart_Configuration
        WHERE Cart_Config_Name = @lcCartConfig
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @msg = 'Error trying to look up LC cart config ID'
            RAISERROR (@msg, 11, 95)
        End

        If @cartConfigID = -1
        Begin
            Set @msg = 'Unknown LC cart config: ' + @lcCartConfig
            RAISERROR (@msg, 11, 96)
        End
    End

    ---------------------------------------------------
    -- Resolve ID for @secSep
    ---------------------------------------------------

    Declare @sepID int = 0

    SELECT @sepID = SS_ID
    FROM T_Secondary_Sep
    WHERE SS_name = @secSep
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @msg = 'Error trying to look up separation type ID'
        RAISERROR (@msg, 11, 98)
    End

    If @sepID = 0
    Begin
        Set @msg = 'Unknown separation type: ' + @secSep
        RAISERROR (@msg, 11, 99)
    End

    ---------------------------------------------------
    -- Resolve ID for @internalStandards
    ---------------------------------------------------

    Declare @intStdID int = -1

    SELECT @intStdID = Internal_Std_Mix_ID
    FROM [T_Internal_Standards]
    WHERE [Name] = @internalStandards
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @msg = 'Error trying to look up internal standards ID'
        RAISERROR (@msg, 11, 95)
    End

    If @intStdID = -1
    Begin
        Set @msg = 'Unknown internal standard name: ' + @internalStandards
        RAISERROR (@msg, 11, 96)
    End

    ---------------------------------------------------
    -- If Dataset starts with "Blank", make sure @experimentName contains "Blank"
    ---------------------------------------------------

    If @datasetName Like 'Blank%' And @addingDataset = 1
    Begin
        If NOT @experimentName LIKE '%blank%'
        Begin
            Set @experimentName = 'blank'
        End

        If @experimentName In ('Blank-', 'Blank_')
        Begin
            Set @experimentName = 'blank'
        End
    End

    ---------------------------------------------------
    -- Resolve experiment ID
    ---------------------------------------------------

    Declare @experimentID int
    execute @experimentID = get_experiment_id @experimentName

    If @experimentID = 0 And @experimentName LIKE 'QC_Shew_[0-9][0-9]_[0-9][0-9]' And @experimentName LIKE '%-%'
    Begin
        Declare @newExperiment varchar(64) = Replace(@experimentName, '-', '_')
        execute @experimentID = get_experiment_id @newExperiment

        If @experimentID > 0
        Begin
            SELECT @experimentName = Experiment_Num
            FROM T_Experiments
            WHERE Exp_ID = @experimentID
        End
    End

    If @experimentID = 0
    Begin
        Set @msg = 'Could not find entry in database for experiment ' + @experimentName
        RAISERROR (@msg, 11, 12)
    End

    ---------------------------------------------------
    -- Resolve instrument ID
    ---------------------------------------------------

    Declare @instrumentID int
    Declare @instrumentClass varchar(64) = ''
    Declare @instrumentGroup varchar(64) = ''
    Declare @instrumentStatus varchar(64) = ''
    Declare @defaultDatasetTypeID int
    Declare @msTypeOld varchar(50)

    execute @instrumentID = get_instrument_id @instrumentName

    If @instrumentID = 0
    Begin
        Set @msg = 'Could not find entry in database for instrument ' + @instrumentName
        RAISERROR (@msg, 11, 14)
    End

    ---------------------------------------------------
    -- Lookup the instrument class, group, and status
    ---------------------------------------------------

    SELECT @instrumentClass = IN_Class,
           @instrumentGroup = IN_Group,
           @instrumentStatus = IN_Status
    FROM T_Instrument_Name
    WHERE Instrument_ID = @instrumentID

    If @instrumentGroup = ''
    Begin
        Set @msg = 'Instrument group not defined for instrument ' + @instrumentName + '; contact a DMS administrator to fix this'
        RAISERROR (@msg, 11, 14)
    End

    If @instrumentStatus <> 'active' And @instrumentClass <> 'Data_Folders'
    Begin
        Set @msg = 'Instrument ' + @instrumentName + ' is not active; new datasets cannot be added for this instrument; contact a DMS administrator if the instrument status should be changed'
        RAISERROR (@msg, 11, 14)
    End

    ---------------------------------------------------
    -- Lookup the default dataset type ID (could be null)
    ---------------------------------------------------

    SELECT @defaultDatasetTypeID = Default_Dataset_Type
    FROM T_Instrument_Group
    WHERE IN_Group = @instrumentGroup


    ---------------------------------------------------
    -- Resolve dataset type ID
    ---------------------------------------------------

    Declare @datasetTypeID int
    execute @datasetTypeID = get_dataset_type_id @msType

    If @datasetTypeID = 0
    Begin
        -- Could not resolve @msType to a dataset type
        -- If @mode is Add, we will auto-update @msType to the default
        --
        If @addingDataset = 1 And IsNull(@defaultDatasetTypeID, 0) > 0
        Begin
            -- Use the default dataset type
            Set @datasetTypeID = @defaultDatasetTypeID

            Set @msTypeOld = @msType

            -- Update @msType
            SELECT @msType = DST_name
            FROM T_Dataset_Type_Name
            WHERE DST_Type_ID = @datasetTypeID
        End
        Else
        Begin
            Set @msg = 'Could not find entry in database for dataset type ' + @msType
            RAISERROR (@msg, 11, 13)
        End
    End


    ---------------------------------------------------
    -- Verify that dataset type is valid for given instrument group
    ---------------------------------------------------

    Declare @allowedDatasetTypes varchar(255)

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Call validate_instrument_group_and_dataset_type with type = ' + @msType + ' and group = ' + @instrumentGroup
        exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
    End

    exec @result = validate_instrument_group_and_dataset_type @msType, @instrumentGroup, @datasetTypeID output, @msg output

    If @result <> 0 And @addingDataset = 1 And IsNull(@defaultDatasetTypeID, 0) > 0
    Begin
        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Dataset type is not valid for this instrument group, however, @mode is Add, so auto-update @msType'
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        -- Dataset type is not valid for this instrument group
        -- However, @mode is Add, so we will auto-update @msType
        --
        If @msType IN ('HMS-MSn', 'HMS-HMSn') And Exists (
            SELECT IGADST.Dataset_Type
            FROM T_Instrument_Group ING
                 INNER JOIN T_Instrument_Name InstName
                   ON ING.IN_Group = InstName.IN_Group
                 INNER JOIN T_Instrument_Group_Allowed_DS_Type IGADST
                   ON ING.IN_Group = IGADST.IN_Group
            WHERE InstName.IN_Name = @instrumentName AND
                  IGADST.Dataset_Type = 'IMS-HMS-HMSn' )
        Begin
            -- This is an IMS MS/MS dataset
            Set @msType = 'IMS-HMS-HMSn'
            execute @datasetTypeID = get_dataset_type_id @msType
        End
        Else
        Begin
            -- Not an IMS dataset; change @datasetTypeID to zero so that the default dataset type is used
            Set @datasetTypeID = 0
        End

        If @datasetTypeID = 0
        Begin
            Set @datasetTypeID = @defaultDatasetTypeID

            Set @msTypeOld = @msType

            -- Update @msType
            SELECT @msType = DST_name
            FROM T_Dataset_Type_Name
            WHERE DST_Type_ID = @datasetTypeID

            If @msTypeOld = 'GC-MS' And @msType = 'EI-HMS'
            Begin
                -- This happens for most datasets from instrument GCQE01; do not update the comment
                Set @result = 0
            End
        End

        -- Validate the new dataset type name (in case the default dataset type is invalid for this instrument group, which would indicate invalid data in table T_Instrument_Group)
        exec @result = validate_instrument_group_and_dataset_type @msType, @instrumentGroup, @datasetTypeID output, @msg output

        If @result <> 0
        Begin
            Set @comment = dbo.append_to_text(@comment, 'Error: Default dataset type defined in T_Instrument_Group is invalid', 0, ' - ', 512)
        End
    End

    If @result <> 0
    Begin
        -- @msg should already contain the details of the error
        If IsNull(@msg, '') = ''
            Set @msg = 'validate_instrument_group_and_dataset_type returned non-zero result code: ' + Convert(varchar(12), @result)

        RAISERROR (@msg, 11, 15)
    End

    ---------------------------------------------------
    -- Check for instrument changing when dataset not in new state
    ---------------------------------------------------
    --
    If @mode IN ('update', 'check_update') and @instrumentID <> @curDSInstID and @curDSStateID <> 1
    Begin
        Set @msg = 'Cannot change instrument if dataset not in "new" state'
        RAISERROR (@msg, 11, 23)
    End

    ---------------------------------------------------
    -- Resolve user ID for operator username
    ---------------------------------------------------

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = 'Call get_user_id with @operatorUsername = ' + @operatorUsername
        exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
    End

    Declare @userID int
    execute @userID = get_user_id @operatorUsername

    If @userID > 0
    Begin
        -- SP get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @operatorUsername contains simply the username
        --
        SELECT @operatorUsername = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for username @operatorUsername
        -- Try to auto-resolve the name

        Declare @matchCount int
        Declare @newUsername varchar(64)

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Call auto_resolve_name_to_username with @operatorUsername = ' + @operatorUsername
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        exec auto_resolve_name_to_username @operatorUsername, @matchCount output, @newUsername output, @userID output

        If @matchCount = 1
        Begin
            -- Single match found; update @operatorUsername
            Set @operatorUsername = @newUsername
        End
        Else
        Begin
            Set @msg = 'Could not find entry in database for operator username ' + @operatorUsername
            RAISERROR (@msg, 11, 19)
        End
    End

    ---------------------------------------------------
    -- Perform additional steps if a requested run ID was provided
    ---------------------------------------------------

    If @requestID <> 0 AND @addingDataset = 1
    Begin
        ---------------------------------------------------
        -- Verify acceptable combination of EUS fields
        ---------------------------------------------------

        If (@eusProposalID <> '' OR @eusUsageType <> '' OR @eusUsersList <> '')
        Begin
            If (@eusUsageType = '(lookup)' AND @eusProposalID = '(lookup)' AND @eusUsersList = '(lookup)') OR (@eusUsageType = '(ignore)')
            Begin
                Set @warning = ''
            End
            Else
            Begin
                Set @warning = 'Warning: ignoring proposal ID, usage type, and user list since request ' + Convert(varchar(12), @requestID) + ' was specified'
            End

            -- When a request is specified, force @eusProposalID, @eusUsageType, and @eusUsersList to be blank
            -- Previously, we would raise an error here
            Set @eusProposalID = ''
            Set @eusUsageType = ''
            Set @eusUsersList = ''

            If @logDebugMessages > 0
            Begin
                exec post_log_entry 'Debug', @warning, 'add_update_dataset'
            End
        End

        ---------------------------------------------------
        -- If the dataset starts with "blank" but @requestID is non-zero, this is likely incorrect
        -- Auto-update things if this is the case
        ---------------------------------------------------

        If @datasetName Like 'Blank%'
        Begin
            -- See if the experiment matches for this request; if it doesn't, change @requestID to 0
            Set @experimentCheck = ''

            SELECT @experimentCheck = E.Experiment_Num
            FROM T_Experiments E INNER JOIN
                 T_Requested_Run RR ON E.Exp_ID = RR.Exp_ID
            WHERE RR.ID = @requestID

            If @experimentCheck <> @experimentName
                Set @requestID = 0
        End
    End

    ---------------------------------------------------
    -- If the dataset starts with 'Blank' and @requestID is zero, perform some additional checks
    ---------------------------------------------------
    --
    If @requestID = 0 AND @addingDataset = 1
    Begin
        -- If the EUS information is not defined, auto-define the EUS usage type as 'MAINTENANCE'
        If (@datasetName Like 'Blank%' Or
            @datasetName Like '%[_]Tune[_]%' Or
            @datasetName Like '%TuneMix%'
           ) And
           @eusProposalID = '' And
           @eusUsageType = ''
        Begin
            Set @eusUsageType = 'MAINTENANCE'
        End
    End

    ---------------------------------------------------
    -- Possibly look for an active requested run that we can auto-associate with this dataset
    ---------------------------------------------------
    --
    If @requestID = 0 AND @addingDataset = 1
    Begin
        Declare @requestInstGroup varchar(128)

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Call find_active_requested_run_for_dataset with @datasetName = ' + @datasetName
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        EXEC find_active_requested_run_for_dataset @datasetName, @experimentID, @requestID out, @requestInstGroup OUT, @showDebugMessages=0

        If @requestID > 0
        Begin
            -- Match found; check for an instrument group mismatch
            If @requestInstGroup <> @instrumentGroup
            Begin
                Set @warning = dbo.append_to_text(@warning,
                    'Instrument group for requested run (' + @requestInstGroup + ') ' +
                    'does not match instrument group for ' + @instrumentName + ' (' + @instrumentGroup + ')', 0, '; ', 512)
            End
        End
    End

    ---------------------------------------------------
    -- Update the dataset comment if it starts with the requested run's comment
    ---------------------------------------------------
    --
    If @requestID <> 0 AND @addingDataset = 1
    Begin
        Set @reqRunComment = ''

        SELECT @reqRunComment = RDS_comment
        FROM T_Requested_Run
        WHERE ID = @requestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Assure that @reqRunComment doesn't have &quot; or &#34; or &amp;
        Set @reqRunComment = dbo.replace_character_codes(@reqRunComment)

        If Len(Coalesce(@reqRunComment, '')) > 0 And (@comment = @reqRunComment Or @comment LIKE @reqRunComment + '%')
        Begin
            If Len(@comment) = Len(@reqRunComment)
            Begin
                Print 'Setting the dataset comment to an empty string since it matches the requested run comment'
                Set @comment = ''
            End
            Else
            Begin
                Set @comment = LTrim(Substring(@comment, Len(@reqRunComment) + 2, Len(@comment)))
            End
        End
    End

    -- Validation checks are complete; now enable @logErrors
    Set @logErrors = 1

    ---------------------------------------------------
    -- Action for dataset create task mode
    ---------------------------------------------------

    If @mode = 'add_dataset_create_task' Or @mode = 'add_trigger'
    Begin

        If @requestID <> 0
        Begin

            ---------------------------------------------------
            -- Validate that experiments match
            -- (check code taken from consume_scheduled_run stored procedure)
            ---------------------------------------------------

            -- Get experiment ID from dataset;
            -- this was already done above

            -- Get experiment ID from scheduled run
            --
            Declare @reqExperimentID int = 0

            SELECT @reqExperimentID = Exp_ID
            FROM T_Requested_Run
            WHERE ID = @requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                Set @message = 'Error trying to look up experiment for request'
                RAISERROR (@message, 11, 86)
            End

            -- Validate that experiments match
            --
            If @experimentID <> @reqExperimentID
            Begin
                Set @message = 'Experiment for dataset (' + @experimentName + ') does not match with the requested run''s experiment (Request ' + Convert(varchar(12), @requestID) + ')'
                RAISERROR (@message, 11, 72)
            End
        End

        ---------------------------------------------------
        -- Resolve ID for LC Cart and update requested run table
        ---------------------------------------------------

        Declare @cartID int = 0

        SELECT @cartID = ID
        FROM T_LC_Cart
        WHERE Cart_Name = @lcCartName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @msg = 'Error trying to look up cart ID'
            RAISERROR (@msg, 11, 33)
        End

        If @cartID = 0
        Begin
            Set @msg = 'Unknown LC Cart name: ' + @lcCartName
            RAISERROR (@msg, 11, 35)
        End

        If @requestID = 0
        Begin -- <b1>

            -- RequestID not specified
            -- Try to determine EUS information using Experiment name

            -- Check code taken from add_update_requested_run stored procedure

            ---------------------------------------------------
            -- Lookup EUS field (only effective for experiments that have associated sample prep requests)
            -- This will update the data in @eusUsageType, @eusProposalID, or @eusUsersList if it is "(lookup)"
            ---------------------------------------------------

            exec @myError = lookup_eus_from_experiment_sample_prep
                            @experimentName,
                            @eusUsageType output,
                            @eusProposalID output,
                            @eusUsersList output,
                            @msg output

            If @myError <> 0
                RAISERROR ('lookup_eus_from_experiment_sample_prep: %s', 11, 1, @msg)

            If IsNull(@msg, '') <> ''
            Begin
                Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
            End

            ---------------------------------------------------
            -- Validate EUS type, proposal, and user list
            ---------------------------------------------------

            Declare @eusUsageTypeID Int

            exec @myError = validate_eus_usage
                                @eusUsageType output,
                                @eusProposalID output,
                                @eusUsersList output,
                                @eusUsageTypeID output,
                                @msg output,
                                @AutoPopulateUserListIfBlank = 0,
                                @samplePrepRequest = 0,
                                @experimentID = @experimentID,
                                @campaignID = 0,
                                @addingItem = @addingDataset

            If @myError <> 0
            Begin
                Set @logErrors = 0
                RAISERROR ('validate_eus_usage: %s', 11, 1, @msg)
            End

            If IsNull(@msg, '') <> ''
            Begin
                Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
            End

        End -- </b1>
        Else
        Begin -- <b2>

            ---------------------------------------------------
            -- Verify that request ID is correct
            ---------------------------------------------------

            If NOT EXISTS (SELECT ID FROM T_Requested_Run WHERE ID = @requestID)
            Begin
                Set @msg = 'Request ID not found'
                RAISERROR (@msg, 11, 52)
            End

        End -- </b2>

        Declare @dsCreatorUsername varchar(256)

        If @callingUser = ''
            Set @dsCreatorUsername = suser_sname()
        Else
            Set @dsCreatorUsername = @callingUser

        Declare @run_Start varchar(10) = ''
        Declare @run_Finish varchar(10) = ''

        If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
            Set @warning = @message

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Create trigger for dataset ' + @datasetName + ', instrument ' + @instrumentName + ', request ' + Cast(@requestID as varchar(9))
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        Exec @result = add_new_dataset_to_creation_queue
                        @datasetName,           -- Dataset name
                        @experimentName,        -- Experiment name
                        @instrumentName,        -- Instrument name
                        @secSep,                -- Separation type
                        @lcCartName,            -- LC cart
                        @lcCartConfig,          -- LC cart config
                        @lcColumnName,          -- LC column
                        @wellplateName,         -- Wellplate
                        @wellNumber,            -- Well number
                        @msType,                -- Datset type
                        @operatorUsername,      -- Operator username
                        @dsCreatorUsername,     -- Dataset creator username
                        @comment,               -- Comment
                        @rating,                -- Interest rating
                        @requestID,             -- Requested run ID
                        @workPackage,           -- Work package
                        @eusUsageType,          -- EUS usage type
                        @eusProposalID,         -- EUS proposal id
                        @eusUsersList,          -- EUS users list
                        @captureSubfolder,      -- Capture subfolder
                        @message output

        If @result > 0
        Begin
            -- add_new_dataset_to_creation_queue should have already logged critical errors to T_Log_Entries
            -- No need for this procedure to log the message again
            Set @logErrors = 0
            Set @msg = 'There was an error while creating the XML Trigger file: ' + @message
            RAISERROR (@msg, 11, 55)
        End
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin

        ---------------------------------------------------
        -- Lookup storage path ID
        ---------------------------------------------------
        --
        Declare @storagePathID int = 0
        Declare @refDate datetime = GetDate()

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Call get_instrument_storage_path_for_new_datasets with @instrumentID = ' + Cast(@instrumentID as varchar(12))
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        Exec @storagePathID = get_instrument_storage_path_for_new_datasets @instrumentID, @refDate, @AutoSwitchActiveStorage=1, @infoOnly=0
        --
        If @storagePathID = 0
        Begin
            Set @storagePathID = 2 -- index of "none" in T_Storage_Path
            Set @msg = 'Valid storage path could not be found'
            RAISERROR (@msg, 11, 43)
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Add dataset ' + @datasetName + ', instrument ID ' + Cast(@instrumentID as varchar(9)) + ', storage path ID ' + Cast(@storagePathID as varchar(9))
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        -- Start transaction
        --
        Declare @transName varchar(32)
        Set @transName = 'add_new_dataset'

        Begin transaction @transName

        If IsNull(@aggregationJobDataset, 0) = 1
            Set @newDSStateID = 3
        Else
            Set @newDSStateID = 1

        If @logDebugMessages > 0
        Begin
            Print 'Insert into T_Dataset'
        End

        -- Insert values into a new row
        --
        INSERT INTO T_Dataset (
            Dataset_Num,
            DS_Oper_PRN,
            DS_comment,
            DS_created,
            DS_instrument_name_ID,
            DS_type_ID,
            DS_well_num,
            DS_sec_sep,
            DS_state_ID,
            DS_folder_name,
            DS_storage_path_ID,
            Exp_ID,
            DS_rating,
            DS_LC_column_ID,
            DS_wellplate_num,
            DS_internal_standard_ID,
            Capture_Subfolder,
            Cart_Config_ID
        ) VALUES (
            @datasetName,
            @operatorUsername,
            @comment,
            @refDate,
            @instrumentID,
            @datasetTypeID,
            @wellNumber,
            @secSep,
            @newDSStateID,
            @folderName,
            @storagePathID,
            @experimentID,
            @ratingID,
            @columnID,
            @wellplateName,
            @intStdID,
            @captureSubfolder,
            @cartConfigID
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0 or @myRowCount <> 1
        Begin
            Set @msg = 'Insert operation failed for dataset ' + @datasetName
            RAISERROR (@msg, 11, 7)
        End

        If @logDebugMessages > 0
        Begin
            Print 'Get ID using SCOPE_IDENTITY()'
        End

        -- Get the ID of newly created dataset
        --
        Set @datasetID = SCOPE_IDENTITY()

        -- As a precaution, query T_Dataset using Dataset name to make sure we have the correct Dataset_ID
        Declare @datasetIDConfirm int = 0

        SELECT @datasetIDConfirm = Dataset_ID
        FROM T_Dataset
        WHERE Dataset_Num = @datasetName

        If @datasetID <> IsNull(@datasetIDConfirm, @datasetID)
        Begin
            Set @debugMsg =
                'Warning: Inconsistent identity values when adding dataset ' + @datasetName + ': Found ID ' +
                Cast(@datasetIDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' +
                Cast(@datasetID as varchar(12))

            exec post_log_entry 'Error', @debugMsg, 'add_update_dataset'

            Set @datasetID = @datasetIDConfirm
        End

        -- If @callingUser is defined, call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            If @logDebugMessages > 0
            Begin
                Print 'Call alter_event_log_entry_user'
            End

            Exec alter_event_log_entry_user 4, @datasetID, @newDSStateID, @callingUser

            Exec alter_event_log_entry_user 8, @datasetID, @ratingID, @callingUser
        End

        ---------------------------------------------------
        -- If scheduled run is not specified, create one
        ---------------------------------------------------

        If @requestID = 0
        Begin -- <b3>

            If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
                Set @warning = @message

            If @workPackage In ('', 'none', 'na', '(lookup)')
            Begin
                If @logDebugMessages > 0
                Begin
                    Print 'Call get_wp_for_eus_proposal'
                End

                EXEC get_wp_for_eus_proposal @eusProposalID, @workPackage OUTPUT
            End

            Set @requestName = 'AutoReq_' + @datasetName

            If @logDebugMessages > 0
            Begin
                Print 'Call add_update_requested_run'
            End

            EXEC @result = dbo.add_update_requested_run
                                    @requestName = @requestName,
                                    @experimentName = @experimentName,
                                    @requesterUsername = @operatorUsername,
                                    @instrumentName = @instrumentName,
                                    @workPackage = @workPackage,
                                    @msType = @msType,
                                    @instrumentSettings = 'na',
                                    @wellplateName = NULL,
                                    @wellNumber = NULL,
                                    @internalStandard = 'na',
                                    @comment = 'Automatically created by Dataset entry',
                                    @eusProposalID = @eusProposalID,
                                    @eusUsageType = @eusUsageType,
                                    @eusUsersList = @eusUsersList,
                                    @mode = 'add-auto',
                                    @request = @requestID output,
                                    @message = @message output,
                                    @secSep = @secSep,
                                    @MRMAttachment = '',
                                    @status = 'Completed',
                                    @SkipTransactionRollback = 1,
                                    @AutoPopulateUserListIfBlank = 1,        -- Auto populate @eusUsersList if blank since this is an Auto-Request
                                    @callingUser = @callingUser,
                                    @logDebugMessages = @logDebugMessages
            --
            Set @myError = @result
            --
            If @myError <> 0
            Begin
                If @eusProposalID = '' And @eusUsageType = '' and @eusUsersList = ''
                Begin
                    Set @msg = 'Create AutoReq run request failed: dataset ' + @datasetName + '; EUS Proposal ID, Usage Type, and Users list cannot all be blank ->' + @message
                End
                Else
                Begin
                    Set @msg = 'Create AutoReq run request failed: dataset ' + @datasetName + ' with EUS Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
                End

                Set @logErrors = 0

                RAISERROR (@msg, 11, 24)
            End
        End -- </b3>

        ---------------------------------------------------
        -- If a cart name is specified, update it for the requested run
        ---------------------------------------------------

        If @requestID > 0 And @lcCartName NOT IN ('', 'no update')
        Begin

            If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
                Set @warning = @message

            If @logDebugMessages > 0
            Begin
                Print 'Call update_cart_parameters with @mode="CartName"'
            End

            exec @result = update_cart_parameters
                                'CartName',
                                @requestID,
                                @lcCartName,
                                @message output

            Set @myError = @result

            If @myError <> 0
            Begin
                Set @msg = 'Update LC cart name failed: dataset ' + @datasetName + ' -> ' + @message
                RAISERROR (@msg, 11, 21)
            End
        End

        ---------------------------------------------------
        -- If @cartConfigID is a positive number, update it for the requested run
        ---------------------------------------------------

        If @requestID > 0 And @cartConfigID > 0
        Begin

            If IsNull(@message, '') <> '' And IsNull(@warning, '') = ''
                Set @warning = @message

            If @logDebugMessages > 0
            Begin
                Print 'Call update_cart_parameters with @mode="CartConfigID"'
            End

            Set @newValue = Cast(@cartConfigID As varchar(12))

            exec @result = update_cart_parameters
                                'CartConfigID',
                                @requestID,
                                @newValue,
                                @message output

            Set @myError = @result

            If @myError <> 0
            Begin
                Set @msg = 'Update cart config ID: dataset ' + @datasetName + ' -> ' + @message
                RAISERROR (@msg, 11, 21)
            End
        End

        ---------------------------------------------------
        -- Consume the scheduled run
        ---------------------------------------------------

        Set @datasetID = 0

        SELECT @datasetID = Dataset_ID
        FROM T_Dataset
        WHERE Dataset_Num = @datasetName

        If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
            Set @warning = @message

        If @logDebugMessages > 0
        Begin
            Print 'Call consume_scheduled_run'
        End

        exec @result = consume_scheduled_run @datasetID, @requestID, @message output, @callingUser, @logDebugMessages
        --
        Set @myError = @result
        --
        If @myError <> 0
        Begin
            Set @msg = 'Consume operation failed: dataset ' + @datasetName + ' -> ' + @message
            RAISERROR (@msg, 11, 16)
        End

        If @@trancount > 0
        Begin
            commit transaction @transName
        End
        Else
        Begin
            Set @debugMsg = '@@trancount is 0; this is unexpected'
            exec post_log_entry 'Error', @debugMsg, 'add_update_dataset'
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Call update_cached_dataset_instruments with @datasetId = ' + CAST(@datasetId as varchar(12))
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        -- Update T_Cached_Dataset_Stats
        Exec dbo.update_cached_dataset_instruments @processingMode=0, @datasetId=@datasetID, @infoOnly=0
    End

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Update dataset ' + @datasetName + ' (Dataset ID ' + Cast(@datasetID as varchar(9)) + ')'
            exec post_log_entry 'Debug', @debugMsg, 'add_update_dataset'
        End

        Set @myError = 0

        UPDATE T_Dataset
        SET     DS_Oper_PRN = @operatorUsername,
                DS_comment = @comment,
                DS_type_ID = @datasetTypeID,
                DS_well_num = @wellNumber,
                DS_sec_sep = @secSep,
                DS_folder_name = @folderName,
                Exp_ID = @experimentID,
                DS_rating = @ratingID,
                DS_LC_column_ID = @columnID,
                DS_wellplate_num = @wellplateName,
                DS_internal_standard_ID = @intStdID,
                Capture_Subfolder = @captureSubfolder,
                Cart_Config_ID = @cartConfigID
        WHERE Dataset_ID = @datasetID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @msg = 'Update operation failed: dataset ' + @datasetName
            RAISERROR (@msg, 11, 4)
        End

        -- If @callingUser is defined, call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0 AND @ratingID <> IsNull(@curDSRatingID, -1000)
            Exec alter_event_log_entry_user 8, @datasetID, @ratingID, @callingUser

        -- Lookup the Requested Run info for this dataset
        --
        SELECT @requestID = RR.ID,
               @requestName = RR.RDS_Name,
               @reqRunInstSettings = RR.RDS_instrument_setting,
               @workPackage = RR.RDS_WorkPackage,
               @wellplateName = RR.RDS_Well_Plate_Num,
               @wellNumber = RR.RDS_Well_Num,
               @reqRunComment = RDS_comment,
               @reqRunInternalStandard = RDS_internal_standard,
               @mrmAttachmentID = RDS_MRM_Attachment,
               @reqRunStatus = RDS_Status
        FROM T_Dataset DS
             INNER JOIN T_Requested_Run RR
               ON DS.Dataset_ID = RR.DatasetID
        WHERE DS.Dataset_ID = @datasetID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @requestID = 0

        ---------------------------------------------------
        -- If a cart name is specified, update it for the requested run
        ---------------------------------------------------
        --
        If @lcCartName NOT IN ('', 'no update')
        Begin

            If @requestID <= 0
            Begin
                Set @warningAddon = 'Dataset is not associated with a requested run; cannot update the LC Cart Name'
                Set @warning = dbo.append_to_text(@warning, @warningAddon, 0, '; ', 512)
            End
            Else
            Begin
                Set @warningAddon = ''
                exec @result = update_cart_parameters
                                    'CartName',
                                    @requestID,
                                    @lcCartName,
                                    @warningAddon output

                Set @myError = @result
                --
                If @myError <> 0
                Begin
                    Set @warningAddon = 'Update LC cart name failed: ' + @warningAddon
                    Set @warning = dbo.append_to_text(@warning, @warningAddon, 0, '; ', 512)
                    Set @myError = 0
                End
            End
        End

        ---------------------------------------------------
        -- If @cartConfigID is a positive number, update it for the requested run
        ---------------------------------------------------

        If @requestID > 0 And @cartConfigID > 0
        Begin

            Set @warningAddon = ''

            Set @newValue = Cast(@cartConfigID As varchar(12))

            exec @result = update_cart_parameters
                                'CartConfigID',
                                @requestID,
                                @newValue,
                                @warningAddon output

            Set @myError = @result
            --
            If @myError <> 0
            Begin
                Set @warningAddon = 'Update cart config ID failed: ' + @warningAddon
                Set @warning = dbo.append_to_text(@warning, @warningAddon, 0, '; ', 512)
                Set @myError = 0
            End
        End

        If @requestID > 0 And @eusUsageType <> ''
        Begin -- <b4>
            -- Lookup @batch, @block, and @runOrder

            SELECT @batch = RDS_BatchID,
                   @block = RDS_Block,
                   @runOrder = RDS_Run_Order
            FROM T_Requested_Run
            WHERE ID = @requestID

            Set @batch = IsNull(@batch, 0)
            Set @block = IsNull(@block, 0)
            Set @runOrder = IsNull(@runOrder, 0)

            EXEC @result = dbo.add_update_requested_run
                                    @requestName = @requestName,
                                    @experimentName = @experimentName,
                                    @requesterUsername = @operatorUsername,
                                    @instrumentName = @instrumentName,
                                    @workPackage = @workPackage,
                                    @msType = @msType,
                                    @instrumentSettings = @reqRunInstSettings,
                                    @wellplateName = @wellplateName,
                                    @wellNumber = @wellNumber,
                                    @internalStandard = @reqRunInternalStandard,
                                    @comment = @reqRunComment,
                                    @batch = @batch,
                                    @block = @block,
                                    @runOrder = @runOrder,
                                    @eusProposalID = @eusProposalID,
                                    @eusUsageType = @eusUsageType,
                                    @eusUsersList = @eusUsersList,
                                    @mode = 'update',
                                    @request = @requestID output,
                                    @message = @message output,
                                    @secSep = @secSep,
                                    @MRMAttachment = @mrmAttachmentID,
                                    @status = @reqRunStatus,
                                    @SkipTransactionRollback = 1,
                                    @AutoPopulateUserListIfBlank = 1,        -- Auto populate @eusUsersList if blank since this is an Auto-Request
                                    @callingUser = @callingUser,
                                    @logDebugMessages = @logDebugMessages

            --
            Set @myError = @result
            --
            If @myError <> 0
            Begin
                Set @msg = 'Requested run update error using Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
                RAISERROR (@msg, 11, 24)
            End
        End -- </b4>

        ---------------------------------------------------
        -- If rating changed from -5, -6, or -7 to 5, check if any jobs exist for this dataset
        -- If no jobs are found, call schedule_predefined_analysis_jobs for this dataset
        -- Skip jobs with AJ_DatasetUnreviewed=1 when looking for existing jobs (these jobs were created before the dataset was dispositioned)
        ---------------------------------------------------
        --
        If @ratingID >= 2 and IsNull(@curDSRatingID, -1000) IN (-5, -6, -7)
        Begin
            If Not Exists (SELECT * FROM T_Analysis_Job WHERE AJ_datasetID = @datasetID AND AJ_DatasetUnreviewed = 0 )
            Begin
                Exec schedule_predefined_analysis_jobs @datasetName, @callingUser=@callingUser

                -- If @callingUser is defined, call alter_event_log_entry_user to alter the Entered_By field
                -- in T_Event_Log for any newly created jobs for this dataset
                If Len(@callingUser) > 0
                Begin
                    Declare @jobStateID int
                    Set @jobStateID = 1

                    CREATE TABLE #TmpIDUpdateList (
                        TargetID int NOT NULL
                    )

                    INSERT INTO #TmpIDUpdateList (TargetID)
                    SELECT AJ_JobID
                    FROM T_Analysis_Job
                    WHERE AJ_datasetID = @datasetID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    Exec alter_event_log_entry_user_multi_id 5, @jobStateID, @callingUser
                End

            End
        End

        -- Update T_Cached_Dataset_Stats
        Exec dbo.update_cached_dataset_instruments @processingMode=0, @datasetId=@datasetID, @infoOnly=0
    End

    -- Update @message if @warning is not empty
    If IsNull(@warning, '') <> ''
    Begin
        Declare @warningWithPrefix varchar(512)

        If @warning like 'Warning:'
            Set @warningWithPrefix = @warning
        Else
            Set @warningWithPrefix = 'Warning: ' + @warning

        If IsNull(@message, '') = ''
            Set @message = @warningWithPrefix
        Else
        Begin
            If @message = @warning
                Set @message = @warningWithPrefix
            Else
                Set @message = @warningWithPrefix + '; ' + @message
        End
    End

    End TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0 And Not @message Like '%validate_eus_usage%'
        Begin
            Declare @logMessage varchar(1024) = @message + '; Dataset ' + @datasetName
            exec post_log_entry 'Error', @logMessage, 'add_update_dataset'
        End

    End CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_dataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_dataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_dataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_dataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_dataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_dataset] TO [PNL\D3M578] AS [dbo]
GO
