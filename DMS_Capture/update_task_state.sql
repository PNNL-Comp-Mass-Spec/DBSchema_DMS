/****** Object:  StoredProcedure [dbo].[update_task_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_task_state]
/****************************************************
**
**  Desc:
**      Based on step state, look for jobs that have been completed,
**      or have entered the "in progress" state,
**      and update state of job locally and dataset in DMS accordingly
**
**      First step:
**        Evaluate state of steps for jobs that are in new or busy state,
**        or in transient state of being resumed or reset, and determine what new
**        broker job state should be, and accumulate list of jobs whose new state is different than their
**        current state.  Only steps for jobs in New or Busy state are considered.
**
**    Current             Current                                     New
**    Broker              Job                                         Broker
**    Job                 Steps                                       Job
**    State               States                                      State
**    -----               -------                                     ---------
**    New or Busy         One or more steps failed                    Failed
**
**    New or Busy         All steps complete (or skipped)             Complete
**
**    New,Busy,Resuming   One or more steps busy                      In Progress
**
**    Failed              All steps complete (or skipped)             Complete, though only if max Job Step completion time is greater than Finish time in T_Tasks
**
**    Failed              All steps waiting/enabled/In Progress       In Progress
**
**
**      Second step:
**        Go through list of jobs from first step whose current state must be changed and
**        take action in broker and DMS as noted.
**
**  Auth:   grk
**  Date:   12/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/04/2010 grk - Bypass DMS if dataset ID = 0
**          05/08/2010 grk - Update DMS sample prep if dataset ID = 0
**          05/05/2011 mem - Now updating job state from Failed to Complete if all job steps are now complete and at least one of the job steps finished later than the Finish time in T_Tasks
**          11/14/2011 mem - Now using >= instead of > when looking for jobs to change from Failed to Complete because all job steps are now complete or skipped
**          01/16/2012 mem - Added overflow checks when using DateDiff to compute @ProcessingTimeMinutes
**          11/05/2014 mem - Now looking for failed jobs that should be changed to state 2 in T_Tasks
**          11/11/2014 mem - Now looking for jobs that are in progress, yet T_Dataset_Archive in DMS5 lists the archive or archive update operation as failed
**          11/04/2016 mem - Now looking for jobs that are failed, yet should be listed as in progress
**                         - Only call copy_task_to_history if the new job state is 3 or 5 and if not changing the state from 5 to 2
**                         - Add parameter @infoOnly
**                         - No longer computing @ProcessingTimeMinutes since not stored in any table
**          01/23/2017 mem - Fix logic bug involving call to copy_task_to_history
**          06/13/2018 mem - Add comments regarding update_dms_file_info_xml and T_Dataset_Info
**          06/01/2020 mem - Add support for step state 13 (Inactive)
**          02/03/2023 bcg - Update column names for V_DMS_Dataset_Archive_Status
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @bypassDMS tinyint = 0,
    @message varchar(512) output,
    @maxJobsToProcess int = 0,
    @loopingUpdateInterval int = 5,        -- Seconds between detailed logging while looping through the dependencies
    @infoOnly tinyint = 0
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int =0

    Declare @job int
    Declare @oldJobStateInBroker int
    Declare @newJobStateInBroker int
    --
    Declare @curJob int = 0
    --
    Declare @resultsFolderName varchar(64) = ''
    --

    Declare @JobPropagationMode int = 0

    Declare @done tinyint
    Declare @JobCountToProcess int
    Declare @JobsProcessed int
    Declare @script varchar(64)

    Declare @StartMin datetime
    Declare @FinishMax datetime
    Declare @UpdateCode int

    Declare @StartTime datetime
    Declare @LastLogTime datetime
    Declare @StatusMessage varchar(512)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    Set @bypassDMS = IsNull(@bypassDMS, 0)
    Set @message = ''
    Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

    Set @StartTime = GetDate()
    Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
    If @LoopingUpdateInterval < 2
        Set @LoopingUpdateInterval = 2

    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Table variable to hold state changes
    ---------------------------------------------------
    CREATE TABLE #Tmp_ChangedJobs (
        Job int,
        OldState int,
        NewState int,
        Results_Folder_Name varchar(128),
        Dataset_Name varchar(128),
        Dataset_ID int,
        Script varchar(64),
        Storage_Server varchar(128),
        Start_New DateTime null,
        Finish_New Datetime null
    )

    CREATE INDEX #IX_Tmp_ChangedJobs_Job ON #Tmp_ChangedJobs (Job)

    ---------------------------------------------------
    -- Determine what current state of active jobs should be
    -- and get list of the ones that need be changed
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_ChangedJobs (
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset_Name,
        Dataset_ID,
        Script,
        Storage_Server
    )
    SELECT
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset,
        Dataset_ID,
        Script,
        Storage_Server
    FROM
    (
        -- Look at the state of steps for active or failed jobs
        -- and determine what the new state of each job should be
        SELECT
          J.Job,
          J.Dataset_ID,
          J.State as OldState,
          J.Results_Folder_Name,
          J.Storage_Server,
          CASE
            WHEN JS_Stats.Failed > 0 THEN 5                     -- New job state: Failed
            WHEN JS_Stats.FinishedOrSkipped = Total THEN 3      -- New job state: Complete
            WHEN JS_Stats.StartedFinishedOrSkipped > 0 THEN 2   -- New job state: In Progress
            Else J.State
          End AS NewState,
          J.Dataset,
          J.Script
        FROM
          (
            -- Count the number of steps for each job
            -- that are in the busy, finished, or failed states
            -- (for jobs that are in new, in progress, or resuming state)
            SELECT
                JS.Job,
                COUNT(*) AS Total,
                SUM(CASE
                    WHEN JS.State IN (3, 4, 5, 13) THEN 1
                    Else 0
                    End) AS StartedFinishedOrSkipped,
                SUM(CASE
                    WHEN JS.State IN (6) THEN 1
                    Else 0
                    End) AS Failed,
                SUM(CASE
                    WHEN JS.State IN (3, 5, 13) THEN 1
                    Else 0
                    End) AS FinishedOrSkipped
            FROM T_Task_Steps JS
                 INNER JOIN T_Tasks J
                   ON JS.Job = J.Job
            WHERE (J.State IN (1,2,5,20))    -- Current job state: New, in progress, failed, or resuming
            GROUP BY JS.Job, J.State
           ) AS JS_Stats
           INNER JOIN T_Tasks AS J
             ON JS_Stats.Job = J.Job
    ) UpdateQ
    WHERE UpdateQ.OldState <> UpdateQ.NewState
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    Set @JobCountToProcess = @myRowCount

    ---------------------------------------------------
    -- Find DatasetArchive and ArchiveUpdate jobs that are
    -- in progress, but for which DMS thinks that
    -- the operation has failed
    ---------------------------------------------------

    INSERT INTO #Tmp_ChangedJobs (
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset_Name,
        Dataset_ID,
        Script,
        Storage_Server
    )
    SELECT J.Job,
           J.State As OldState,
           J.State As NewState,
           J.Results_Folder_Name,
           J.Dataset,
           J.Dataset_ID,
           J.Script,
           J.Storage_Server
    FROM T_Tasks J
         INNER JOIN V_DMS_Dataset_Archive_Status DAS
           ON J.Dataset_ID = DAS.Dataset_ID
         LEFT OUTER JOIN #Tmp_ChangedJobs TargetTable
           ON J.Job = TargetTable.Job
    WHERE TargetTable.Job Is Null AND
          ( (J.Script = 'DatasetArchive' AND J.State = 2 AND DAS.Archive_State_ID = 6) OR
            (J.Script = 'ArchiveUpdate'  AND J.State = 2 AND DAS.Archive_Update_State_ID = 5) )
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    Set @JobCountToProcess = @JobCountToProcess + @myRowCount

    ---------------------------------------------------
    -- Find failed jobs that do not have any failed job steps
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_ChangedJobs(
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset_Name,
        Dataset_ID,
        Script,
        Storage_Server )

    SELECT Job,
           State AS OldState,
           2 AS NewState,
           Results_Folder_Name,
           Dataset,
           Dataset_ID,
           Script,
           Storage_Server
    FROM T_Tasks
    WHERE State = 5 AND
          (Job IN ( SELECT Job FROM T_Task_Steps WHERE State IN (2, 3, 4, 5, 13))) AND
          (NOT Job IN (SELECT Job FROM T_Task_Steps WHERE State = 6)) AND
          (NOT Job In (SELECT Job FROM #Tmp_ChangedJobs))
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    Set @JobCountToProcess = @JobCountToProcess + @myRowCount

    ---------------------------------------------------
    -- Loop through jobs whose state has changed
    -- and update local state and DMS state
    ---------------------------------------------------
    --
    Set @done = 0
    Set @JobsProcessed = 0
    Set @LastLogTime = GetDate()
    SET @script = ''
    Declare
        @datasetName VARCHAR(128),
        @datasetID INT,
        @storageServerName VARCHAR(128)
    --
    While @done = 0
    Begin -- <a>
        Set @job = 0
        --
        SELECT TOP 1 @job = Job,
                     @curJob = Job,
                     @oldJobStateInBroker = OldState,
                     @newJobStateInBroker = NewState,
                     @resultsFolderName = Results_Folder_Name,
                     @script = Script,
                     @datasetName = Dataset_Name,
                     @datasetID = Dataset_ID,
                     @storageServerName = Storage_Server
        FROM #Tmp_ChangedJobs
        WHERE Job > @curJob
        ORDER BY Job
         --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @job = 0
            Set @done = 1
        Else
        Begin -- <b>

            ---------------------------------------------------
            -- Examine the steps for this job to determine actual start/End times
            ---------------------------------------------------

            Set @StartMin = Null
            Set @FinishMax = Null

            -- Note: You can use the following query to update @StartMin and @FinishMax
            -- However, when a job has some completed steps and some not yet started, this query
            --  will trigger the warning "Null value is eliminated by an aggregate or other Set operation"
            -- The warning can be safely ignored, but tends to bloat up the Sql Server Agent logs,
            --  so we are instead populating @StartMin and @FinishMax separately
            /*
            SELECT @StartMin = Min(Start),
                   @FinishMax = Max(Finish)
            FROM T_Task_Steps
            WHERE (Job = @job)
             --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            */

            -- Update @StartMin
            -- Note that if no steps have started yet, then @StartMin will be Null
            SELECT @StartMin = Min(Start)
            FROM T_Task_Steps
            WHERE (Job = @job) AND Not Start Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            -- Update @FinishMax
            -- Note that if no steps have finished yet, then @FinishMax will be Null
            SELECT @FinishMax = Max(Finish)
            FROM T_Task_Steps
            WHERE (Job = @job) AND Not Finish Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            ---------------------------------------------------
            -- Deprecated:
            -- Examine the steps for this job to determine total processing time
            -- Steps with the same Step Tool name are assumed to be steps that can run in parallel;
            --   therefore, we use a Max(ProcessingTime) on steps with the same Step Tool name
            -- We use ABS(DATEDIFF(HOUR, start, xx)) to avoid overflows produced with
            --   DATEDIFF(SECOND, Start, xx) when Start and Finish are widely different
            ---------------------------------------------------
            /*
            SELECT @ProcessingTimeMinutes = SUM(SecondsElapsedMax) / 60.0
            FROM ( SELECT Tool,
                          MAX(ISNULL(SecondsElapsed1, 0) + ISNULL(SecondsElapsed2, 0)) AS SecondsElapsedMax
                   FROM ( SELECT Tool,
                                 CASE
                                     WHEN ABS(DATEDIFF(HOUR, start, finish)) > 100000 THEN 360000000
                                     ELSE DATEDIFF(SECOND, Start, Finish)
                                 END AS SecondsElapsed1,
                                 CASE
                                     WHEN (NOT Start IS NULL) AND
                                          Finish IS NULL THEN
                                            CASE
                                                WHEN ABS(DATEDIFF(HOUR, start, GETDATE())) > 100000 THEN 360000000
                                                ELSE DATEDIFF(SECOND, Start, getdate())
                                            END
                                     ELSE NULL
                                 END AS SecondsElapsed2
                          FROM T_Task_Steps
                          WHERE (Job = @job)
                          ) StatsQ
                   GROUP BY Tool
                   ) StepToolQ
             --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @ProcessingTimeMinutes = IsNull(@ProcessingTimeMinutes, 0)
            */

            If @infoOnly > 0
            Begin
                UPDATE #Tmp_ChangedJobs
                SET Start_New =
                        CASE
                        WHEN @newJobStateInBroker >= 2 THEN IsNull(@StartMin, GetDate())    -- Job state is 2 or higher
                        ELSE Src.Start
                        END,
                    Finish_New =
                        CASE
                        WHEN @newJobStateInBroker IN (3, 5) THEN @FinishMax                 -- Job state is 3=Complete or 5=Failed
                        ELSE Src.Finish
                        END
                FROM #Tmp_ChangedJobs Target
                     INNER JOIN T_Tasks Src
                       ON Target.Job = Src.Job
                WHERE Target.Job = @job
                 --
                SELECT @myError = @@error, @myRowCount = @@rowcount

            End
            Else
            Begin
                ---------------------------------------------------
                -- Update local job state and timestamp (If appropriate)
                ---------------------------------------------------
                --
                UPDATE T_Tasks
                Set
                    State = @newJobStateInBroker,
                    Start =
                        CASE
                        WHEN @newJobStateInBroker >= 2 THEN IsNull(@StartMin, GetDate())    -- Job state is 2 or higher
                        Else Start
                        End,
                    Finish =
                        CASE
                        WHEN @newJobStateInBroker IN (3, 5) THEN @FinishMax                 -- Job state is 3=Complete or 5=Failed
                        Else Finish
                        End
                WHERE Job = @job
                 --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End

            ---------------------------------------------------
            -- Make changes to DMS if we are enabled to do so
            -- update_dms_dataset_state will also call update_dms_file_info_xml to push the data into T_Dataset_Info
            -- If a duplicate dataset is found, update_dms_dataset_state will change this job's state to 14 in T_Tasks
            ---------------------------------------------------
            --
            If @bypassDMS = 0 AND @datasetID <> 0
            Begin -- <c>

                If @infoOnly > 0
                Begin
                    Print 'Exec update_dms_dataset_state @job=' + Cast(@job as varchar(12)) + ', @newJobStateInBroker=' + Cast(@newJobStateInBroker as varchar(6))
                End
                Else
                Begin
                    Exec @myError = update_dms_dataset_state
                                        @job,
                                        @datasetName,
                                        @datasetID,
                                        @Script,
                                        @storageServerName,
                                        @newJobStateInBroker,
                                        @message output

                    If @myError <> 0
                        Exec post_log_entry 'Error', @message, 'update_task_state'
                End

            End -- </c>

            If @bypassDMS = 0 AND @datasetID = 0
            Begin -- <d>

                If @infoOnly > 0
                Begin
                    Print 'Exec update_dms_prep_state @job=' + Cast(@job as varchar(12)) + ', @newJobStateInBroker=' + Cast(@newJobStateInBroker as varchar(6))
                End
                Else
                Begin
                    Exec @myError = update_dms_prep_state
                                @job,
                                @Script,
                                @newJobStateInBroker,
                                @message output

                    If @myError <> 0
                        Exec post_log_entry 'Error', @message, 'update_task_state'
                End
            End -- </d>

            ---------------------------------------------------
            -- Save job history
            ---------------------------------------------------
            --
            If @newJobStateInBroker IN (3, 5) AND
               Not (@oldJobStateInBroker = 2 And @newJobStateInBroker = 2) AND
               Not (@oldJobStateInBroker = 5 And @newJobStateInBroker = 2)
            Begin
                If @infoOnly > 0
                Begin
                    Print 'Exec copy_task_to_history @job=' + Cast(@job as varchar(12)) + ', @newJobStateInBroker=' + Cast(@newJobStateInBroker as varchar(6))
                End
                Else
                Begin
                    exec @myError = copy_task_to_history @job, @newJobStateInBroker, @message output
                End
            End

            Set @JobsProcessed = @JobsProcessed + 1
        End -- </b>

        If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
        Begin
            Set @StatusMessage = '... Updating job state: ' + Convert(varchar(12), @JobsProcessed) + ' / ' + Convert(varchar(12), @JobCountToProcess)
            exec post_log_entry 'Progress', @StatusMessage, 'update_task_state'
            Set @LastLogTime = GetDate()
        End

        If @MaxJobsToProcess > 0 And @JobsProcessed >= @MaxJobsToProcess
            Set @done = 1

    End -- </a>

    If @infoOnly > 0
    Begin
        SELECT *
        FROM #Tmp_ChangedJobs
        ORDER BY Job
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_task_state] TO [DDL_Viewer] AS [dbo]
GO
