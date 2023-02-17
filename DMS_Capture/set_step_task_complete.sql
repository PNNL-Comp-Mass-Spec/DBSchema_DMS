/****** Object:  StoredProcedure [dbo].[SetStepTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetStepTaskComplete]
/****************************************************
**
**  Desc:   Make entry in step completion table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/30/2009 grk - Made @message an output parameter
**          01/15/2010 grk - Set step state back to enable If retrying
**          05/05/2011 mem - Now leaving Next_Try unchanged If state = 5 (since @completionCode = 0)
**          02/08/2012 mem - Added support for @evaluationCode = 3 when @completionCode = 0
**          09/10/2013 mem - Added support for @evaluationCode being 4, 5, or 6
**          09/11/2013 mem - Now auto-adjusting the holdoff interval for ArchiveVerify job steps
**          09/18/2013 mem - Added support for @evaluationCode = 7 (MyEMSL is already up to date)
**          09/19/2013 mem - Now skipping ArchiveStatusCheck when skipping ArchiveVerify
**          10/16/2013 mem - Now updating Evaluation_Message when skipping the ArchiveVerify step
**          09/24/2014 mem - No longer looking up machine
**          11/03/2013 mem - Added support for @evaluationCode = 8 (failed, do not retry)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/21/2017 mem - Added support for @evaluationCode = 9 (tool skipped)
**          12/04/2017 mem - Rename variables and add logic checks
**          06/14/2018 mem - Call S_PostEmailAlert if a reporter ion m/z validation error or warning is detected
**          07/30/2018 mem - Include dataset name when calling S_PostEmailAlert
**          08/09/2018 mem - Expand @completionMessage to varchar(512)
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**          08/21/2020 mem - Set @HoldoffIntervalMinutes to 60 (or higher) if @retryCount is 0
**
*****************************************************/
(
    @job int,
    @step int,
    @completionCode int,
    @completionMessage varchar(512) = '',
    @evaluationCode int = 0,
    @evaluationMessage varchar(256) = '',
    @message varchar(512) = '' output,
    @returnCode varchar(64) = '' output
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(1024)

    Set @message = ''
    Set @returnCode = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'SetStepTaskComplete', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Get current state of this job step
    ---------------------------------------------------
    --
    Declare @processor varchar(64) = ''
    Declare @initialState tinyint = 0
    Declare @retryCount smallint = 0
    Declare @HoldoffIntervalMinutes int = 30
    Declare @nextTry datetime = GetDate()
    Declare @stepTool varchar(64)
    Declare @outputFolderName varchar(255)
    Declare @datasetID int
    Declare @datasetName varchar(128)

    SELECT @initialState = JS.State,
           @processor = JS.Processor,
           @retryCount = JS.Retry_Count,
           @HoldoffIntervalMinutes = JS.Holdoff_Interval_Minutes,
           @nextTry = JS.Next_Try,
           @stepTool = JS.Step_Tool,
           @outputFolderName = JS.Output_Folder_Name,
           @datasetID = J.Dataset_ID,
           @datasetName = J.Dataset
    FROM T_Job_Steps JS
         INNER JOIN T_Local_Processors LP
           ON LP.Processor_Name = JS.Processor
         INNER JOIN T_Jobs J
           ON JS.Job = J.Job
    WHERE (JS.Job = @job) AND
          (JS.Step_Number = @step)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error getting state of current job'
        goto Done
    End
    --
    If @initialState <> 4
    Begin
        set @myError = 67
        set @message = 'Job step is not in correct state to be completed; job ' + convert(varchar(12), @job) +
                       ', step ' + convert(varchar(12), @step) +
                       ', actual state ' + convert(varchar(6), @initialState)  +
                       '; expected state 4'
        goto Done
    End

    ---------------------------------------------------
    -- Determine completion state
    -- Initially assume new state will be 5 (success)
    ---------------------------------------------------
    --
    Declare @newStepState int = 5

    If @completionCode = 0 And @evaluationCode <> 9
    Begin
        -- Completed successfully
        Set @newStepState = 5
    End
    Else
    Begin
        -- Either completion code is non-zero, or the step was skipped (eval-code 9)

        If @evaluationCode = 8      -- EVAL_CODE_FAILURE_DO_NOT_RETRY
        Begin
            -- Failed
            Set @newStepState = 6
            Set @retryCount = 0
        End

        If @evaluationCode = 9      -- EVAL_CODE_SKIPPED
        Begin
            -- Skipped
            Set @newStepState = 3
        End

        If Not @newStepState IN (3, 6) And (@retryCount > 0 Or @evaluationCode = 3)
        Begin
            If @initialState = 4
            Begin
                -- Retry the step
                Set @newStepState = 2
            End

            If @retryCount > 0
            Begin
                Set @retryCount = @retryCount - 1   -- decrement retry count
            End

            If @evaluationCode = 3
            Begin
                -- The captureTaskManager returns 3 (EVAL_CODE_NETWORK_ERROR_RETRY_CAPTURE) when a network error occurs during capture
                -- Auto-retry the capture again (even if @retryCount is 0)
                Set @nextTry = DATEADD(minute, 15, GETDATE())
            End
            Else
            Begin
                If @StepTool = 'ArchiveVerify' AND @retryCount > 0
                Begin
                    SET @HoldoffIntervalMinutes = CASE
                            WHEN @HoldoffIntervalMinutes < 5 THEN 5
                                                      WHEN @HoldoffIntervalMinutes < 10 THEN 10
                                                      WHEN @HoldoffIntervalMinutes < 15 THEN 15
                                                      WHEN @HoldoffIntervalMinutes < 30 THEN 30
                                                      ELSE @HoldoffIntervalMinutes
                                                  END
                End

                If @retryCount = 0 AND @HoldoffIntervalMinutes < 60
                    Set @HoldoffIntervalMinutes = 60

                If @newStepState <> 5
                    set @nextTry = DATEADD(minute, @HoldoffIntervalMinutes, GETDATE())
            End

        End
        Else
        Begin
            If Not @newStepState IN (3, 6)
            Begin
                -- Failed
                Set @newStepState = 6
            End
        End
    End

    ---------------------------------------------------
    -- Set up transaction parameters
    ---------------------------------------------------
    --
    Declare @transName varchar(32)
    set @transName = 'SetStepTaskComplete'

    -- Start transaction
    Begin transaction @transName

    ---------------------------------------------------
    -- Update job step
    ---------------------------------------------------
    --
    UPDATE T_Job_Steps
    SET    State = @newStepState,
           Finish = Getdate(),
           Completion_Code = @completionCode,
           Completion_Message = @completionMessage,
           Evaluation_Code = @evaluationCode,
           Evaluation_Message = @evaluationMessage,
           Retry_Count = @retryCount,
           Holdoff_Interval_Minutes = @HoldoffIntervalMinutes,
           Next_Try = @nextTry
    WHERE  (Job = @job)
    AND (Step_Number = @step)
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        set @message = 'Error updating step table'
        goto Done
    End

    If @stepTool In ('ArchiveUpdate', 'ArchiveUpdateTest', 'DatasetArchive') AND @evaluationCode IN (6, 7)
    Begin
        -- If @evaluationCode = 6, we copied data to Aurora via FTP but did not upload to MyEMSL
        -- If @evaluationCode = 7, we uploaded data to MyEMSL, but there were no new files to upload, so there is nothing to verify
        -- In either case, skip the ArchiveVerify and ArchiveStatusCheck steps for this job (if they exist)

        UPDATE T_Job_Steps
        SET State = 3,
            Completion_Code = 0,
            Completion_Message = '',
            Evaluation_Code = 0,
            Evaluation_Message =
              CASE
                  WHEN @evaluationCode = 6 THEN 'Skipped since MyEMSL upload was skipped'
                  WHEN @evaluationCode = 7 THEN 'Skipped since MyEMSL files were already up-to-date'
                  ELSE 'Skipped for unknown reason'
              END
        WHERE Job = @job AND
              Step_Tool IN ('ArchiveVerify', 'ArchiveStatusCheck') AND
              NOT State IN (4, 5, 7)

    End

    -- Update was successful
    commit transaction @transName

    ---------------------------------------------------
    -- Check for reporter ion m/z validation warnings or errors
    ---------------------------------------------------

    If @completionMessage Like '%Over%of the % spectra have a minimum m/z value larger than the required minimum%'
    Begin
        Set @msg = 'Dataset ' + @datasetName + ' (ID ' + Cast(@datasetID  As varchar(12)) + '): ' + @completionMessage
        Exec S_PostEmailAlert 'Error', @msg, 'SetStepTaskComplete', @recipients='admins', @postMessageToLogEntries=1
    End
    Else If @completionMessage Like '%Some of the % spectra have a minimum m/z value larger than the required minimum%' Or
            @completionMessage Like '%reporter ion peaks likely could not be detected%'
    Begin
        Set @msg = 'Dataset ' + @datasetName + ' (ID ' + Cast(@datasetID  As varchar(12)) + '): ' + @completionMessage
        Exec S_PostEmailAlert 'Warning', @msg, 'SetStepTaskComplete', @recipients='admins', @postMessageToLogEntries=1
    End

    ---------------------------------------------------
    -- Possibly update MyEMSL State values
    ---------------------------------------------------
    --
    If @completionCode = 0
    Begin

        -- @evaluationCode = 4 means Submitted to MyEMSL
        -- @evaluationCode = 5 means Verified in MyEMSL

        If @stepTool Like '%Archive%' And @evaluationCode IN (4, 5)
        Begin
            -- Update the MyEMSLState values
            Declare @MyEMSLStateNew tinyint = 0

            If @evaluationCode = 4
                Set @MyEMSLStateNew = 1

            If @evaluationCode = 5
                Set @MyEMSLStateNew = 2

            exec S_UpdateMyEMSLState @datasetID, @outputFolderName, @MyEMSLStateNew

        End
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Set @returnCode = Cast(@myError As varchar(64))
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
