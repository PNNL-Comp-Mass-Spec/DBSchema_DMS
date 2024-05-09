/****** Object:  StoredProcedure [dbo].[add_update_tracking_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_tracking_dataset]
/****************************************************
**
**  Desc:
**      Adds new or edits existing tracking dataset
**
**  Auth:   grk
**  Date:   07/03/2012
**          07/19/2012 grk - Extended interval update range around dataset date
**          05/08/2013 mem - Now setting @wellplateName and @wellNumber to Null instead of 'na'
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Rename @operatorUsername to @requestorUsername when calling add_update_requested_run
**                         - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          02/25/2021 mem - Use replace_character_codes to replace character codes with punctuation marks
**                         - Use remove_cr_lf to replace linefeeds with semicolons
**          02/17/2022 mem - Rename variables, adjust formatting, convert tabs to spaces
**          02/18/2022 mem - Call add_update_requested_run if the EUS usage info is updated
**          05/23/2022 mem - Rename @requestorUsername to @requesterUsername when calling add_update_requested_run
**          11/18/2022 mem - Use new column name in V_Requested_Run_Detail_Report
**          11/25/2022 mem - Update call to add_update_requested_run to use new parameter name
**          11/27/2022 mem - Remove query artifact that was used for debugging
**          12/24/2022 mem - Fix logic error evaluating @runDuration
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2023 mem - Use new argument name, @requestName
**          09/07/2023 mem - Update warning messages
**          01/20/2024 mem - Prevent changing an existing tracking dataset's instrument
**
*****************************************************/
(
    @datasetName varchar(128) = 'TrackingDataset1',
    @experimentName varchar(64) = 'Placeholder',
    @operatorUsername varchar(64) = 'D3J410',
    @instrumentName varchar(64),
    @runStart VARCHAR(32) = '6/1/2012',
    @runDuration VARCHAR(16) = '10',            -- Acquisition length, in minutes (as text)
    @comment varchar(512) = 'na',
    @eusProposalID varchar(10) = 'na',
    @eusUsageType varchar(50) = 'CAP_DEV',
    @eusUsersList varchar(1024) = '',           -- EUS User ID (only a single person is allowed, though long ago multiple people could be listed)
    @mode varchar(12) = 'add',                  -- Can be 'add', 'update', 'bad', 'check_update', 'check_add'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(256)
    Declare @folderName varchar(128)
    Declare @addingDataset tinyint = 0

    Declare @result int
    Declare @warning varchar(512)
    Declare @experimentCheck varchar(128)

    Declare @requestID int = 0
    Declare @requestName varchar(128)
    Declare @wellplateName varchar(64) = NULL
    Declare @wellNumber varchar(64) = NULL
    Declare @secSep varchar(64) = 'none'
    Declare @rating varchar(32) = 'Unknown'

    Declare @existingEusProposal varchar(24)
    Declare @existingEusUsageType varchar(50)
    Declare @existingEusUser varchar(1024)

    Declare @columnID INT = 0
    Declare @intStdID INT = 0
    Declare @ratingID INT = 1 -- 'No Interest'

    Declare @msType varchar(50) = 'Tracking'

    Set @message = ''
    Set @warning = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_tracking_dataset', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    Declare @refDate DATETIME = GETDATE()
    Declare @acqStart DATETIME = @runStart
    Declare @acqEnd DATETIME = DATEADD(MINUTE, 10, @acqStart) -- default

    If @runDuration <> ''
    BEGIN
        SET @acqEnd = DATEADD(MINUTE, CONVERT(INT, @runDuration), @acqStart)
    END

    Declare @datasetTypeID int
    execute @datasetTypeID = get_dataset_type_id @msType

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If IsNull(@mode, '') = ''
    Begin
        Set @msg = '@mode must be specified'
        RAISERROR (@msg, 11, 17)
    End

    If IsNull(@datasetName, '') = ''
    Begin
        Set @msg = 'Dataset name must be specified'
        RAISERROR (@msg, 11, 10)
    End

    Set @folderName = @datasetName

    If IsNull(@experimentName, '') = ''
    Begin
        Set @msg = 'Experiment name must be specified'
        RAISERROR (@msg, 11, 11)
    End

    If IsNull(@folderName, '') = ''
    Begin
        Set @msg = 'Folder name must be specified'
        RAISERROR (@msg, 11, 12)
    End

    If IsNull(@operatorUsername, '') = ''
    Begin
        Set @msg = 'Operator payroll number/HID must be specified'
        RAISERROR (@msg, 11, 13)
    End

    If IsNull(@instrumentName, '') = ''
    Begin
        Set @msg = 'Instrument name must be specified'
        RAISERROR (@msg, 11, 14)
    End

    -- Assure that @comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
    Set @comment = dbo.replace_character_codes(@comment)

    -- Replace instances of CRLF (or LF) with semicolons
    Set @comment = dbo.remove_cr_lf(@comment)

    Set @eusProposalID = IsNull(@eusProposalID, '')
    Set @eusUsageType = IsNull(@eusUsageType, '')
    Set @eusUsersList = IsNull(@eusUsersList, '')

    ---------------------------------------------------
    -- Determine if we are adding or check_adding a dataset
    ---------------------------------------------------
    --
    If @mode IN ('add', 'check_add')
        Set @addingDataset = 1
    Else
        Set @addingDataset = 0

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

    If @datasetName Like '%[.]raw' Or @datasetName Like '%[.]wiff' Or @datasetName Like '%[.]d'
    Begin
        Set @msg = 'Dataset name may not end in .raw, .wiff, or .d'
        RAISERROR (@msg, 11, 2)
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
    End

    If @mode In ('update', 'check_update')
    Begin
        -- Leave the instrument name as-is when updating a tracking entry
        SELECT @instrumentName = IN_name
        FROM t_instrument_name
        WHERE instrument_id = @curDSInstID;
    End

    ---------------------------------------------------
    -- Resolve experiment ID
    ---------------------------------------------------

    Declare @experimentID int
    execute @experimentID = get_experiment_id @experimentName

    If @experimentID = 0
    Begin
        Set @msg = 'Could not find entry in database for experiment ' + @experimentName
        RAISERROR (@msg, 11, 12)
    End

    ---------------------------------------------------
    -- Resolve instrument ID
    ---------------------------------------------------

    Declare @instrumentID int
    Declare @instrumentGroup varchar(64) = ''
    Declare @defaultDatasetTypeID int

    execute @instrumentID = get_instrument_id @instrumentName

    If @instrumentID = 0
    Begin
        Set @msg = 'Could not find entry in database for instrument ' + @instrumentName
        RAISERROR (@msg, 11, 14)
    End

    ---------------------------------------------------
    -- Resolve user ID for operator username
    ---------------------------------------------------

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
    -- Action for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin -- <AddMode>

        ---------------------------------------------------
        -- Lookup storage path ID
        ---------------------------------------------------
        --
        Declare @storagePathID int = 0

        Exec @storagePathID = get_instrument_storage_path_for_new_datasets @instrumentID, @refDate, @autoSwitchActiveStorage=1, @infoOnly=0
        --
        If @storagePathID = 0
        Begin
            Set @storagePathID = 2 -- index of "none" in table
            Set @msg = 'Valid storage path could not be found'
            RAISERROR (@msg, 11, 43)
        End


        -- Start transaction
        --
        Declare @transName varchar(32)
        Set @transName = 'add_new_dataset'
        Begin transaction @transName

        Set @newDSStateID = 3

        -- Insert values into a new row
        --
        INSERT INTO T_Dataset(
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
            Acq_Time_Start,
            Acq_Time_End
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
            @acqStart,
            @acqEnd
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0 or @myRowCount <> 1
        Begin
            Set @msg = 'Insert operation failed for dataset ' + @datasetName
            RAISERROR (@msg, 11, 7)
        End

        -- Get the ID of the newly added dataset
        --
        Set @datasetID = SCOPE_IDENTITY()

        -- If @callingUser is defined, call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec alter_event_log_entry_user 4, @datasetID, @newDSStateID, @callingUser

            Exec alter_event_log_entry_user 8, @datasetID, @ratingID, @callingUser
        End

        ---------------------------------------------------
        -- Adding a tracking dataset, so need to create a scheduled run
        ---------------------------------------------------

        If @requestID = 0
        Begin -- <b3>

            If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
                Set @warning = @message

            Set @requestName = 'AutoReq_' + @datasetName

            EXEC @result = dbo.add_update_requested_run
                                    @requestName = @requestName,
                                    @experimentName = @experimentName,
                                    @requesterUsername = @operatorUsername,
                                    @instrumentName = @instrumentName,
                                    @workPackage = 'none',
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
                                    @callingUser = @callingUser
            --
            Set @myError = @result

            If @myError <> 0
            Begin
                Set @msg = 'Create AutoReq run request failed: dataset ' + @datasetName + ' with EUS Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
                RAISERROR (@msg, 11, 24)
            End
        End -- </b3>

        ---------------------------------------------------
        -- Consume the scheduled run
        ---------------------------------------------------

        Set @datasetID = 0

        SELECT @datasetID = Dataset_ID
        FROM T_Dataset
        WHERE Dataset_Num = @datasetName

        If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
            Set @warning = @message

        exec @result = consume_scheduled_run @datasetID, @requestID, @message output, @callingUser
        --
        Set @myError = @result

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
            exec post_log_entry 'Error', '@@trancount is 0; this is unexpected', 'add_update_tracking_dataset'
        End

        -- Update T_Cached_Dataset_Stats
        Exec dbo.update_cached_dataset_instruments @processingMode=0, @datasetId=@datasetID, @infoOnly=0

    End -- </AddMode>

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin -- <UpdateMode>
        Set @myError = 0
        --
        UPDATE T_Dataset
        SET     DS_Oper_PRN = @operatorUsername,
                DS_comment = @comment,
                DS_type_ID = @datasetTypeID,
                DS_folder_name = @folderName,
                Exp_ID = @experimentID,
                Acq_Time_Start = @acqStart,
                Acq_Time_End = @acqEnd
        WHERE Dataset_Num = @datasetName
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


        -- Call add_update_requested_run if the EUS info has changed

        SELECT @requestName = RR.RDS_Name,
               @existingEusProposal = RR.RDS_EUS_Proposal_ID,
               @existingEusUsageType = RR.RDS_EUS_UsageType,
               @existingEusUser = RRD.EUS_User
        FROM T_Dataset AS DS
             INNER JOIN T_Requested_Run AS RR
               ON DS.Dataset_ID = RR.DatasetID
             INNER JOIN V_Requested_Run_Detail_Report AS RRD
               ON RR.ID = RRD.Request
        WHERE DS.Dataset_Num = @datasetName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0 And (
          Coalesce(@existingEusProposal, '') <> @eusProposalID OR
          Coalesce(@existingEusUsageType, '') <> @eusUsageType OR
          Coalesce(@existingEusUser, '') <> @eusUsersList)
        Begin

            EXEC @result = dbo.add_update_requested_run
                                    @requestName = @requestName,
                                    @experimentName = @experimentName,
                                    @requesterUsername = @operatorUsername,
                                    @instrumentName = @instrumentName,
                                    @workPackage = 'none',
                                    @msType = @msType,
                                    @instrumentSettings = 'na',
                                    @wellplateName = NULL,
                                    @wellNumber = NULL,
                                    @internalStandard = 'na',
                                    @comment = 'Automatically created by Dataset entry',
                                    @eusProposalID = @eusProposalID,
                                    @eusUsageType = @eusUsageType,
                                    @eusUsersList = @eusUsersList,
                                    @mode = 'update',
                                    @request = @requestID output,
                                    @message = @message output,
                                    @secSep = @secSep,
                                    @MRMAttachment = '',
                                    @status = 'Completed',
                                    @SkipTransactionRollback = 1,
                                    @AutoPopulateUserListIfBlank = 1,        -- Auto populate @eusUsersList if blank since this is an Auto-Request
                                    @callingUser = @callingUser
            --
            Set @myError = @result

            If @myError <> 0
            Begin
                Set @msg = 'Call to add_update_requested_run failed: dataset ' + @datasetName + ' with EUS Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
                RAISERROR (@msg, 11, 24)
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

    ---------------------------------------------------
    -- Update interval table
    ---------------------------------------------------
    --
    Declare @nd DATETIME = DATEADD(MONTH, 1, @refDate)
    Declare @st DATETIME = DATEADD(MONTH, -1, @refDate)

    EXEC update_dataset_interval @instrumentName, @st, @nd, @message OUTPUT, 0

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'add_update_tracking_dataset'
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_tracking_dataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_tracking_dataset] TO [DMS2_SP_User] AS [dbo]
GO
