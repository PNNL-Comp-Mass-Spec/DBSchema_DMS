/****** Object:  StoredProcedure [dbo].[AddUpdateTrackingDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateTrackingDataset]
/****************************************************
**
**  Desc:   Adds new or edits existing tracking dataset
**
**  Auth:   grk
**  Date:   07/03/2012
**          07/19/2012 grk - Extended interval update range around dataset date
**          05/08/2013 mem - Now setting @wellplateNum and @wellNum to Null instead of 'na'
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Rename @operPRN to @requestorPRN when calling AddUpdateRequestedRun
**                         - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          02/25/2021 mem - Use ReplaceCharacterCodes to replace character codes with punctuation marks
**                         - Use RemoveCrLf to replace linefeeds with semicolons
**          02/17/2022 mem - Rename variables, adjust formatting, convert tabs to spaces
**          02/18/2022 mem - Call AddUpdateRequestedRun if the EUS usage info is updated
**          05/23/2022 mem - Rename @requestorPRN to @requesterPRN when calling AddUpdateRequestedRun
**          11/18/2022 mem - Use new column name in V_Requested_Run_Detail_Report
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @datasetNum varchar(128) = 'TrackingDataset1',
    @experimentNum varchar(64) = 'Placeholder',
    @operPRN varchar(64) = 'D3J410',
    @instrumentName varchar(64),
    @runStart VARCHAR(32) = '6/1/2012',
    @runDuration VARCHAR(16) = '10',
    @comment varchar(512) = 'na',
    @eusProposalID varchar(10) = 'na',
    @eusUsageType varchar(50) = 'CAP_DEV',
    @eusUsersList varchar(1024) = '',         -- EUS User ID (only a single person is allowed, though long ago multiple people could be listed)
    @mode varchar(12) = 'add',                -- Can be 'add', 'update', 'bad', 'check_update', 'check_add'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
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
    Declare @reqName varchar(128)
    Declare @wellplateNum varchar(64) = NULL
    Declare @wellNum varchar(64) = NULL
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
    Exec @authorized = VerifySPAuthorized 'AddUpdateTrackingDataset', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    Declare @refDate DATETIME = GETDATE()
    Declare @acqStart DATETIME = @runStart
    Declare @acqEnd DATETIME = DATEADD(MINUTE, 10, @acqStart) -- default

    If @runDuration <> '' OR @runDuration < 1
    BEGIN
        SET @acqEnd = DATEADD(MINUTE, CONVERT(INT, @runDuration), @acqStart)
    END

    Declare @datasetTypeID int
    execute @datasetTypeID = GetDatasetTypeID @msType

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If IsNull(@mode, '') = ''
    Begin
        Set @msg = '@mode was blank'
        RAISERROR (@msg, 11, 17)
    End

    If IsNull(@datasetNum, '') = ''
    Begin
        Set @msg = 'Dataset name was blank'
        RAISERROR (@msg, 11, 10)
    End

    Set @folderName = @datasetNum

    If IsNull(@experimentNum, '') = ''
    Begin
        Set @msg = 'Experiment name was blank'
        RAISERROR (@msg, 11, 11)
    End

    If IsNull(@folderName, '') = ''
    Begin
        Set @msg = 'Folder name was blank'
        RAISERROR (@msg, 11, 12)
    End

    If IsNull(@operPRN, '') = ''
    Begin
        Set @msg = 'Operator payroll number/HID was blank'
        RAISERROR (@msg, 11, 13)
    End

    If IsNull(@instrumentName, '') = ''
    Begin
        Set @msg = 'Instrument name was blank'
        RAISERROR (@msg, 11, 14)
    End

    -- Assure that @comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
    Set @comment = dbo.ReplaceCharacterCodes(@comment)

    -- Replace instances of CRLF (or LF) with semicolons
    Set @comment = dbo.RemoveCrLf(@comment)

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
    Declare @badCh varchar(128) = dbo.ValidateChars(@datasetNum, '')

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

    If @datasetNum Like '%[.]raw' Or @datasetNum Like '%[.]wiff' Or @datasetNum Like '%[.]d'
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
    WHERE Dataset_Num = @datasetNum

    Set @datasetID = IsNull(@datasetID, 0)

    If @datasetID = 0
    Begin
        -- Cannot update a non-existent entry
        --
        If @mode IN ('update', 'check_update')
        Begin
            Set @msg = 'Cannot update: Dataset ' + @datasetNum + ' is not in database'
            RAISERROR (@msg, 11, 4)
        End
    End
    Else
    Begin
        -- Cannot create an entry that already exists
        --
        If @addingDataset = 1
        Begin
            Set @msg = 'Cannot add dataset ' + @datasetNum + ' since already in database'
            RAISERROR (@msg, 11, 5)
        End
    End

    ---------------------------------------------------
    -- Resolve experiment ID
    ---------------------------------------------------

    Declare @experimentID int
    execute @experimentID = GetExperimentID @experimentNum

    If @experimentID = 0
    Begin
        Set @msg = 'Could not find entry in database for experiment ' + @experimentNum
        RAISERROR (@msg, 11, 12)
    End

    ---------------------------------------------------
    -- Resolve instrument ID
    ---------------------------------------------------

    Declare @instrumentID int
    Declare @instrumentGroup varchar(64) = ''
    Declare @defaultDatasetTypeID int

    execute @instrumentID = GetinstrumentID @instrumentName

    If @instrumentID = 0
    Begin
        Set @msg = 'Could not find entry in database for instrument ' + @instrumentName
        RAISERROR (@msg, 11, 14)
    End

    ---------------------------------------------------
    -- Resolve user ID for operator username
    ---------------------------------------------------

    Declare @userID int
    execute @userID = GetUserID @operPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @operPRN contains simply the username
        --
        SELECT @operPRN = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        -- Could not find entry in database for PRN @operPRN
        -- Try to auto-resolve the name

        Declare @matchCount int
        Declare @newPRN varchar(64)

        exec AutoResolveNameToPRN @operPRN, @matchCount output, @newPRN output, @userID output

        If @matchCount = 1
        Begin
            -- Single match found; update @operPRN
            Set @operPRN = @newPRN
        End
        Else
        Begin
            Set @msg = 'Could not find entry in database for operator username ' + @operPRN
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

        Exec @storagePathID = GetInstrumentStoragePathForNewDatasets @instrumentID, @refDate, @autoSwitchActiveStorage=1, @infoOnly=0
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
        Set @transName = 'AddNewDataset'
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
            @datasetNum,
            @operPRN,
            @comment,
            @refDate,
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
            @acqStart,
            @acqEnd
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0 or @myRowCount <> 1
        Begin
            Set @msg = 'Insert operation failed for dataset ' + @datasetNum
            RAISERROR (@msg, 11, 7)
        End

        -- Get the ID of the newly added dataset
        --
        Set @datasetID = SCOPE_IDENTITY()

        -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0
        Begin
            Exec AlterEventLogEntryUser 4, @datasetID, @newDSStateID, @callingUser

            Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser
        End

        ---------------------------------------------------
        -- Adding a tracking dataset, so need to create a scheduled run
        ---------------------------------------------------

        If @requestID = 0
        Begin -- <b3>

            If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
                Set @warning = @message

            Set @reqName = 'AutoReq_' + @datasetNum

            EXEC @result = dbo.AddUpdateRequestedRun
                                    @reqName = @reqName,
                                    @experimentNum = @experimentNum,
                                    @requesterPRN = @operPRN,
                                    @instrumentName = @instrumentName,
                                    @workPackage = 'none',
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
                                    @callingUser = @callingUser
            --
            Set @myError = @result

            If @myError <> 0
            Begin
                Set @msg = 'Create AutoReq run request failed: dataset ' + @datasetNum + ' with EUS Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
                RAISERROR (@msg, 11, 24)
            End
        End -- </b3>

        ---------------------------------------------------
        -- Consume the scheduled run
        ---------------------------------------------------

        Set @datasetID = 0

        SELECT @datasetID = Dataset_ID
        FROM T_Dataset
        WHERE Dataset_Num = @datasetNum

        If IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
            Set @warning = @message

        exec @result = ConsumeScheduledRun @datasetID, @requestID, @message output, @callingUser
        --
        Set @myError = @result

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
            exec PostLogEntry 'Error', '@@trancount is 0; this is unexpected', 'AddUpdateTrackingDataset'
        End

        -- Update T_Cached_Dataset_Instruments
        Exec dbo.UpdateCachedDatasetInstruments @processingMode=0, @datasetId=@datasetID, @infoOnly=0

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
        SET     DS_Oper_PRN = @operPRN,
                DS_comment = @comment,
                DS_instrument_name_ID = @instrumentID,
                DS_type_ID = @datasetTypeID,
                DS_folder_name = @folderName,
                Exp_ID = @experimentID,
                Acq_Time_Start = @acqStart,
                Acq_Time_End = @acqEnd
        WHERE Dataset_Num = @datasetNum
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @msg = 'Update operation failed: dataset ' + @datasetNum
            RAISERROR (@msg, 11, 4)
        End

        -- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
        If Len(@callingUser) > 0 AND @ratingID <> IsNull(@curDSRatingID, -1000)
            Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser


        -- Call AddUpdateRequestedRun if the EUS info has changed
        SELECT TOP 1 @reqName = RR.RDS_Name,
                     @existingEusProposal = RR.RDS_EUS_Proposal_ID,
                     @existingEusUsageType = RR.RDS_EUS_UsageType,
                     @existingEusUser = U.EUS_Person_ID
        FROM T_Dataset AS DS
             INNER JOIN T_Requested_Run AS RR
               ON DS.Dataset_ID = RR.DatasetID
             LEFT OUTER JOIN T_Requested_Run_EUS_Users U
               ON RR.ID = U.Request_ID
        WHERE (DS.Dataset_Num = 'LTQ_2_01Nov15')

        SELECT @reqName = RR.RDS_Name,
               @existingEusProposal = RR.RDS_EUS_Proposal_ID,
               @existingEusUsageType = RR.RDS_EUS_UsageType,
               @existingEusUser = RRD.EUS_User
        FROM T_Dataset AS DS
             INNER JOIN T_Requested_Run AS RR
               ON DS.Dataset_ID = RR.DatasetID
             INNER JOIN V_Requested_Run_Detail_Report AS RRD
               ON RR.ID = RRD.Request
        WHERE DS.Dataset_Num = @datasetNum
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0 And (
          Coalesce(@existingEusProposal, '') <> @eusProposalID OR
          Coalesce(@existingEusUsageType, '') <> @eusUsageType OR
          Coalesce(@existingEusUser, '') <> @eusUsersList)
        Begin

            EXEC @result = dbo.AddUpdateRequestedRun
                                    @reqName = @reqName,
                                    @experimentNum = @experimentNum,
                                    @requesterPRN = @operPRN,
                                    @instrumentName = @instrumentName,
                                    @workPackage = 'none',
                                    @msType = @msType,
                                    @instrumentSettings = 'na',
                                    @wellplateNum = NULL,
                                    @wellNum = NULL,
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
                Set @msg = 'Call to AddUpdateRequestedRun failed: dataset ' + @datasetNum + ' with EUS Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
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

    EXEC UpdateDatasetInterval @instrumentName, @st, @nd, @message OUTPUT, 0

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AddUpdateTrackingDataset'
    END CATCH

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateTrackingDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateTrackingDataset] TO [DMS2_SP_User] AS [dbo]
GO
