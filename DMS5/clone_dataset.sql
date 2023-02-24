/****** Object:  StoredProcedure [dbo].[CloneDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CloneDataset]
/****************************************************
**
**  Desc:
**      Clones a dataset, including creating a new requested run; does not clone any jobs
**
**      This procedure is intended to be used in cases where a dataset's files have been manually duplicated on a storage server
**      and we wish to run new analysis jobs against the cloned dataset using DMS
**
**  Return values: 0 if no error; otherwise error code
**
**  Auth:   mem
**  Date:   02/27/2014
**          09/25/2014 mem - Updated T_Job_Step_Dependencies to use Job
**                           Removed the Machine column from T_Job_Steps
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/13/2017 mem - Rename @operPRN to @requestorPRN when calling AddUpdateRequestedRun
**          05/23/2022 mem - Rename @requestorPRN to @requesterPRN when calling AddUpdateRequestedRun
**          11/25/2022 mem - Update call to AddUpdateRequestedRun to use new parameter name
**
*****************************************************/
(
    @infoOnly tinyint = 1,                      -- Change to 0 to actually perform the clone; 1 to preview items that would be created
    @Dataset varchar(128),                      -- Dataset name to clone
    @Suffix varchar(24) = '_Test1',             -- Suffix to apply to cloned dataset and requested run
    @CreateDatasetArchiveTask tinyint = 0,      -- Set to 1 to instruct DMS to archive the cloned dataset
    @message varchar(255) = '' OUTPUT
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int    = 0

    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Declare @TranClone varchar(24) = 'Clone'
    Declare @RequestID int = 0

    Declare @experimentNum varchar(64)
    Declare @operPRN varchar(50)
    Declare @instrumentName varchar(64)
    Declare @workPackage varchar(50)
    Declare @DatasetType varchar(50)
    Declare @instrumentSettings varchar(1024)
    Declare @wellplate varchar(64)
    Declare @wellNum varchar(64)
    Declare @internalStandard varchar(64)
    Declare @comment varchar(512)
    Declare @eusProposalID varchar(10)
    Declare @eusUsageType varchar(50)
    Declare @eusUsersList varchar(1024)
    Declare @secSep varchar(64)

    Declare @DatasetIDNew int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @Dataset = IsNull(@Dataset, '')
    Set @Suffix = IsNull(@Suffix, '')
    Set @CreateDatasetArchiveTask = IsNull(@CreateDatasetArchiveTask, 0)

    Set @message = ''

    If @Dataset = ''
    Begin
        Set @message = '@Dataset parameter cannot be empty'
        print @message
        Goto Done
    End

    If @Suffix = ''
    Begin
        Set @message = '@Suffix parameter cannot be empty'
        print @message
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure the source dataset exists (and determine the Requested Run ID)
    ---------------------------------------------------
    --
    SELECT @RequestID = RR.ID
    FROM T_Requested_Run RR
         INNER JOIN T_Dataset DS
           ON RR.DatasetID = DS.Dataset_ID
    WHERE DS.Dataset_Num = @Dataset
    --
    Select @myRowCount = @@RowCount, @myError = @@Error

    If @myRowCount = 0 Or IsNull(@RequestID, 0) = 0
    Begin
        Set @message = 'Source dataset not found: ' + @Dataset
        print @message
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure the target dataset does not already exist
    ---------------------------------------------------

    Declare @DatasetNew varchar(128) = @Dataset + @Suffix

    If Exists (SELECT * FROM T_Dataset WHERE Dataset_Num = @DatasetNew)
    Begin
        Set @message = 'Target dataset already exists: ' + @DatasetNew
        print @message
        Goto Done
    End


    BEGIN TRY

        -- Lookup the EUS Users for the request associated with the dataset we are cloning
        --
        Set @eusUsersList = null

        SELECT @eusUsersList = Coalesce(@eusUsersList + ',', '') + Convert(varchar(12), EUS_Person_ID)
        FROM T_Requested_Run_EUS_Users
        WHERE Request_ID = @RequestID
        --
        Select @myRowCount = @@RowCount, @myError = @@Error

        Set @eusUsersList = IsNull(@eusUsersList, '')

        -- Lookup the information requred to create a new requested run
        --
        SELECT @experimentNum = E.Experiment_Num,
               @operPRN = DS.DS_Oper_PRN,
               @instrumentName = Inst.IN_name,
               @workPackage = RR.RDS_WorkPackage,
               @DatasetType = DTN.DST_name,                     -- Aka @msType
               @instrumentSettings = RR.RDS_instrument_setting,
               @wellplate = RR.RDS_Well_Plate_Num,
               @wellNum = RR.RDS_Well_Num,
               @internalStandard = RR.RDS_internal_standard,
               @comment = 'Automatically created by Dataset entry',
               @eusProposalID = RR.RDS_EUS_Proposal_ID,
               @eusUsageType = EUT.Name,
               @secSep = RR.RDS_Sec_Sep
        FROM T_Dataset DS
             INNER JOIN T_Requested_Run RR
               ON DS.Dataset_ID = RR.DatasetID
             INNER JOIN T_Experiments E
               ON DS.Exp_ID = E.Exp_ID
             INNER JOIN T_Instrument_Name Inst
               ON DS.DS_instrument_name_ID = Inst.Instrument_ID
             INNER JOIN T_DatasetTypeName DTN
               ON DS.DS_type_ID = DTN.DST_Type_ID
             INNER JOIN T_EUS_UsageType EUT
               ON RR.RDS_EUS_UsageType = EUT.ID
        WHERE DS.Dataset_Num = @Dataset


        Declare @requestNameNew varchar(128) = 'AutoReq_' + @DatasetNew

        If @infoOnly <> 0
        Begin -- <a>
            ---------------------------------------------------
            -- Preview the new dataset
            ---------------------------------------------------

            SELECT @DatasetNew AS Dataset_Num_New, *
            FROM T_Dataset
            WHERE (Dataset_Num = @Dataset)

            ---------------------------------------------------
            -- Preview the new requested run
            ---------------------------------------------------

            SELECT @requestNameNew AS Request_Name_New,
                   @experimentNum AS Experiment,
                   @instrumentName AS Instrument,
                   @workPackage AS WorkPackage,
                   @DatasetType AS Dataset_Type,
                   @instrumentSettings AS Instrument_Settings,
                   @wellplate AS Well_Plate_Num,
                   @wellNum AS Well_Num,
                   @internalStandard AS Internal_standard,
                   @comment AS [Comment],
                   @eusProposalID AS EUS_Proposal_ID,
                   @eusUsageType AS EUS_UsageType,
                   @eusUsersList AS EUS_UsersList,
                   @secSep AS Sec_Sep

        End -- </a>
        Else
        Begin -- <b>

            ---------------------------------------------------
            -- Duplicate the dataset
            ---------------------------------------------------

            -- Start a transaction
            Begin Tran @TranClone


            -- Add a new row to T_Dataset
            --
            INSERT INTO T_Dataset (Dataset_Num, DS_Oper_PRN, DS_comment, DS_created, DS_instrument_name_ID, DS_LC_column_ID, DS_type_ID,
                                   DS_wellplate_num, DS_well_num, DS_sec_sep, DS_state_ID, DS_Last_Affected, DS_folder_name, DS_storage_path_ID,
                                   Exp_ID, DS_internal_standard_ID, DS_rating, DS_Comp_State, DS_Compress_Date, DS_PrepServerName,
                                   Acq_Time_Start, Acq_Time_End, Scan_Count, File_Size_Bytes, File_Info_Last_Modified, Interval_to_Next_DS
            )
            SELECT @DatasetNew AS Dataset_Num,
                DS_Oper_PRN,
                'Cloned from dataset ' + @Dataset AS DS_comment,
                GetDate() AS DS_created,
                DS_instrument_name_ID,
                DS_LC_column_ID,
                DS_type_ID,
                DS_wellplate_num,
                DS_well_num,
                DS_sec_sep,
                DS_state_ID,
                GetDate() AS DS_Last_Affected,
                @DatasetNew AS DS_folder_name,
                DS_storage_path_ID,
                Exp_ID,
                DS_internal_standard_ID,
                DS_rating,
                DS_Comp_State,
                DS_Compress_Date,
                DS_PrepServerName,
                Acq_Time_Start,
                Acq_Time_End,
                Scan_Count,
                File_Size_Bytes,
                File_Info_Last_Modified,
                Interval_to_Next_DS
            FROM T_Dataset
            WHERE Dataset_Num = @Dataset
            --
            Select @myRowCount = @@RowCount, @myError = @@Error

            Set @DatasetIDNew = SCOPE_IDENTITY()

            -- Create a requested run for the dataset
            -- (code is from AddUpdateDataset)

            EXEC @myError = dbo.AddUpdateRequestedRun
                                    @reqName = @requestNameNew,
                                    @experimentNum = @experimentNum,
                                    @requesterPRN = @operPRN,
                                    @instrumentName = @instrumentName,
                                    @workPackage = @workPackage,
                                    @msType = @datasetType,
                                    @instrumentSettings = @instrumentSettings,
                                    @wellplate = @wellplate,
                                    @wellNum = @wellNum,
                                    @internalStandard = @internalStandard,
                                    @comment = @comment,
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
                                    @AutoPopulateUserListIfBlank = 1        -- Auto populate @eusUsersList if blank since this is an Auto-Request

            If @myError <> 0
            Begin
                rollback
                Exec PostLogEntry 'Error', @message, 'CloneDataset'
                Goto Done
            End

            -- Associate the requested run with the dataset
            --
            UPDATE T_Requested_Run
            SET DatasetID = @DatasetIDNew
            WHERE RDS_Name = @requestNameNew AND DatasetID Is Null

            -- Possibly create a Dataset Archive task
            --
            If @CreateDatasetArchiveTask <> 0
                execute AddArchiveDataset @DatasetIDNew
            Else
                print 'You should manually create a dataset archive task using: execute AddArchiveDataset ' + Convert(varchar(12), @DatasetIDNew)

            -- Finalize the transaction
            Commit

            Set @message = 'Created dataset ' + @DatasetNew + ' by cloning ' + @Dataset

            Exec PostLogEntry 'Normal', @message, 'CloneDataset'


            -- Create a Capture job for the newly cloned dataset

            Declare @CaptureJob int = 0
            Declare @CaptureJobNew int = 0
            Declare @dateStamp datetime

            SELECT @CaptureJob = MAX(Job)
            FROM DMS_Capture.dbo.T_Jobs
            WHERE Dataset = @Dataset AND Script LIKE '%capture%'
            --
            Select @myRowCount = @@RowCount, @myError = @@Error


            If @myRowCount = 0 Or IsNull(@CaptureJob, 0) = 0
            Begin -- <c1>
                -- Job not found; examine T_Jobs_History
                SELECT TOP 1 @CaptureJob = Job,
                             @dateStamp = Saved
                FROM DMS_Capture.dbo.T_Jobs_History
                WHERE Dataset = @Dataset AND
                      Script LIKE '%capture%'
                ORDER BY Saved DESC

                --
                Select @myRowCount = @@RowCount, @myError = @@Error

                If @myRowCount = 0
                Begin
                    Print 'Unable to create capture job in DMS_Capture since source job not found for dataset ' + @Dataset
                    Goto Done
                End


                INSERT INTO DMS_Capture.dbo.T_Jobs (Priority, Script, State,
                                    Dataset, Dataset_ID, Results_Folder_Name,
                                    Imported, Start, Finish)
                SELECT Priority,
                        Script,
                        3 AS State,
                        @DatasetNew AS Dataset,
                        @DatasetIDNew AS Dataset_ID,
                        '' AS Results_Folder_Name,
                        GetDate() AS Imported,
                        GetDate() AS Start,
                        GetDate() AS Finish
                FROM DMS_Capture.dbo.T_Jobs_History
                WHERE Job = @CaptureJob AND
                        Saved = @dateStamp
                --
                Select @myRowCount = @@RowCount, @myError = @@Error

                Set @CaptureJobNew = SCOPE_IDENTITY()

                If @CaptureJobNew > 0
                Begin -- <d1>

                    INSERT INTO DMS_Capture.dbo.T_Job_Steps( Job,
                                                Step_Number,
                                                Step_Tool,
                                                State,
                                                Input_Folder_Name,
                                                Output_Folder_Name,
                                                Processor,
                                                Start,
                                                Finish,
                                                Tool_Version_ID,
                                                Completion_Code,
                                                Completion_Message,
                                                Evaluation_Code,
                                                Evaluation_Message,
                                                Holdoff_Interval_Minutes,
                                                Next_Try,
                                                Retry_Count )
                    SELECT @CaptureJobNew AS Job,
                           Step_Number,
                           Step_Tool,
                           Case When State Not In (3,5,7) Then 7 Else State End As State,
                           Input_Folder_Name,
                           Output_Folder_Name,
                           'In-Silico' AS Processor,
                           Case When Start Is Null Then Null Else GetDate() End As Start,
                           Case When Finish Is Null Then Null Else GetDate() End As Finish,
                           1 As Tool_Version_ID,
                           0 AS Completion_Code,
                           '' AS Completion_Message,
                           0 AS Evaluation_Code,
                           '' AS Evaluation_Message,
                           0 AS Holdoff_Interval_Minutes,
                           GetDate() AS Next_Try,
                           0 AS Retry_Count
                    FROM DMS_Capture.dbo.T_Job_Steps_History
                    WHERE Job = @CaptureJob AND
                            Saved = @dateStamp
                    --
                    Select @myRowCount = @@RowCount, @myError = @@Error

                End -- </d1>


            End -- </c1>
            Else
            Begin -- <c2>
                INSERT INTO DMS_Capture.dbo.T_Jobs (Priority, Script, State,
                                    Dataset, Dataset_ID, Storage_Server, Instrument, Instrument_Class,
                                    Max_Simultaneous_Captures,
                                    Imported, Start, Finish, Archive_Busy, Comment)
                SELECT Priority,
                       Script,
                       State,
                       @DatasetNew AS Dataset,
                       @DatasetIDNew AS Dataset_ID,
                       Storage_Server,
                       Instrument,
                       Instrument_Class,
                       Max_Simultaneous_Captures,
                       GetDate() AS Imported,
                       GetDate() AS Start,
                       GetDate() AS Finish,
                       0 AS Archive_Busy,
                       'Cloned from dataset ' + @Dataset AS [Comment]
                FROM DMS_Capture.dbo.T_Jobs
                WHERE Dataset = @Dataset AND
                      Script LIKE '%capture%'
                --
                Select @myRowCount = @@RowCount, @myError = @@Error

                Set @CaptureJobNew = SCOPE_IDENTITY()

                If @CaptureJobNew > 0
                Begin -- <d2>

                    INSERT INTO DMS_Capture.dbo.T_Job_Steps( Job,
                                                             Step_Number,
                                                             Step_Tool,
                                                             CPU_Load,
                                                             Dependencies,
                                                             State,
                                                             Input_Folder_Name,
                                                             Output_Folder_Name,
                                                             Processor,
                                                             Start,
                                                             Finish,
                                                             Tool_Version_ID,
                                                             Completion_Code,
                                                             Completion_Message,
                                                             Evaluation_Code,
                                                             Evaluation_Message,
                                                             Holdoff_Interval_Minutes,
                                                             Next_Try,
                                                             Retry_Count )
                    SELECT @CaptureJobNew AS Job,
                           Step_Number,
                           Step_Tool,
                           CPU_Load,
                           Dependencies,
                           Case When State Not In (3,5,7) Then 7 Else State End As State,
                           Input_Folder_Name,
                           Output_Folder_Name,
                           'In-Silico' AS Processor,
                           Case When Start Is Null Then Null Else GetDate() End As Start,
                           Case When Finish Is Null Then Null Else GetDate() End As Finish,
                           1 AS Tool_Version_ID,
                           0 AS Completion_Code,
                           '' AS Completion_Message,
                           0 AS Evaluation_Code,
                           '' AS Evaluation_Message,
                           Holdoff_Interval_Minutes,
                           GetDate() AS Next_Try,
                           Retry_Count
                    FROM DMS_Capture.dbo.T_Job_Steps
                    WHERE Job = @CaptureJob
                    --
                    Select @myRowCount = @@RowCount, @myError = @@Error


                    INSERT INTO DMS_Capture.dbo.T_Job_Step_Dependencies (Job, Step_Number, Target_Step_Number,
                                                                         Condition_Test, Test_Value, Evaluated,
                                                                         Triggered, Enable_Only)
                    SELECT @CaptureJobNew AS Job,
                           Step_Number,
                           Target_Step_Number,
                           Condition_Test,
                           Test_Value,
                           Evaluated,
                           Triggered,
                           Enable_Only
                    FROM DMS_Capture.dbo.T_Job_Step_Dependencies
                    WHERE Job = @CaptureJob
                    --
                    Select @myRowCount = @@RowCount, @myError = @@Error


                End -- </d2>

            End -- </c2>


            If IsNull(@CaptureJobNew, 0) > 0
            Begin
                exec DMS_Capture.dbo.update_parameters_for_job @CaptureJobNew

                Declare @jobMessage varchar(255) = 'Created capture task job ' + Convert(varchar(12), @CaptureJobNew) + ' for dataset ' + @DatasetNew + ' by cloning job ' + Convert(varchar(12), @CaptureJob)
                Exec PostLogEntry 'Normal', @jobMessage, 'CloneDataset'

                Set @message = @message + '; ' + @jobMessage
            End


        End -- </b>

    END TRY
    BEGIN CATCH
        -- Error caught
        If @@TranCount > 0
            Rollback

        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'CloneDataset')
                exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 0,
                                        @ErrorNum = @myError output, @message = @message output

        Set @message = 'Exception: ' + @message
        print @message
        Goto Done
    END CATCH

Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CloneDataset] TO [DDL_Viewer] AS [dbo]
GO
