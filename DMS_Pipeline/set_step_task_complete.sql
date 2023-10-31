/****** Object:  StoredProcedure [dbo].[set_step_task_complete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_step_task_complete]
/****************************************************
**
**  Desc:
**      Mark job step as complete
**      Also updates CPU and memory info tracked by T_Machines
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          05/07/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          06/17/2008 dac - Added default values for completionMessage, evaluationCode, and evaluationMessage
**          10/05/2009 mem - Now allowing for CPU_Load to be null in T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/25/2012 mem - Expanded @organismDBName to varchar(128)
**          09/09/2014 mem - Added support for completion code 16 (CLOSEOUT_FILE_NOT_IN_CACHE)
**          09/12/2014 mem - Added PBF_Gen as a valid tool for completion code 16
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**                         - Now looking up machine using T_Local_Processors
**          10/30/2014 mem - Added support for completion code 17 (CLOSEOUT_UNABLE_TO_USE_MZ_REFINERY)
**          03/11/2015 mem - Now updating Completion_Message when completion code 16 or 17 is encountered more than once in a 24 hour period
**          04/17/2015 mem - Now using Uses_All_Cores for determining the number of cores to add back to CPUs_Available
**          11/18/2015 mem - Add Actual_CPU_Load
**          12/31/2015 mem - Added support for completion code 20 (CLOSEOUT_NO_DATA)
**          01/05/2016 mem - Tweak warning message for DeconTools results without data
**          06/17/2016 mem - Add missing space in log message
**          06/20/2016 mem - Include the completion code description in logged messages
**          12/02/2016 mem - Lookup step tools with shared results in T_Step_Tools when initializing @SharedResultStep
**          05/11/2017 mem - Add support for @completionCode 25 (RUNNING_REMOTE) and columns Next_Try and Retry_Count
**          05/12/2017 mem - Add parameter @remoteInfo, update Remote_Info_ID in T_Job_Steps, and update T_Remote_Info
**          05/15/2017 mem - Add parameter @remoteTimestamp, which is used to define the remote info file in the TaskQueuePath folder
**          05/18/2017 mem - Use get_remote_info_id to resolve @remoteInfo to @remoteInfoID
**          05/23/2017 mem - Add parameter @remoteProgress
**                           Update Remote_Finish if a remotely running job has finished (success or failure)
**          05/26/2017 mem - Add completion code 26 (FAILED_REMOTE), which leads to step state 16
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/12/2017 mem - Skip waiting step tools MSGF, IDPicker, and MSAlign_Quant when a DataExtractor step reports NO_DATA
**          10/17/2017 mem - Fix the warning logged when the DataExtractor reports no data
**          10/31/2017 mem - Add parameter @processorName
**          03/14/2018 mem - Use a shorter interval when updating Next_Try for remotely running jobs
**          03/29/2018 mem - Decrease @adjustedHoldoffInterval from 90 to 30 minutes
**          04/19/2018 mem - Add parameters @remoteStart and @remoteFinish
**          04/25/2018 mem - Stop setting Remote_Finish to the current date since @remoteFinish provides that info
**          06/12/2018 mem - Send @maxLength to append_to_text
**          10/18/2018 mem - Add output parameter @message
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**          12/14/2020 mem - Add support for completion code 18 (CLOSEOUT_SKIPPED_MZ_REFINERY)
**          03/12/2021 mem - Add support for completion codes 21 (CLOSEOUT_SKIPPED_MSXML_GEN) and 22 (CLOSEOUT_SKIPPED_MAXQUANT)
**                         - Expand @completionMessage and @evaluationMessage to varchar(512)
**          09/21/2021 mem - Add support for completion code 23 (CLOSEOUT_RESET_JOB_STEP)
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**          03/29/2023 mem - Add support for completion codes 27 and 28 (SKIPPED_DIA_NN_SPEC_LIB and WAITING_FOR_DIA_NN_SPEC_LIB)
**
*****************************************************/
(
    @job int,
    @step int,
    @completionCode int,
    @completionMessage varchar(512) = '',
    @evaluationCode int = 0,
    @evaluationMessage varchar(512) = '',
    @organismDBName varchar(128) = '',
    @remoteInfo varchar(900) = '',          -- Remote server info for jobs with @completionCode = 25
    @remoteTimestamp varchar(24) = null,    -- Timestamp for the .info file for remotely running jobs (e.g. "20170515_1532" in file Job1449504_Step03_20170515_1532.info)
    @remoteProgress real = null,
    @remoteStart datetime = null,           -- Time the remote processor actually started processing the job
    @remoteFinish datetime = null,          -- Time the remote processor actually finished processing the job
    @processorName varchar(128) = '',       -- Name of the processor setting the job as complete
    @message varchar(512) = '' output,
    @returnCode varchar(64) = '' output

)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @returnCode = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'set_step_task_complete', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- This table variable tracks step tools that should be skipped when a job step reports NO_DATA
    ---------------------------------------------------

    Declare @stepToolsToSkip table (Tool varchar(64))

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @job = IsNull(@job, 0)
    Set @step = IsNull(@step, 0)
    Set @processorName = IsNull(@processorName, '')

    Declare @jobStepDescription varchar(32) = 'job ' + Cast(@job as varchar(12)) + ', step ' + Cast(@step as varchar(9))
    Declare @jobStepDescriptionCapital varchar(32) = 'Job ' + Cast(@job as varchar(12)) + ', step ' + Cast(@step as varchar(9))

    ---------------------------------------------------
    -- Get current state of this job step
    ---------------------------------------------------
    --
    Declare @jobStepsProcessor varchar(64) = ''
    Declare @state tinyint = 0
    Declare @cpuLoad smallint = 0
    Declare @memoryUsageMB int = 0
    Declare @machine varchar(64) = ''
    Declare @stepTool varchar(64) = ''
    Declare @retryCount int = 0
    --
    SELECT @machine = LP.Machine,
           @cpuLoad = CASE WHEN Tools.Uses_All_Cores > 0 AND JS.Actual_CPU_Load = JS.CPU_Load
                           THEN IsNull(M.Total_CPUs, 1)
                           ELSE IsNull(JS.Actual_CPU_Load, 1)
                      END,
           @memoryUsageMB = IsNull(JS.Memory_Usage_MB, 0),
           @state = JS.State,
           @jobStepsProcessor = JS.Processor,
           @stepTool = JS.Tool,
           @retryCount = JS.Retry_Count
    FROM T_Job_Steps JS
         INNER JOIN T_Local_Processors LP
           ON LP.Processor_Name = JS.Processor
         INNER JOIN T_Step_Tools Tools
           ON Tools.Name = JS.Tool
         LEFT OUTER JOIN T_Machines M
           ON LP.Machine = M.Machine
    WHERE JS.Job = @job AND
          JS.Step = @step
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error getting machine name from T_Local_Processors using T_Job_Steps for ' + @jobStepDescription
        Exec post_log_entry 'Error', @message, 'set_step_task_complete'
        Goto Done
    End
    --
    If IsNull(@machine, '') = ''
    Begin
        Set @myError = 66
        Set @message = 'Could not find machine name in T_Local_Processors using T_Job_Steps; cannot mark ' + @jobStepDescription + ' complete for processor ' + @processorName
        Exec post_log_entry 'Error', @message, 'set_step_task_complete'

        Goto Done
    End
    --
    If @state <> 4
    Begin
        Set @myError = 67
        Set @message = @jobStepDescriptionCapital + ' is not in the correct state (4) to be marked complete by processor ' + @processorName + '; actual state is ' + Cast(@state as varchar(9))
        Exec post_log_entry 'Error', @message, 'set_step_task_complete'

        Goto Done
    End
    Else
    Begin
        If @processorName <> '' And @jobStepsProcessor <> @processorName
        Begin
            Set @myError = 68
            Set @message = @jobStepDescriptionCapital + ' is being processed by ' + @jobStepsProcessor + '; processor ' + @processorName + ' is not allowed to mark it as complete'
            Exec post_log_entry 'Error', @message, 'set_step_task_complete'

            Goto Done
        End
    End

    ---------------------------------------------------
    -- Determine completion state
    ---------------------------------------------------
    --
    Declare @stepState int
    Declare @resetSharedResultStep tinyint = 0
    Declare @handleSkippedStep tinyint = 0
    Declare @completionCodeDescription varchar(64) = 'Unknown completion reason'
    Declare @nextTry DateTime = GetDate()

    If @completionCode = 0
    Begin
        Set @stepState = 5 -- success
        Set @completionCodeDescription = 'Success'
    End
    Else
    Begin
        Set @stepState = 0

        If @completionCode = 16  -- CLOSEOUT_FILE_NOT_IN_CACHE
        Begin
            Set @stepState = 1 -- waiting
            Set @resetSharedResultStep = 1
            Set @completionCodeDescription = 'File not in cache'
        End

        If @completionCode = 17  -- CLOSEOUT_UNABLE_TO_USE_MZ_REFINERY
        Begin
            Set @stepState = 3 -- skipped
            Set @handleSkippedStep = 1
            Set @completionCodeDescription = 'Unable to use MZ_Refinery'
        End

        If @completionCode = 18  -- CLOSEOUT_SKIPPED_MZ_REFINERY
        Begin
            Set @stepState = 3 -- skipped
            Set @handleSkippedStep = 1
            Set @completionCodeDescription = 'Skipped MZ_Refinery'
        End

        If @completionCode = 21  -- CLOSEOUT_SKIPPED_MSXML_GEN
        Begin
            Set @stepState = 3 -- skipped
            Set @handleSkippedStep = 1
            Set @completionCodeDescription = 'Skipped MSXml_Gen'
        End

        If @completionCode = 22  -- CLOSEOUT_SKIPPED_MAXQUANT
        Begin
            Set @stepState = 3 -- skipped
            Set @handleSkippedStep = 1
            Set @completionCodeDescription = 'Skipped MaxQuant'
        End

        If @completionCode = 23  -- CLOSEOUT_RESET_JOB_STEP
        Begin
            Set @stepState = 2 -- New
            Set @handleSkippedStep = 0
            Set @completionCodeDescription = 'Insufficient memory or free disk space; retry'
        End

        If @completionCode = 20  -- CLOSEOUT_NO_DATA
        Begin
            Set @completionCodeDescription = 'No Data'

            -- Note that Formularity and NOMSI jobs that report completion code 20 are handled in auto_fix_failed_jobs

            If @stepTool IN ('Decon2LS_V2')
            Begin
                -- Treat "No_data" results for DeconTools as a completed job step but skip the next step if it is LCMSFeatureFinder
                Set @stepState = 5 -- Complete

                INSERT INTO @stepToolsToSkip(Tool) VALUES ('LCMSFeatureFinder')

                Set @message = 'Warning, ' + @jobStepDescription + ' has no results in the DeconTools _isos.csv file; either it is a bad dataset or analysis parameters are incorrect'
                Exec post_log_entry 'Error', @message, 'set_step_task_complete'
            End

            If @stepTool IN ('DataExtractor')
            Begin
                -- Treat "No_data" results for the DataExtractor as a completed job step but skip later job steps that match certain tools
                Set @stepState = 5 -- Complete

                INSERT INTO @stepToolsToSkip(Tool) VALUES ('MSGF'),('IDPicker'),('MSAlign_Quant')

                Set @message = 'Warning, ' + @jobStepDescription + ' has an empty synopsis file (no results above threshold); either it is a bad dataset or analysis parameters are incorrect'
                Exec post_log_entry 'Error', @message, 'set_step_task_complete'
            End
        End

        If    @completionCode = 25  -- RUNNING_REMOTE
           OR @completionCode = 28  -- WAITING_FOR_DIA_NN_SPEC_LIB
        Begin
            If @completionCode = 25
            Begin
                Set @stepState = 9  -- Running_Remote
                Set @completionCodeDescription = 'Running remote'
            End
            Else If @completionCode = 28
            Begin
                Set @stepState = 11 -- Waiting_for_File
                Set @completionCodeDescription = 'Waiting for DIA-NN spectral library to be generated by another job'
            End
            Else
            Begin
                Set @stepState = 6  -- Failed
                Set @completionCodeDescription = 'Unrecognized completion code'
            End

            Declare @holdoffIntervalMinutes int

            SELECT @holdoffIntervalMinutes = Holdoff_Interval_Minutes
            FROM T_Step_Tools
            WHERE [Name] = @stepTool

            If IsNull(@holdoffIntervalMinutes, 0) < 1
                Set @holdoffIntervalMinutes = 3

            Set @retryCount = @retryCount + 1
            If (@retryCount < 1)
                Set @retryCount = 1

            -- Wait longer after each check of remote status, with a maximum holdoff interval of 30 minutes
            -- If @holdoffIntervalMinutes is 5, will wait 5 minutes initially, then wait 6 minutes after the next check, then 7, etc.
            Declare @adjustedHoldoffInterval int = @holdoffIntervalMinutes + (@retryCount - 1)

            If @adjustedHoldoffInterval > 30
                Set @adjustedHoldoffInterval = 30

            If @remoteProgress > 0
            Begin
                -- Bump @adjustedHoldoffInterval down based on @remoteProgress; examples:
                -- If @adjustedHoldoffInterval is 20 and @remoteProgress is 10, change @adjustedHoldoffInterval to 19
                -- If @adjustedHoldoffInterval is 20 and @remoteProgress is 50, change @adjustedHoldoffInterval to 15
                -- If @adjustedHoldoffInterval is 20 and @remoteProgress is 90, change @adjustedHoldoffInterval to 11
                Set @adjustedHoldoffInterval = @adjustedHoldoffInterval - @adjustedHoldoffInterval * @remoteProgress / 200
            End

            Set @nextTry = DateAdd(minute, @adjustedHoldoffInterval, GetDate())
        End

        If @completionCode = 26  -- FAILED_REMOTE
        Begin
            Set @stepState = 16  -- Failed_Remote
            Set @completionCodeDescription = 'Failed remote'
        End

        If @completionCode = 27  -- SKIPPED_DIA_NN_SPEC_LIB
        Begin
            Set @stepState = 3 -- skipped
            Set @handleSkippedStep = 1
            Set @completionCodeDescription = 'Skipped DIA-NN spectral library creation'
        End

        If @stepState = 0
        Begin
            Set @stepState = 6 -- fail
            Set @completionCodeDescription = 'General error'
        End
    End

    ---------------------------------------------------
    -- Set up transaction parameters
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'set_step_task_complete'

    -- Start transaction
    Begin transaction @transName

    ---------------------------------------------------
    -- Update job step
    ---------------------------------------------------
    --
    UPDATE T_Job_Steps
    Set    State = @stepState,
           Finish = Getdate(),
           Completion_Code = @completionCode,
           Completion_Message = @completionMessage,
           Evaluation_Code = @evaluationCode,
           Evaluation_Message = @evaluationMessage,
           Next_Try = @nextTry,
           Retry_Count = @retryCount,
           Remote_Timestamp = @remoteTimestamp,
           Remote_Progress = @remoteProgress,
           Remote_Start = @remoteStart,
           Remote_Finish = @remoteFinish
    WHERE Job = @job AND
          Step = @step
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error updating step table'
        Goto Done
    End

    ---------------------------------------------------
    -- Update machine loading for this job step's processor's machine
    ---------------------------------------------------
    --
    UPDATE T_Machines
    Set CPUs_Available = CPUs_Available + @cpuLoad,
        Memory_Available = Memory_Available + @memoryUsageMB
    WHERE Machine = @machine
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error updating CPU loading'
        Goto Done
    End

    ---------------------------------------------------
    -- Update T_Remote_Info if appropriate
    ---------------------------------------------------
    --
    If IsNull(@remoteInfo, '') <> ''
    Begin
        Declare @remoteInfoID int = 0

        Exec @remoteInfoID = get_remote_info_id @remoteInfo

        If IsNull(@remoteInfoID, 0) = 0
        Begin
            ---------------------------------------------------
            -- Something went wrong; @remoteInfo wasn't found in T_Remote_Info
            -- and we were unable to add it with the Merge statement
            ---------------------------------------------------

            UPDATE T_Job_Steps
            SET Remote_Info_ID = 1
            WHERE Job = @job AND
                Step = @step AND
                Remote_Info_ID IS NULL
        End
        Else
        Begin

            UPDATE T_Job_Steps
            SET Remote_Info_ID = @remoteInfoID,
                Remote_Progress = CASE WHEN @stepState = 5 THEN 100 ELSE Remote_Progress END
            WHERE Job = @job AND
                  Step = @step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            UPDATE T_Remote_Info
            SET Most_Recent_Job = @Job,
                Last_Used = GetDate()
            WHERE Remote_Info_ID = @remoteInfoID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

    End

    If @resetSharedResultStep <> 0
    Begin
        -- Possibly reset the the DTA_Gen, DTA_Refinery, Mz_Refinery,
        -- MSXML_Gen, MSXML_Bruker, PBF_Gen, or ProMex step just upstream from this step

        Declare @SharedResultStep int = -1

        SELECT TOP 1 @SharedResultStep = Step
        FROM T_Job_Steps
        WHERE Job = @job AND
              Step < @step AND
              Tool IN (SELECT [Name] FROM T_Step_Tools WHERE Shared_Result_Version > 0)
        ORDER BY Step DESC

        If IsNull(@SharedResultStep, -1) < 0
        Begin
            Set @message = 'Job ' + Cast(@job as varchar(12)) +
                           ' does not have a Mz_Refinery, MSXML_Gen, MSXML_Bruker, PBF_Gen, or ProMex step prior to step ' + Cast(@step as varchar(12)) +
                           '; CompletionCode ' + Cast(@completionCode as varchar(12)) + ' (' + @completionCodeDescription + ') is invalid'

            Exec post_log_entry 'Error', @message, 'set_step_task_complete'
            Goto CommitTran
        End

        Set @message = 'Re-running step ' + Cast(@SharedResultStep as varchar(12)) + ' for job ' + Cast(@job as varchar(12)) +
                       ' because step ' + Cast(@step as varchar(12)) +
                       ' reported completion code ' + Cast(@completionCode as varchar(12)) + ' (' + @completionCodeDescription + ')'

        If Exists ( SELECT *
                    FROM T_Log_Entries
                    WHERE Message = @message And
                          type = 'Normal' And
                          Entered >= DateAdd(day, -1, GetDate())
             )
        Begin
            Set @message = 'has already reported completion code ' + Cast(@completionCode as varchar(12)) + ' (' + @completionCodeDescription + ')' +
                           ' within the last 24 hours'

            UPDATE T_Job_Steps
            SET State = 7,        -- Holding
                Completion_Message = dbo.append_to_text(Completion_Message, @message, 0, '; ', 256)
            WHERE Job = @job AND
                  Step = @step

            Set @message = 'Step ' + Cast(@step as varchar(12)) + ' in job ' + Cast(@job as varchar(12)) + ' ' +
                           @message + '; will not reset step ' + Cast(@SharedResultStep as varchar(12)) +
                           ' again because this likely represents a problem; this step is now in state "holding"'

            Exec post_log_entry 'Error', @message, 'set_step_task_complete'

            Goto CommitTran
        End

        Exec post_log_entry 'Normal', @message, 'set_step_task_complete'

        -- Reset shared results step just upstream from this step
        --
        UPDATE T_Job_Steps
        Set State = 2,                  -- 2=Enabled
            Tool_Version_ID = 1,        -- 1=Unknown
            Next_Try = GetDate(),
            Remote_Info_ID = 1          -- 1=Unknown
        WHERE Job = @job AND
              Step = @SharedResultStep And
              Not State IN (4, 9)       -- Do not reset the step if it is already running

        UPDATE T_Job_Step_Dependencies
        SET Evaluated = 0,
            Triggered = 0
        WHERE Job = @job AND
              Step = @step

        UPDATE T_Job_Step_Dependencies
        SET Evaluated = 0,
            Triggered = 0
        WHERE Job = @job AND
              Target_Step = @SharedResultStep

    End

    If @handleSkippedStep <> 0
    Begin
        -- This step was skipped
        -- Update T_Job_Step_Dependencies

        Declare @newTargetStep int = -1
        Declare @nextStep int = -1

        SELECT @newTargetStep = Target_Step
        FROM T_Job_Step_Dependencies
        WHERE Job = @job AND
              Step = @step

        SELECT @nextStep = Step
        FROM T_Job_Step_Dependencies
        WHERE Job = @job AND
              Target_Step = @step AND
              ISNULL(Condition_Test, '') <> 'Target_Skipped'

        If @newTargetStep > -1 And @newTargetStep > -1
        Begin
            UPDATE T_Job_Step_Dependencies
            SET Target_Step = @newTargetStep
            WHERE Job = @job AND Step = @nextStep

            Set @message = 'Updated job step dependencies for job ' + Cast(@job as varchar(9)) + ' since step ' + Cast(@step as varchar(9)) + ' has been skipped'
            Exec post_log_entry 'Normal', @message, 'set_step_task_complete'
        End

    End

    If Exists (SELECT * FROM @stepToolsToSkip)
    Begin
        -- Skip specific waiting step tools for this job
        --
        UPDATE T_Job_Steps
        SET State = 3
        FROM T_Job_Steps JS
             INNER JOIN @stepToolsToSkip ToolsToSkip
               ON JS.Tool = ToolsToSkip.Tool
        WHERE JS.Job = @job AND
              JS.State = 1

    End

CommitTran:

    -- Update was successful
    commit transaction @transName

    ---------------------------------------------------
    -- Update fasta file name (if one was passed in from the analysis tool manager)
    ---------------------------------------------------
    --
    If IsNull(@organismDBName,'') <> ''
    Begin
        UPDATE T_Jobs
        Set Organism_DB_Name = @organismDBName
        WHERE Job = @job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error updating organism DB name'
            Goto Done
        End
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Set @returnCode = Cast(@myError As varchar(64))
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[set_step_task_complete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_step_task_complete] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_step_task_complete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[set_step_task_complete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_step_task_complete] TO [svc-dms] AS [dbo]
GO
