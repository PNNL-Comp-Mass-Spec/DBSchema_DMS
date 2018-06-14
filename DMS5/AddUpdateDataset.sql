/****** Object:  StoredProcedure [dbo].[AddUpdateDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateDataset]
/****************************************************
**
**  Desc:   Adds new dataset entry to DMS database
**
**          This is called from the Dataset Entry page (http://dms2.pnl.gov/dataset/create) with @mode = 'add_trigger'
**          It is also called from the Spreadsheet Loader with @mode as 'add, 'check_update', or 'check_add'
**
**  Return values: 0: success, otherwise, error code
** 
**  Auth:   grk
**  Date:   02/13/2003
**          01/10/2002
**          12/10/2003 grk - added wellplate, internal standards, and LC column stuff
**          01/11/2005 grk - added bad dataset stuff
**          02/23/2006 grk - added LC cart tracking stuff and EUS stuff
**          01/12/2007 grk - added verification mode
**          02/16/2007 grk - added validation of dataset name (Ticket #390)
**          04/30/2007 grk - added better name validation (Ticket #450)
**          07/26/2007 mem - Now checking dataset type (@msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**          09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          10/08/2007 jds - Added support for new mode 'add_trigger'.  Validation was taken from other stored procs from the 'add' mode
**          12/07/2007 mem - Now disallowing updates for datasets with a rating of -10 = Unreviewed (use UpdateDatasetDispositions instead)
**          01/08/2008 mem - Added check for @eusProposalID, @eusUsageType, or @eusUsersList being blank or 'no update' when @mode = 'add' and @requestID is 0
**          02/13/2008 mem - Now sending @datasetNum to function ValidateChars and checking for @badCh = '[space]' (Ticket #602)
**          02/15/2008 mem - Increased size of @folderName to varchar(128) (Ticket #645)
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**          04/09/2008 mem - Added call to AlterEventLogEntryUser to handle dataset rating entries (event log target type 8)
**          05/23/2008 mem - Now calling SchedulePredefinedAnalyses if the dataset rating is changed from -5 to 5 and no jobs exist yet for this dataset (Ticket #675)
**          04/08/2009 jds - Added support for the additional parameters @secSep and @MRMAttachment to the AddUpdateRequestedRun stored procedure (Ticket #727)
**          09/16/2009 mem - Now checking dataset type (@msType) against the Instrument_Allowed_Dataset_Type table (Ticket #748)
**          01/14/2010 grk - assign storage path on creation of dataset
**          02/28/2010 grk - added add-auto mode for requested run
**          03/02/2010 grk - added status field to requested run
**          05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @operPRN contains a person's real name rather than their username
**          07/27/2010 grk - try-catch for error handling
**          08/26/2010 mem - Now passing @callingUser to SchedulePredefinedAnalyses
**          08/27/2010 mem - Now calling ValidateInstrumentGroupAndDatasetType to validate the instrument type for the selected instrument's instrument group
**          09/01/2010 mem - Now passing @SkipTransactionRollback to AddUpdateRequestedRun
**          09/02/2010 mem - Now allowing @msType to be blank or invalid when @mode = 'add'; The assumption is that the dataset type will be auto-updated if needed based on the results from the DatasetQuality tool, which runs during dataset capture
**                         - Expanded @msType to varchar(50)
**          09/09/2010 mem - Now passing @AutoPopulateUserListIfBlank to AddUpdateRequestedRun
**                         - Relaxed EUS validation to ignore @eusProposalID, @eusUsageType, and @eusUsersList if @requestID is non-zero
**                         - Auto-updating RequestID, experiment, and EUS information for "Blank" datasets
**          03/10/2011 mem - Tweaked text added to dataset comment when dataset type is auto-updated or auto-defined
**          05/11/2011 mem - Now calling GetInstrumentStoragePathForNewDatasets
**          05/12/2011 mem - Now passing @RefDate and @AutoSwitchActiveStorage to GetInstrumentStoragePathForNewDatasets
**          05/24/2011 mem - Now checking for change of rating from -5, -6, or -7 to 5
**                         - Now ignoring AJ_DatasetUnreviewed jobs when determining whether or not to call SchedulePredefinedAnalyses
**          12/12/2011 mem - Updated call to ValidateEUSUsage to treat @eusUsageType as an input/output parameter
**          12/14/2011 mem - Now passing @callingUser to AddUpdateRequestedRun and ConsumeScheduledRun
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**          01/11/2012 mem - Added parameter @AggregationJobDataset
**          02/29/2012 mem - Now auto-updating the @eus parameters if null
**                         - Now raising an error if other key parameters are null/empty
**          09/12/2012 mem - Now auto-changing HMS-HMSn to IMS-HMS-HMSn for IMS datasets
**                         - Now requiring that the dataset name be 90 characters or less (longer names can lead to "path-too-long" errors; Windows has a 254 character path limit)
**          11/21/2012 mem - Now requiring that the dataset name be at least 6 characters in length
**          01/22/2013 mem - Now updating the dataset comment if the default dataset type is invalid for the instrument group
**          04/02/2013 mem - Now updating @LCCartName (if not blank) when updating an existing dataset
**          05/08/2013 mem - Now setting @wellplateNum and @wellNum to Null if they are blank or 'na'
**          02/27/2014 mem - Now skipping check for name ending in Raw or Wiff if @AggregationJobDataset is non-zero
**          05/07/2015 mem - Now showing URL http://dms2.pnl.gov/dataset_disposition/search if the user tries to change the rating from Unreleased to something else (previously showed http://dms2.pnl.gov/dataset_disposition/report)
**          05/29/2015 mem - Added parameter @captureSubfolder (only used if @mode is 'add' or 'bad')
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/19/2015 mem - Now auto-fixing QC_Shew names, e.g. QC_Shew_15-01 to QC_Shew_15_01
**          10/01/2015 mem - Add support for (ignore) for @eusProposalID, @eusUsageType, and @eusUsersList
**          10/14/2015 mem - Remove double quotes from error messages
**          01/29/2016 mem - Now calling GetWPforEUSProposal to get the best work package for the given EUS Proposal
**          02/23/2016 mem - Add Set XACT_ABORT on
**          05/23/2016 mem - Disallow certain dataset names
**          06/10/2016 mem - Try to auto-associate new datasets with an active requested run (only associate if only one active requested run matches the dataset name)
**          06/21/2016 mem - Add additional debug messages
**          08/25/2016 mem - Do not update the dataset comment if the dataset type is changed from 'GC-MS' to 'EI-HMS'
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          11/21/2016 mem - Pass @logDebugMessages to ConsumeScheduledRun
**          11/23/2016 mem - Include the dataset name when calling PostLogEntry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          01/09/2017 mem - Pass @logDebugMessages to AddUpdateRequestedRun
**          02/23/2017 mem - Add parameter @lcCartConfig
**          03/06/2017 mem - Decreased maximum dataset name length from 90 characters to 80 characters
**          04/28/2017 mem - Disable logging certain messages to T_Log_Entries
**          06/13/2017 mem - Rename @operPRN to @requestorPRN when calling AddUpdateRequestedRun
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/29/2017 mem - Allow updating EUS info for existing datasets (calls AddUpdateRequestedRun)
**          06/12/2018 mem - Send @maxLength to AppendToText
**                         - Expand @warning to varchar(512)
**    
*****************************************************/
(
    @datasetNum varchar(128),                   -- Dataset name
    @experimentNum varchar(64),
    @operPRN varchar(64),
    @instrumentName varchar(64),
    @msType varchar(50),                        -- Dataset Type
    @LCColumnNum varchar(64),
    @wellplateNum varchar(64) = 'na',
    @wellNum varchar(64) = 'na',
    @secSep varchar(64) = 'na',
    @internalStandards varchar(64) = 'none',
    @comment varchar(512) = 'na',
    @rating varchar(32) = 'Unknown',
    @LCCartName varchar(128),
    @eusProposalID varchar(10) = 'na',
    @eusUsageType varchar(50),
    @eusUsersList varchar(1024) = '',
    @requestID int = 0,                         -- Only valid if @mode is 'add', 'check_add', or 'add_trigger'; ignored if @mode is 'update' or 'check_update'
    @mode varchar(12) = 'add',                  -- Can be 'add', 'update', 'bad', 'check_update', 'check_add', 'add_trigger'
    @message varchar(512) output,
    @callingUser varchar(128) = '',
    @AggregationJobDataset tinyint = 0,      -- Set to 1 when creating an in-silico dataset to associate with an aggregation job
    @captureSubfolder varchar(255) = '',     -- Only used when @mode is 'add' or 'bad'
    @lcCartConfig varchar(128) = '',
    @logDebugMessages tinyint = 0
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @msg varchar(256)
    Declare @folderName varchar(128)
    Declare @AddingDataset tinyint = 0
    
    Declare @result int
    Declare @warning varchar(512)
    Declare @warningAddon varchar(128)
    Declare @ExperimentCheck varchar(128)
    Declare @debugMsg varchar(512)
    Declare @logErrors tinyint = 0

    Declare @workPackage varchar(12) = 'none'            
    Declare @reqName varchar(128)
    Declare @reqRunInstSettings varchar(512)
    Declare @reqRunComment varchar(1024)
    Declare @reqRunInternalStandard varchar(50)
    Declare @mrmAttachmentID int
    Declare @reqRunStatus varchar(24)
            
    Set @message = ''
    Set @warning = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'AddUpdateDataset', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    BEGIN TRY 

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @mode = LTrim(RTrim(IsNull(@mode, '')))
    Set @secSep = LTrim(RTrim(IsNull(@secSep, '')))
    Set @LCColumnNum = LTrim(RTrim(IsNull(@LCColumnNum, '')))
    Set @datasetNum = LTrim(RTrim(IsNull(@datasetNum, '')))

    Set @experimentNum = LTrim(RTrim(IsNull(@experimentNum, '')))
    Set @operPRN = LTrim(RTrim(IsNull(@operPRN, '')))
    Set @instrumentName = LTrim(RTrim(IsNull(@instrumentName, '')))
    Set @rating = LTrim(RTrim(IsNull(@rating, '')))

    Set @internalStandards = IsNull(@internalStandards, '')
    If @internalStandards = '' Or @internalStandards = 'na'
        Set @internalStandards = 'none'
    
    If IsNull(@mode, '') = ''
    Begin
        Set @msg = '@mode was blank'
        RAISERROR (@msg, 11, 17)
    End
        
    If IsNull(@secSep, '') = ''
    Begin
        Set @msg = 'Separation type was blank'
        RAISERROR (@msg, 11, 17)
    End
    --
    If IsNull(@LCColumnNum, '') = ''
    Begin
        Set @msg = 'LC Column name was blank'
        RAISERROR (@msg, 11, 16)
    End
    --
    If IsNull(@datasetNum, '') = ''
    Begin
        Set @msg = 'Dataset name was blank'
        RAISERROR (@msg, 11, 10)
    End
    --
    Set @folderName = @datasetNum
    --
    If IsNull(@experimentNum, '') = ''
    Begin
        Set @msg = 'Experiment name was blank'
        RAISERROR (@msg, 11, 11)
    End
    --
    If IsNull(@folderName, '') = ''
    Begin
        Set @msg = 'Folder name was blank'
        RAISERROR (@msg, 11, 12)
    End
    --
    If IsNull(@operPRN, '') = ''
    Begin
        Set @msg = 'Operator payroll number/HID was blank'
        RAISERROR (@msg, 11, 13)
    End
    --
    If IsNull(@instrumentName, '') = ''
    Begin
        Set @msg = 'Instrument name was blank'
        RAISERROR (@msg, 11, 14)
    End
    --
    Set @msType = IsNull(@msType, '')
    
    -- Allow @msType to be blank If @mode is Add or Bad but not if check_add or add_trigger or update
    If @msType = '' And NOT @mode In ('Add', 'Bad')
    Begin
        Set @msg = 'Dataset type was blank'
        RAISERROR (@msg, 11, 15)
    End
    --
    If IsNull(@LCCartName, '') = ''
    Begin
        Set @msg = 'LC Cart name was blank'
        RAISERROR (@msg, 11, 15)
    End

    -- Assure that @comment is not null and assure that it doesn't have &quot;
    Set @comment = IsNull(@comment, '')
    If @comment LIKE '%&quot;%'
        Set @comment = Replace(@comment, '&quot;', '"')
    
    -- 
    If IsNull(@rating, '') = ''
    Begin
        Set @msg = 'Rating was blank'
        RAISERROR (@msg, 11, 15)
    End
    
    If IsNull(@wellplateNum, '') IN ('', 'na')
        Set @wellplateNum = NULL
    
    If IsNull(@wellNum, '') IN ('', 'na')
        Set @wellNum = NULL

    Set @eusProposalID = IsNull(@eusProposalID, '')
    Set @eusUsageType = IsNull(@eusUsageType, '')
    Set @eusUsersList = IsNull(@eusUsersList, '')
    
    Set @requestID = IsNull(@requestID, 0)
    Set @AggregationJobDataset = IsNull(@AggregationJobDataset, 0)    
    Set @captureSubfolder = LTrim(RTrim(IsNull(@captureSubfolder, '')))
    
    Set @lcCartConfig = LTrim(RTrim(IsNull(@lcCartConfig, '')))
    If @lcCartConfig = ''
        Set @lcCartConfig = null
        
    Set @logDebugMessages = IsNull(@logDebugMessages, 0)
    
    ---------------------------------------------------
    -- Determine if we are adding or check_adding a dataset
    ---------------------------------------------------
    --
    If @mode IN ('add', 'check_add', 'add_trigger')
        Set @AddingDataset = 1
    Else
        Set @AddingDataset = 0

    If @logDebugMessages > 0
    Begin
        Set @debugMsg = '@mode=' + @mode + ', @dataset=' + @datasetNum + ', @requestID=' + Cast(@requestID    as varchar(9)) + ', @callingUser=' + @callingUser        
        exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateDataset'
    End
    
    ---------------------------------------------------
    -- Validate dataset name
    ---------------------------------------------------
    --
    Declare @badCh varchar(128)
    Set @badCh =  dbo.ValidateChars(@datasetNum, '')
    If @badCh <> ''
    Begin
        If @badCh = '[space]'
            Set @msg = 'Dataset name may not contain spaces'
        Else
        Begin
            If Len(@badCh) = 1
                Set @msg = 'Dataset name may not contain the character ' + @badCh
            else
                Set @msg = 'Dataset name may not contain the characters ' + @badCh
        End

        RAISERROR (@msg, 11, 1)
    End

    If @AggregationJobDataset = 0 And (@datasetNum Like '%raw' Or @datasetNum Like '%wiff') 
    Begin
        Set @msg = 'Dataset name may not end in raw or wiff'
        RAISERROR (@msg, 11, 2)
    End

    If Len(@datasetNum) > 80 And Not @mode in ('update', 'check_update')
    Begin
        Set @msg = 'Dataset name cannot be over 80 characters in length; currently ' + Convert(varchar(12), Len(@datasetNum)) + ' characters'
        RAISERROR (@msg, 11, 3)
    End
    
    If Len(@datasetNum) < 6
    Begin
        Set @msg = 'Dataset name must be at least 6 characters in length; currently ' + Convert(varchar(12), Len(@datasetNum)) + ' characters'
        RAISERROR (@msg, 11, 3)
    End

    If @datasetNum in (
       'Archive', 'Dispositioned', 'Processed', 'Reprocessed', 'Not-Dispositioned', 
       'High-pH', 'NotDispositioned', 'Yufeng', 'Uploaded', 'Sequence', 'Sequences', 
       'Peptide', 'BadData')
    Begin
        Set @msg = 'Dataset name is too generic; be more specific'
        RAISERROR (@msg, 11, 3)
    End    
        
    ---------------------------------------------------
    -- Resolve id for rating
    ---------------------------------------------------

    Declare @ratingID int

    If @mode = 'bad'
    Begin
        Set @ratingID = -1 -- "No Data"
        Set @mode = 'add'
        Set @AddingDataset = 1
    End
    else
    Begin
        execute @ratingID = GetDatasetRatingID @rating
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
    WHERE (Dataset_Num = @datasetNum)

    Set @datasetID = IsNull(@datasetID, 0)
    
    If @datasetID = 0 
    Begin
        -- cannot update a non-existent entry
        --
        If @mode IN ('update', 'check_update')
        Begin
            Set @msg = 'Cannot update: Dataset ' + @datasetNum + ' is not in database'
            RAISERROR (@msg, 11, 4)
        End
    End
    else
    Begin
        -- cannot create an entry that already exists
        --
        If @AddingDataset = 1
        Begin
            Set @msg = 'Cannot add dataset ' + @datasetNum + ' since already in database'
            RAISERROR (@msg, 11, 5)
        End

        -- do not allow a rating change from 'Unreviewed' to any other rating within this procedure
        --
        If @curDSRatingID = -10 And @rating <> 'Unreviewed'
        Begin
            Set @msg = 'Cannot change dataset rating from Unreviewed with this mechanism; use the Dataset Disposition process instead ("http://dms2.pnl.gov/dataset_disposition/search" or SP UpdateDatasetDispositions)'
            RAISERROR (@msg, 11, 6)
        End        
    End

    ---------------------------------------------------
    -- Resolve ID for LC Column
    ---------------------------------------------------
    
    Declare @columnID int = -1
    --
    SELECT @columnID = ID
    FROM T_LC_Column
    WHERE (SC_Column_Number = @LCColumnNum)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error trying to look up column ID'
        RAISERROR (@msg, 11, 93)
    End
    If @columnID = -1
    Begin
        Set @msg = 'Unknown LC column name: ' + @LCColumnNum
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
        WHERE (Cart_Config_Name = @lcCartConfig)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
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
    --
    SELECT @sepID = SS_ID
    FROM T_Secondary_Sep
    WHERE SS_name = @secSep    
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
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
    --
    SELECT @intStdID = Internal_Std_Mix_ID
    FROM [T_Internal_Standards]
    WHERE [Name] = @internalStandards    
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
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
    -- If Dataset starts with "Blank", then make sure @experimentNum contains "Blank"
    ---------------------------------------------------
    
    If @datasetNum Like 'Blank%' And @AddingDataset = 1
    Begin
        If NOT @ExperimentNum LIKE '%blank%'
            Set @ExperimentNum = 'blank'        
    End
    
    ---------------------------------------------------
    -- Resolve experiment ID
    ---------------------------------------------------

    Declare @experimentID int
    execute @experimentID = GetExperimentID @experimentNum

    If @experimentID = 0 And @experimentNum LIKE 'QC_Shew_[0-9][0-9]_[0-9][0-9]' And @experimentNum LIKE '%-%'
    Begin
        Declare @newExperiment varchar(64) = Replace(@experimentNum, '-', '_')
        execute @experimentID = GetExperimentID @newExperiment
        
        If @experimentID > 0
        Begin
            SELECT @experimentNum = Experiment_Num
            FROM T_Experiments
            WHERE (Exp_ID = @experimentID)
        End
    End

    If @experimentID = 0
    Begin
        Set @msg = 'Could not find entry in database for experiment ' + @experimentNum
        RAISERROR (@msg, 11, 12)
    End


    ---------------------------------------------------
    -- Resolve instrument ID
    ---------------------------------------------------

    Declare @instrumentID int
    Declare @InstrumentGroup varchar(64) = ''
    Declare @DefaultDatasetTypeID int
    Declare @msTypeOld varchar(50)
    
    execute @instrumentID = GetinstrumentID @instrumentName
    If @instrumentID = 0
    Begin
        Set @msg = 'Could not find entry in database for instrument ' + @instrumentName
        RAISERROR (@msg, 11, 14)
    End

    ---------------------------------------------------
    -- Lookup the Instrument Group
    ---------------------------------------------------
        
    SELECT @InstrumentGroup = IN_Group
    FROM T_Instrument_Name
    WHERE Instrument_ID = @instrumentID

    If @InstrumentGroup = ''
    Begin
        Set @msg = 'Instrument group not defined for instrument ' + @instrumentName
        RAISERROR (@msg, 11, 14)
    End

    ---------------------------------------------------
    -- Lookup the default dataset type ID (could be null)
    ---------------------------------------------------
        
    SELECT @DefaultDatasetTypeID = Default_Dataset_Type
    FROM T_Instrument_Group
    WHERE IN_Group = @InstrumentGroup

    
    ---------------------------------------------------
    -- Resolve dataset type ID
    ---------------------------------------------------

    Declare @datasetTypeID int
    execute @datasetTypeID = GetDatasetTypeID @msType
    
    If @datasetTypeID = 0
    Begin
        -- Could not resolve @msType to a dataset type
        -- If @mode is Add, we will auto-update @msType to the default
        --
        If @AddingDataset = 1 And IsNull(@DefaultDatasetTypeID, 0) > 0
        Begin
            -- Use the default dataset type
            Set @datasetTypeID = @DefaultDatasetTypeID
            
            Set @msTypeOld = @msType
            
            -- Update @msType            
            SELECT @msType = DST_name
            FROM T_DatasetTypeName
            WHERE (DST_Type_ID = @datasetTypeID)

            If @comment = 'na'
                Set @comment = ''
            
            If @msTypeOld <> ''
            Begin
                -- Update the comment since we changed the dataset type from @msTypeOld to @msType
                If @comment <> ''
                    Set @comment = @comment + '; '
                
                Set @comment = @comment + 'Auto-switched invalid dataset type from ' + @msTypeOld + ' to default: ' + @msType
            End
            Else
            Begin
                -- @msTypeOld was blank
                -- Update the comment only if this is not an IMS dataset
                If Not @instrumentName Like 'IMS%'
                Begin
                    If @comment <> ''
                        Set @comment = @comment + '; '
                    
                    Set @comment = @comment + 'Auto-defined dataset type using default: ' + @msType
                End
            End                        
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
        
    exec @result = ValidateInstrumentGroupAndDatasetType @msType, @InstrumentGroup, @datasetTypeID output, @msg output

    If @result <> 0 And @AddingDataset = 1 And IsNull(@DefaultDatasetTypeID, 0) > 0
    Begin
        -- Dataset type is not valid for this instrument group
        -- However, @mode is Add, so we will auto-update @msType
        --
        If @comment = 'na'
            Set @comment = ''
        
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
            execute @datasetTypeID = GetDatasetTypeID @msType
            
            Set @comment = dbo.AppendToText(@comment, 'Auto-switched dataset type from HMS-HMSn to ' + @msType, 0, '; ', 512)
        End
        Else
        Begin
            -- Not an IMS dataset; change @datasetTypeID to zero so that the default dataset type is used
            Set @datasetTypeID = 0
        End
        
        If @datasetTypeID = 0
        Begin
            Set @datasetTypeID = @DefaultDatasetTypeID    

            Set @msTypeOld = @msType
            
            -- Update @msType            
            SELECT @msType = DST_name
            FROM T_DatasetTypeName
            WHERE (DST_Type_ID = @datasetTypeID)
            
            If @msTypeOld = 'GC-MS' And @msType = 'EI-HMS'
            Begin
                -- This happens for most datasets from instrument GCQE01; do not update the comment
                Set @result = 0
            End
            Else
            Begin
                Set @comment = dbo.AppendToText(@comment, 'Auto-switched invalid dataset type from ' + @msTypeOld + ' to default: ' + @msType, 0, '; ', 512)
            End
        End
        
        -- Validate the new dataset type name (in case the default dataset type is invalid for this instrument group, which would indicate invalid data in table T_Instrument_Group)
        exec @result = ValidateInstrumentGroupAndDatasetType @msType, @InstrumentGroup, @datasetTypeID output, @msg output
        
        If @result <> 0
        Begin
            Set @comment = dbo.AppendToText(@comment, 'Error: Default dataset type defined in T_Instrument_Group is invalid', 0, ' - ', 512)
        End
    End
    
    If @result <> 0
    Begin
        -- @msg should already contain the details of the error
        If IsNull(@msg, '') = ''
            Set @msg = 'ValidateInstrumentGroupAndDatasetType returned non-zero result code: ' + Convert(varchar(12), @result)
        
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
    -- Resolve user ID for operator PRN
    ---------------------------------------------------

    Declare @userID int
    execute @userID = GetUserID @operPRN
    If @userID = 0
    Begin
        -- Could not find entry in database for PRN @operPRN
        -- Try to auto-resolve the name

        Declare @MatchCount int
        Declare @NewPRN varchar(64)

        exec AutoResolveNameToPRN @operPRN, @MatchCount output, @NewPRN output, @userID output

        If @MatchCount = 1
        Begin
            -- Single match found; update @operPRN
            Set @operPRN = @NewPRN
        End
        Else
        Begin
            Set @msg = 'Could not find entry in database for operator PRN ' + @operPRN
            RAISERROR (@msg, 11, 19)
        End
    End

    ---------------------------------------------------
    -- Verify acceptable combination of EUS fields
    ---------------------------------------------------
    
    If @requestID <> 0 AND @AddingDataset = 1
    Begin       
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
        End
                
        ---------------------------------------------------
        -- If the dataset starts with "blank" but @requestID is non-zero, then this is likely incorrect
        -- Auto-update things if this is the case
        ---------------------------------------------------
        If @datasetNum Like 'Blank%'
        Begin
            -- See If the experiment matches for this request; if it doesn't, change @requestID to 0
            Set @ExperimentCheck = ''
            
            SELECT @ExperimentCheck = E.Experiment_Num
            FROM T_Experiments E INNER JOIN
                T_Requested_Run RR ON E.Exp_ID = RR.Exp_ID
            WHERE (RR.ID = @requestID)
            
            If @ExperimentCheck <> @ExperimentNum
                Set @RequestID = 0
        End
    End

    ---------------------------------------------------
    -- If the dataset starts with "blank" and @requestID is zero, perform some additional checks
    ---------------------------------------------------
    --
    If @requestID = 0 AND @AddingDataset = 1
    Begin
        -- If the EUS information is not defined, auto-define the EUS usage type as 'MAINTENANCE'
        If @datasetNum Like 'Blank%' And @eusProposalID = '' And @eusUsageType = ''
            Set @eusUsageType = 'MAINTENANCE'

    End

    ---------------------------------------------------
    -- Possibly look for an active requested run that we can auto-associate with this dataset
    ---------------------------------------------------
    --
    If @requestID = 0 AND @AddingDataset = 1
    Begin
        Declare @requestInstGroup varchar(128)
        
        EXEC FindActiveRequestedRunForDataset @datasetNum, @experimentID, @requestID out, @requestInstGroup OUT, @showDebugMessages=0
        
        If @requestID > 0
        Begin
            -- Match found; check for an instrument group mismatch
            If @requestInstGroup <> @InstrumentGroup
            Begin
                Set @warning = dbo.AppendToText(@warning, 
                    'Instrument group for requested run (' + @requestInstGroup + ') ' + 
                    'does not match instrument group for ' + @instrumentName + ' (' + @InstrumentGroup + ')', 0, '; ', 512)
            End
            
        End
    End
    
    -- Validation checks are complete; now enable @logErrors    
    Set @logErrors = 1
    
    ---------------------------------------------------
    -- action for add trigger mode
    ---------------------------------------------------
    
    If @mode = 'add_trigger'
    Begin -- <AddTrigger>

        If @requestID <> 0
        Begin
            --**Check code taken from ConsumeScheduledRun stored procedure**
            ---------------------------------------------------
            -- Validate that experiments match
            ---------------------------------------------------
        
            -- get experiment ID from dataset
            -- this was already done above

            -- get experiment ID from scheduled run
            --
            Declare @reqExperimentID int
            Set @reqExperimentID = 0
            --
            SELECT @reqExperimentID = Exp_ID
            FROM T_Requested_Run
            WHERE ID = @requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Error trying to look up experiment for request'
                RAISERROR (@message, 11, 86)
            End
        
            -- validate that experiments match
            --
            If @experimentID <> @reqExperimentID
            Begin
                Set @message = 'Experiment for dataset (' + @experimentNum + ') does not match with the requested run''s experiment (Request ' + Convert(varchar(12), @requestID) + ')'
                RAISERROR (@message, 11, 72)
            End
        End

        --**Check code taken from UpdateCartParameters stored procedure**
        ---------------------------------------------------
        -- Resolve ID for LC Cart and update requested run table
        ---------------------------------------------------

        Declare @cartID int = 0
        --
        SELECT @cartID = ID
        FROM T_LC_Cart
        WHERE (Cart_Name = @LCCartName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Error trying to look up cart ID'
            RAISERROR (@msg, 11, 33)
        End
        else 
        If @cartID = 0
        Begin
            Set @msg = 'Unknown LC Cart name: ' + @LCCartName
            RAISERROR (@msg, 11, 35)
        End

        If @requestID = 0
        Begin -- <b1>
        
            -- RequestID not specified
            -- Try to determine EUS information using Experiment name
            
            --**Check code taken from AddUpdateRequestedRun stored procedure**
            
            ---------------------------------------------------
            -- Lookup EUS field (only effective for experiments that have associated sample prep requests)
            -- This will update the data in @eusUsageType, @eusProposalID, or @eusUsersList if it is "(lookup)"
            ---------------------------------------------------
            exec @myError = LookupEUSFromExperimentSamplePrep    
                            @experimentNum,
                            @eusUsageType output,
                            @eusProposalID output,
                            @eusUsersList output,
                            @msg output
                            
            If @myError <> 0
                RAISERROR ('LookupEUSFromExperimentSamplePrep: %s', 11, 1, @msg)

            ---------------------------------------------------
            -- validate EUS type, proposal, and user list
            ---------------------------------------------------
            Declare @eusUsageTypeID int
            exec @myError = ValidateEUSUsage
                            @eusUsageType output,
                            @eusProposalID output,
                            @eusUsersList output,
                            @eusUsageTypeID output,
                            @msg output,
                            @AutoPopulateUserListIfBlank = 0
                            
            If @myError <> 0
                RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)
            
            If IsNull(@msg, '') <> ''
                Set @message = @msg
                
        End -- </b1>
        else
        Begin -- <b2>
            
            ---------------------------------------------------
            -- verify that request ID is correct
            ---------------------------------------------------
            
            If NOT EXISTS (SELECT * FROM T_Requested_Run WHERE ID = @requestID)
            Begin
                Set @msg = 'Request ID not found'
                RAISERROR (@msg, 11, 52)
            End

        End -- </b2>

        Declare @DSCreatorPRN varchar(256) = suser_sname()

        Declare @rslt int
        Declare @Run_Start varchar(10) = ''
        Declare @Run_Finish varchar(10) = ''

        If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
            Set @warning = @message

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Create trigger for dataset ' + @datasetNum + ', instrument ' + @instrumentName + ', request ' + Cast(@requestID as varchar(9))
            exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateDataset'
        End
            
        exec @rslt = CreateXmlDatasetTriggerFile
            @datasetNum,
            @experimentNum,
            @instrumentName,
            @secSep,
            @LCCartName,
            @LCColumnNum,
            @wellplateNum,
            @wellNum,
            @msType,
            @operPRN,
            @DSCreatorPRN,
            @comment,
            @rating,
            @requestID,
            @eusUsageType,
            @eusProposalID,
            @eusUsersList,
            @Run_Start,
            @Run_Finish,
            @captureSubfolder,
            @lcCartConfig,
            @message output

        If @rslt > 0 
        Begin
            -- CreateXmlDatasetTriggerFile should have already logged critical errors to T_Log_Entries
            -- No need for this procedure to log the message again
            Set @logErrors = 0
            Set @msg = 'There was an error while creating the XML Trigger file: ' + @message
            RAISERROR (@msg, 11, 55)
        End
    End -- </AddTrigger>

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    
    If @mode = 'add' 
    Begin -- <AddMode>
    
        ---------------------------------------------------
        -- Lookup storage path ID
        ---------------------------------------------------
        --
        Declare @storagePathID int = 0
        Declare @RefDate datetime = GetDate()
        --
        Exec @storagePathID = GetInstrumentStoragePathForNewDatasets @instrumentID, @RefDate, @AutoSwitchActiveStorage=1, @infoOnly=0
        --
        If @storagePathID = 0
        Begin
            Set @storagePathID = 2 -- index of "none" in T_Storage_Path
            Set @msg = 'Valid storage path could not be found'
            RAISERROR (@msg, 11, 43)
        End

        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Add dataset ' + @datasetNum + ', instrument ID ' + Cast(@instrumentID as varchar(9)) + ', storage path ID ' + Cast(@storagePathID as varchar(9))
            exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateDataset'
        End
        
        -- Start transaction
        --
        Declare @transName varchar(32)
        Set @transName = 'AddNewDataset'

        Begin transaction @transName

        If IsNull(@AggregationJobDataset, 0) = 1
            Set @newDSStateID = 3
        Else
            Set @newDSStateID = 1
        
        -- insert values into a new row
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
            @datasetNum,
            @operPRN,
            @comment,
            @RefDate,
            @instrumentID,
            @datasetTypeID,
            @wellNum,
            @secSep,
            @newDSStateID,
            @folderName,
            @storagePathID,
            @experimentID,
            @ratingID,
            @columnID,
            @wellplateNum,
            @intStdID,
            @captureSubfolder,
            @cartConfigID
        ) 
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 or @myRowCount <> 1
        Begin
            Set @msg = 'Insert operation failed for dataset ' + @datasetNum
            RAISERROR (@msg, 11, 7)
        End
        
        -- Get the ID of newly created dataset
        Set @datasetID = SCOPE_IDENTITY()        

        -- As a precaution, query T_Dataset using Dataset name to make sure we have the correct Dataset_ID
        Declare @DatasetIDConfirm int = 0
        
        SELECT @DatasetIDConfirm = Dataset_ID
        FROM T_Dataset
        WHERE Dataset_Num = @datasetNum
        
        If @datasetID <> IsNull(@DatasetIDConfirm, @datasetID)
        Begin
            Set @DebugMsg = 'Warning: Inconsistent identity values when adding dataset ' + @datasetnum + ': Found ID ' +
                            Cast(@DatasetIDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' + 
                Cast(@datasetID as varchar(12))
                            
            exec PostLogEntry 'Error', @DebugMsg, 'AddUpdateDataset'
            
            Set @datasetID = @DatasetIDConfirm
        End
        
        -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec AlterEventLogEntryUser 4, @datasetID, @newDSStateID, @callingUser
            
            Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser
        End

    
        ---------------------------------------------------
        -- If scheduled run is not specified, create one
        ---------------------------------------------------

        If @requestID = 0
        Begin -- <b3>
        
            If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
                Set @warning = @message

            EXEC GetWPforEUSProposal @eusProposalID, @workPackage OUTPUT

            Set @reqName = 'AutoReq_' + @datasetNum
            
            EXEC @result = dbo.AddUpdateRequestedRun 
                                    @reqName = @reqName,
                                    @experimentNum = @experimentNum,
                                    @requestorPRN = @operPRN,
                                    @instrumentName = @instrumentName,
                                    @workPackage = @workPackage,
                                    @msType = @msType,
                                    @instrumentSettings = 'na',
                                    @wellplateNum = NULL,
                                    @wellNum = NULL,
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
                Set @msg = 'Create AutoReq run request failed: dataset ' + @datasetNum + ' with Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
                RAISERROR (@msg, 11, 24)
            End
        End -- </b3>

        ---------------------------------------------------
        -- If a cart name is specified, update it for the 
        -- requested run
        ---------------------------------------------------
        --
        If @LCCartName NOT IN ('', 'no update') And @requestID > 0
        Begin
        
            If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
                Set @warning = @message

            exec @result = UpdateCartParameters
                                'CartName',
                                @requestID,
                                @LCCartName output,
                                @message output
            --
            Set @myError = @result
            --
            If @myError <> 0
            Begin
                Set @msg = 'Update LC cart name failed: dataset ' + @datasetNum + ' -> ' + @message
                RAISERROR (@msg, 11, 21)
            End
        End
        
        ---------------------------------------------------
        -- Consume the scheduled run 
        ---------------------------------------------------
        
        Set @datasetID = 0
        SELECT @datasetID = Dataset_ID
        FROM T_Dataset 
        WHERE (Dataset_Num = @datasetNum)

        If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
            Set @warning = @message
                
        exec @result = ConsumeScheduledRun @datasetID, @requestID, @message output, @callingUser, @logDebugMessages
        --
        Set @myError = @result
        --
        If @myError <> 0
        Begin
            Set @msg = 'Consume operation failed: dataset ' + @datasetNum + ' -> ' + @message
            RAISERROR (@msg, 11, 16)
        End

        If @@trancount > 0
        Begin
            commit transaction @transName
        End
        Else
        Begin
            Set @debugMsg = '@@trancount is 0; this is unexpected'
            exec PostLogEntry 'Error', @debugMsg, 'AddUpdateDataset'
        End
                
    End -- </AddMode>

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update' 
    Begin -- <UpdateMode>
    
        If @logDebugMessages > 0
        Begin
            Set @debugMsg = 'Update dataset ' + @datasetNum + ' (Dataset ID ' + Cast(@datasetID as varchar(9)) + ')'
            exec PostLogEntry 'Debug', @debugMsg, 'AddUpdateDataset'
        End

        Set @myError = 0
        --
        UPDATE T_Dataset 
        Set 
                DS_Oper_PRN = @operPRN, 
                DS_comment = @comment, 
                DS_type_ID = @datasetTypeID, 
                DS_well_num = @wellNum, 
                DS_sec_sep = @secSep, 
                DS_folder_name = @folderName, 
                Exp_ID = @experimentID,
                DS_rating = @ratingID,
                DS_LC_column_ID = @columnID, 
                DS_wellplate_num = @wellplateNum, 
                DS_internal_standard_ID = @intStdID,
                Capture_Subfolder = @captureSubfolder,
                Cart_Config_ID = @cartConfigID
        WHERE Dataset_ID = @datasetID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Update operation failed: dataset ' + @datasetNum
            RAISERROR (@msg, 11, 4)
        End
        
        -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0 AND @ratingID <> IsNull(@curDSRatingID, -1000)
            Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser

        -- Lookup the Requested Run info for this dataset
        --
        SELECT @requestID = RR.ID,
               @reqName = RR.RDS_Name,
               @reqRunInstSettings = RR.RDS_instrument_setting,
               @workPackage = RR.RDS_WorkPackage,
               @wellplateNum = RR.RDS_Well_Plate_Num,
               @wellNum = RR.RDS_Well_Num,
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
        -- If a cart name is specified, update it for the 
        -- requested run
        ---------------------------------------------------
        --
        If @LCCartName NOT IN ('', 'no update')
        Begin

            If IsNull(@requestID, 0) = 0
            Begin
                Set @warningAddon = 'Dataset is not associated with a requested run; cannot update the LC Cart Name'
                Set @warning = dbo.AppendToText(@warning, @warningAddon, 0, '; ', 512)
            End
            Begin
                Set @warningAddon = ''
                exec @result = UpdateCartParameters
                                    'CartName',
                                    @requestID,
                                    @LCCartName output,
                                    @warningAddon output
                --
                Set @myError = @result
                --
                If @myError <> 0
                Begin
                    Set @warningAddon = 'Update LC cart name failed: ' + @warningAddon
                    Set @warning = dbo.AppendToText(@warning, @warningAddon, 0, '; ', 512)
                    Set @myError = 0
                End
            End    
        End

        If @requestID > 0 And @eusUsageType <> ''
        Begin -- <b4>
            EXEC @result = dbo.AddUpdateRequestedRun 
                                    @reqName = @reqName,
                                    @experimentNum = @experimentNum,
                                    @requestorPRN = @operPRN,
                                    @instrumentName = @instrumentName,
                                    @workPackage = @workPackage,
                                    @msType = @msType,
                                    @instrumentSettings = @reqRunInstSettings,
                                    @wellplateNum = @wellplateNum,
                                    @wellNum = @wellNum,
                                    @internalStandard = @reqRunInternalStandard,
                                    @comment = @reqRunComment,
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
        -- If no jobs are found, call SchedulePredefinedAnalyses for this dataset
        -- Skip jobs with AJ_DatasetUnreviewed=1 when looking for existing jobs (these jobs were created before the dataset was dispositioned)
        ---------------------------------------------------
        --
        If @ratingID >= 2 and IsNull(@curDSRatingID, -1000) IN (-5, -6, -7)
        Begin
            If Not Exists (SELECT * FROM T_Analysis_Job WHERE (AJ_datasetID = @datasetID) AND AJ_DatasetUnreviewed = 0 )
            Begin
                Exec SchedulePredefinedAnalyses @datasetNum, @callingUser=@callingUser
                
                -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in 
                --  T_Event_Log for any newly created jobs for this dataset
                If Len(@callingUser) > 0
                Begin
                    Declare @JobStateID int
                    Set @JobStateID = 1
                    
                    CREATE TABLE #TmpIDUpdateList (
                        TargetID int NOT NULL
                    )
                    
                    INSERT INTO #TmpIDUpdateList (TargetID)
                    SELECT AJ_JobID
                    FROM T_Analysis_Job
                    WHERE (AJ_datasetID = @datasetID)
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    Exec AlterEventLogEntryUserMultiID 5, @JobStateID, @callingUser
                End

            End
        End

    End -- </UpdateMode>


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
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0 And
           Not @message Like 'ValidateEUSUsage%'           
        Begin
            Declare @logMessage varchar(1024) = @message + '; Dataset ' + @datasetNum        
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateDataset'
        End

    End CATCH
    
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [PNL\D3M578] AS [dbo]
GO
