/****** Object:  StoredProcedure [dbo].[duplicate_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[duplicate_dataset]
/****************************************************
**
**  Desc:   Duplicates a dataset by adding a new row to T_Dataset and calling add_update_requested_run
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/12/2018 mem - Initial version
**          08/19/2020 mem - Add @newOperatorUsername
**                         - Add call to update_cached_dataset_instruments
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          05/23/2022 mem - Rename @requestorUsername to @requesterUsername when calling add_update_requested_run
**          11/25/2022 mem - Rename variable and update call to add_update_requested_run to use new parameter name
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2023 mem - Use new argument name, @requestName
**          03/02/2023 mem - Use renamed table names
**
*****************************************************/
(
    @sourceDataset varchar(128),                -- Existing dataset to copy
    @newDataset varchar(128),                   -- New dataset name
    @newComment varchar(512) = '',              -- New dataset comment; use source dataset's comment if blank; use a blank comment if '.' or '<blank>' or '<empty>'
    @newCaptureSubfolder varchar(255) = '',     -- Capture subfolder name; use source dataset's capture subfolder if blank
    @newOperatorUsername varchar(64) = '',      -- Operator username
    @datasetStateID int = 1,                    -- 1 for a new dataset, which will create a dataset capture job; 3=Complete; 4=Inactive; 13=Holding
    @infoOnly tinyint = 1,                      -- 0 to create the dataset, 1 to preview
    @message varchar(512) = '' output           -- Output message
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetID int = 0
    Declare @workPackage varchar(12) = 'none'

    Declare @sourceDatasetRequestID int
    Declare @requestName varchar(128)
    Declare @experimentName varchar(64)
    Declare @instrumentName varchar(64)
    Declare @instrumentSettings Varchar(1024)
    Declare @msType varchar(50)
    Declare @separationGroup varchar(64)
    Declare @eusProposalID varchar(10) = 'na'
    Declare @eusUsageType varchar(50)
    Declare @eusUsersList varchar(1024) = ''

    Declare @requestID int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @sourceDataset = IsNull(@sourceDataset, '')
    Set @newDataset = IsNull(@newDataset, '')
    Set @newComment = IsNull(@newComment, '')
    Set @newCaptureSubfolder = IsNull(@newCaptureSubfolder, '')
    Set @newOperatorUsername = ISNULL(@newOperatorUsername, '')
    Set @datasetStateID = IsNull(@datasetStateID, 1)
    Set @infoOnly  = IsNull(@infoOnly, 1)

    Set @message = ''

    If @sourceDataset = ''
    Begin
        Set @message = '@sourceDataset is empty'
        Select @message as Error

        Goto Done
    End

    If @newDataset = ''
    Begin
        Set @message = '@newDataset is empty'
        Select @message as Error

        Goto Done
    End

    If Not Exists (Select * From T_Dataset Where Dataset_Num = @sourceDataset)
    Begin
        Set @message = 'Source dataset not found in T_Dataset: ' + @sourceDataset
        Select @message as Error

        Goto Done
    End

    If Exists (Select * From T_Dataset Where Dataset_Num = @newDataset)
    Begin
        Set @message = 'T_Dataset already has dataset: ' + @newDataset
        Select @message as Error

        Goto Done
    End

    Declare @sourceDatasetId int
    Declare @operatorUsername varchar(64)
    Declare @comment varchar(512)
    Declare @instrumentID int
    Declare @datasetTypeID int
    Declare @wellNumber varchar(64)
    Declare @secSep varchar(64)
    Declare @storagePathID int
    Declare @experimentID int
    Declare @ratingID int
    Declare @columnID int
    Declare @wellplateName varchar(64)
    Declare @intStdID Int
    Declare @captureSubfolder varchar(255)
    Declare @cartConfigID int

    ---------------------------------------------------
    -- Lookup the source dataset info, including Experiment name
    ---------------------------------------------------
    --
    SELECT @sourceDatasetId = D.Dataset_ID,
           @operatorUsername = D.DS_Oper_PRN,
           @comment = D.DS_comment,
           @instrumentID = D.DS_instrument_name_ID,
           @datasetTypeID = D.DS_type_ID,
           @wellNumber = D.DS_well_num,
           @secSep = D.DS_sec_sep,
           @storagePathID = D.DS_storage_path_ID,
           @experimentID = D.Exp_ID,
           @ratingID = D.DS_rating,
           @columnID = D.DS_LC_column_ID,
           @wellplateName = D.DS_wellplate_num,
           @intStdID = D.DS_internal_standard_ID,
           @captureSubfolder = D.Capture_Subfolder,
           @cartConfigID = D.Cart_Config_ID,
           @experimentName = E.Experiment_Num
    FROM T_Dataset D
         INNER JOIN T_Experiments E
           ON D.Exp_ID = E.Exp_ID
    WHERE D.Dataset_Num = @sourceDataset
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Dataset not found: ' + @sourceDataset
        Select @message as Error

        Goto Done
    End

    If @newComment <> ''
    Begin
        Set @comment = Ltrim(Rtrim(@newComment))

        If @comment In ('.', '<blank>', '[blank]', '<empty>', '[empty]')
            Set @comment = ''
    End

    If @newCaptureSubfolder <> ''
        Set @captureSubfolder = @newCaptureSubfolder

    ---------------------------------------------------
    -- Lookup requested run information
    ---------------------------------------------------
    --
    SELECT @sourceDatasetRequestID = RR.ID,
           @instrumentName = RR.RDS_instrument_group,
           @workPackage = RR.RDS_WorkPackage,
           @instrumentSettings = RR.RDS_instrument_setting,
           @msType = DTN.DST_name,
           @separationGroup = RR.RDS_Sec_Sep,
           @eusProposalID = RR.RDS_EUS_Proposal_ID,
           @eusUsageType = EUT.[Name]
    FROM T_Requested_Run AS RR
         INNER JOIN T_Dataset_Type_Name AS DTN
           ON RR.RDS_type_ID = DTN.DST_Type_ID
         INNER JOIN T_EUS_UsageType AS EUT
           ON RR.RDS_EUS_UsageType = EUT.ID
    WHERE DatasetID = @sourceDatasetId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Source dataset does not have a requested run; use add_missing_requested_run to add one'
        Select @message as Error

        Goto Done
    End

    Set @eusUsersList = dbo.get_requested_run_eus_users_list(@sourceDatasetRequestID, 'I')

    If @newOperatorUsername <> ''
    Begin
        ---------------------------------------------------
        -- Resolve user ID for operator username
        ---------------------------------------------------

        Declare @userID int
        execute @userID = get_user_id @newOperatorUsername

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
            -- Could not find entry in database for username @newOperatorUsername
            -- Try to auto-resolve the name

            Declare @matchCount int
            Declare @newUsername varchar(64)

            exec auto_resolve_name_to_username @newOperatorUsername, @matchCount output, @newUsername output, @userID output

            If @MatchCount = 1
            Begin
                -- Single match found; update @operatorUsername
                Set @operatorUsername = @newUsername
            End
            Else
            Begin
                Set @message = 'Could not find entry in database for operator username ' + @newOperatorUsername
                Select @message as Error
                Goto Done
            End
        End
    End

    If @infoOnly <> 0
    Begin
        SELECT @newDataset AS Dataset,
               @operatorUsername AS Operator_PRN,
               @comment AS [Comment],
               GetDate() AS DS_Created,
               @instrumentID AS Instrument_ID,
               @datasetTypeID AS DS_TypeID,
               @wellNumber AS WellNumber,
               @secSep AS SecondarySep,
               @datasetStateID AS DatasetStateID,
               @newDataset AS Dataset_Folder,
               @storagePathID AS StoragePathID,
               @experimentID AS ExperimentID,
               @ratingID AS RatingID,
               @columnID AS ColumnID,
               @wellplateName AS WellplateName,
               @intStdID AS InternalStandardID,
               @captureSubfolder AS Capture_SubFolder,
               @cartConfigID AS CartConfigID


        Select 'AutoReq_' + @newDataset As Requested_Run,
                                @experimentName As Experiment,
                                @operatorUsername As Operator_Username,
                                @instrumentName As Instrument,
                                @workPackage As WP,
                                @msType As MSType,
                                @separationGroup As SeparationGroup,
                                @instrumentSettings As Instrument_Settings,
                                @wellplateName As WellplateName,
                                @wellNumber As WellNumber,
                                'na' As InternalStandard,
                                'Automatically created by Dataset entry' As [Comment],
                                @eusProposalID As EUS_ProposalID,
                                @eusUsageType As EUS_ProposalType,
                                @eusUsersList As EUS_ProposalUsers,
                                @separationGroup As SeparationGroup,
                                '' As MRMAttachment,
                                'Completed' As Status


    End
    Else
    Begin

        Declare @transName varchar(32) = 'add_new_dataset'

        Begin transaction @transName

        ---------------------------------------------------
        -- Create the new dataset
        ---------------------------------------------------
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
            @newDataset,
            @operatorUsername,
            @comment,
            GetDate(),
            @instrumentID,
            @datasetTypeID,
            @wellNumber,
            @secSep,
            @datasetStateID,
            @newDataset,        -- DS_folder_name
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
        --
        If @myError <> 0 or @myRowCount <> 1
        Begin
            Rollback transaction @transName

            Set @message = 'Insert operation failed for dataset ' + @newDataset
            Select @message as Error

            Goto Done
        End

        -- Get the ID of newly created dataset
        Set @datasetID = SCOPE_IDENTITY()

        ---------------------------------------------------
        -- Create a requested run
        ---------------------------------------------------
        --
        Set @requestName = 'AutoReq_' + @newDataset

        EXEC @myError = dbo.add_update_requested_run
                                @requestName = @requestName,
                                @experimentName = @experimentName,
                                @requesterUsername = @operatorUsername,
                                @instrumentName = @instrumentName,
                                @workPackage = @workPackage,
                                @msType = @msType,
                                @instrumentSettings = @instrumentSettings,
                                @wellplateName = @wellplateName,
                                @wellNumber = @wellNumber,
                                @internalStandard = 'na',
                                @comment = 'Automatically created by Dataset entry',
                                @eusProposalID = @eusProposalID,
                                @eusUsageType = @eusUsageType,
                                @eusUsersList = @eusUsersList,
                                @mode = 'add-auto',
                                @request = @requestID output,
                                @message = @message output,
                                @secSep = @separationGroup,
                                @MRMAttachment = '',
                                @status = 'Completed',
                                @SkipTransactionRollback = 1,
                                @AutoPopulateUserListIfBlank = 1        -- Auto populate @eusUsersList if blank since this is an Auto-Request

        --
        If @myError <> 0
        Begin
            Rollback transaction @transName

            Set @message = 'Create AutoReq run request failed: dataset ' + @newDataset + ' with Proposal ID ' + @eusProposalID + ', Usage Type ' + @eusUsageType + ', and Users List ' + @eusUsersList + ' ->' + @message
            Select @message as Error

            Goto Done
        End

        ---------------------------------------------------
        -- Consume the scheduled run
        ---------------------------------------------------

        exec @myError = consume_scheduled_run @datasetID, @requestID, @message output
        --
        If @myError <> 0
        Begin
            Rollback transaction @transName

            Set @message = 'Consume operation failed: dataset ' + @newDataset + ' -> ' + @message
            Select @message as Error

            Goto Done
        End

        Commit transaction @transName

        -- Update T_Cached_Dataset_Instruments
        Exec dbo.update_cached_dataset_instruments @processingMode=0, @datasetId=@datasetID, @infoOnly=0

        Select @newDataset As Dataset_New, @datasetID As Dataset_ID, @requestID As RequestedRun_ID, 'Duplicated dataset ' + @sourceDataset As Status

        SELECT *
        FROM V_Dataset_Detail_Report_Ex
        WHERE ID = @datasetID

    End

Done:

    return @myError


GO
