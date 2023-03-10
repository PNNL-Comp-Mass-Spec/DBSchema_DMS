/****** Object:  StoredProcedure [dbo].[copy_history_to_job_multi] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[copy_history_to_job_multi]
/****************************************************
**
**  Desc:
**      For a list of jobs, copies the job details, steps,
**      and parameters from the most recent successful
**      run in the history tables back into the main tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**          09/27/2012 mem - Initial version
**          03/26/2013 mem - Added column Comment
**          01/20/2014 mem - Added T_Job_Step_Dependencies_History
**          01/21/2014 mem - Added support for jobs that don't have cached dependencies in T_Job_Step_Dependencies_History
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          01/19/2015 mem - Fix ambiguous column reference
**          11/18/2015 mem - Add Actual_CPU_Load
**          02/23/2016 mem - Add Set XACT_ABORT on
**          05/12/2017 mem - Add Remote_Info_ID
**          01/19/2018 mem - Add Runtime_Minutes
**          06/20/2018 mem - Move rollback transaction to before the call to local_error_handler
**          07/25/2019 mem - Add Remote_Start and Remote_Finish
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**
*****************************************************/
(
    @jobList varchar(max),
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @JobsCopied int = 0

    ---------------------------------------------------
    -- Populate a temporary table with the jobs in @jobList
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_JobsToCopy (
        Job int NOT NULL,
        DateStamp datetime NULL
    )

    CREATE CLUSTERED INDEX #IX_Tmp_JobsToCopy ON #Tmp_JobsToCopy (Job)

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin Try

        INSERT INTO #Tmp_JobsToCopy (Job)
        SELECT Value
        FROM dbo.parse_delimited_integer_list(@jobList, ',')

        ---------------------------------------------------
        -- Bail if no candidates found
        ---------------------------------------------------
        --
        If Not exists (SELECT * FROM #Tmp_JobsToCopy)
        Begin
            Set @message = '@jobList was empty or contained no jobs'
            print @message
            Goto Done
        End

        ---------------------------------------------------
        -- Remove jobs that already exist in T_Jobs
        ---------------------------------------------------
        --
        DELETE FROM #Tmp_JobsToCopy
        WHERE Job IN (SELECT Job FROM T_Jobs)

        ---------------------------------------------------
        -- Bail if no candidates found
        ---------------------------------------------------
        --
        If not exists (SELECT * FROM #Tmp_JobsToCopy)
        Begin
            Set @message = 'All jobs in @jobList already exist in T_Jobs'
            print @message
            Goto Done
        End

        ---------------------------------------------------
        -- Delete jobs not present in T_Jobs_History
        ---------------------------------------------------
        --
        DELETE FROM #Tmp_JobsToCopy
        WHERE Job NOT IN (SELECT Job FROM T_Jobs_History)

        ---------------------------------------------------
        -- Bail if no candidates remain
        ---------------------------------------------------
        --
        If not exists (SELECT * FROM #Tmp_JobsToCopy)
        Begin
            Set @message = 'None of the jobs in @jobList exists in T_Jobs_History'
            print @message
            Goto Done
        End

        ---------------------------------------------------
        -- Lookup the max saved date for each job
        ---------------------------------------------------
        --
        Set @CurrentLocation = 'Update #Tmp_JobsToCopy.DateStamp'
        --
        UPDATE #Tmp_JobsToCopy
        SET DateStamp = DateQ.MostRecentDate
        FROM #Tmp_JobsToCopy
             INNER JOIN ( SELECT JH.Job,
                                 MAX(JH.Saved) AS MostRecentDate
                          FROM T_Jobs_History JH
                               INNER JOIN #Tmp_JobsToCopy Src
                                 ON JH.Job = Src.Job
                          WHERE State = 4
                          GROUP BY JH.Job ) DateQ
               ON #Tmp_JobsToCopy.Job = DateQ.Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error '
            Goto Done
        End

        ---------------------------------------------------
        -- Remove jobs where DateStamp is null
        ---------------------------------------------------
        --
        DELETE FROM #Tmp_JobsToCopy
        WHERE DateStamp Is Null
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myRowCount > 0
        Begin
            Print 'Deleted ' + Convert(varchar(12), @myRowCount) + ' job(s) from @jobList because they do not exist in T_Jobs_History with state 4'
        End

        If @infoOnly <> 0
        Begin
            SELECT *
            FROM #Tmp_JobsToCopy
            ORDER BY Job

            Goto Done
        End

        ---------------------------------------------------
        -- Start transaction
        ---------------------------------------------------
        --
        Declare @transName varchar(64) = 'copy_history_to_job'
        Begin transaction @transName

        ---------------------------------------------------
        -- Copy jobs
        ---------------------------------------------------
        --
        Set @CurrentLocation = 'Populate T_Jobs'
        --
        INSERT INTO T_Jobs (
            Job,
            Priority,
            Script,
            State,
            Dataset,
            Dataset_ID,
            Results_Folder_Name,
            Organism_DB_Name,
            Special_Processing,
            Imported,
            Start,
            Finish,
            Runtime_Minutes,
            Transfer_Folder_Path,
            Owner,
            DataPkgID,
            Comment
        )
        SELECT
            JH.Job,
            JH.Priority,
            JH.Script,
            JH.State,
            JH.Dataset,
            JH.Dataset_ID,
            JH.Results_Folder_Name,
            JH.Organism_DB_Name,
            JH.Special_Processing,
            JH.Imported,
            JH.Start,
            JH.Finish,
            JH.Runtime_Minutes,
            JH.Transfer_Folder_Path,
            JH.Owner,
            JH.DataPkgID,
            JH.Comment
        FROM T_Jobs_History JH
             INNER JOIN #Tmp_JobsToCopy Src
               ON JH.Job = Src.Job AND
                  JH.Saved = Src.DateStamp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Error '
            Goto Done
        End
        Else
            Set @JobsCopied = @myRowCount

        ---------------------------------------------------
        -- Copy Steps
        ---------------------------------------------------
        --
        Set @CurrentLocation = 'Populate T_Job_Steps'
        --
        INSERT INTO T_Job_Steps (
            Job,
            Step,
            Tool,
            CPU_Load,
            Actual_CPU_Load,
            Memory_Usage_MB,
            Shared_Result_Version,
            Signature,
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
            Remote_Info_ID,
            Remote_Start,
            Remote_Finish
        )
        SELECT H.Job,
            H.Step,
            H.Tool,
            ST.CPU_Load,
            ST.CPU_Load,
            H.Memory_Usage_MB,
            H.Shared_Result_Version,
            H.Signature,
            H.State,
            H.Input_Folder_Name,
            H.Output_Folder_Name,
            H.Processor,
            H.Start,
            H.Finish,
            H.Tool_Version_ID,
            H.Completion_Code,
            H.Completion_Message,
            H.Evaluation_Code,
            H.Evaluation_Message,
            H.Remote_Info_ID,
            H.Remote_Start,
            H.Remote_Finish
        FROM T_Job_Steps_History H
             INNER JOIN T_Step_Tools ST
               ON H.Tool = ST.Name
             INNER JOIN #Tmp_JobsToCopy Src
               ON H.Job = Src.Job AND
                  H.Saved = Src.DateStamp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Error '
            Goto Done
        End

        ---------------------------------------------------
        -- copy parameters
        ---------------------------------------------------
        --
        Set @CurrentLocation = 'Populate T_Job_Parameters'
        --
        INSERT INTO T_Job_Parameters( Job,
                                      [Parameters] )
        SELECT JPH.Job,
               JPH.[Parameters]
        FROM T_Job_Parameters_History JPH
             INNER JOIN #Tmp_JobsToCopy Src
               ON JPH.Job = Src.Job AND
                  JPH.Saved = Src.DateStamp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Error '
            Goto Done
        End

        ---------------------------------------------------
        -- Copy job step dependencies
        ---------------------------------------------------
        --
        -- First delete any extra steps that are in T_Job_Step_Dependencies
        --
        DELETE T_Job_Step_Dependencies
        FROM T_Job_Step_Dependencies Target
             LEFT OUTER JOIN T_Job_Step_Dependencies_History Source
               ON Target.Job = Source.Job AND
                  Target.Step = Source.Step AND
                  Target.Target_Step = Source.Target_Step
        WHERE Target.Job IN ( SELECT Job
                              FROM #Tmp_JobsToCopy ) AND
              Source.Job IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Error '
            Goto Done
        End

        -- Now add/update the job step dependencies
        --
        MERGE T_Job_Step_Dependencies AS target
        USING ( SELECT H.Job, H.Step, H.Target_Step, H.Condition_Test, H.Test_Value,
                       H.Evaluated, H.Triggered, H.Enable_Only
                FROM T_Job_Step_Dependencies_History H
                     INNER JOIN #Tmp_JobsToCopy Src
                       ON H.Job = Src.Job
            ) AS Source (Job, Step, Target_Step, Condition_Test, Test_Value, Evaluated, Triggered, Enable_Only)
            ON (target.Job = source.Job And
                target.Step = source.Step And
                target.Target_Step = source.Target_Step)
        WHEN Matched THEN
            UPDATE Set
                Condition_Test = source.Condition_Test,
                Test_Value = source.Test_Value,
                Evaluated = source.Evaluated,
                Triggered = source.Triggered,
                Enable_Only = source.Enable_Only
        WHEN Not Matched THEN
            INSERT (Job, Step, Target_Step, Condition_Test, Test_Value,
                    Evaluated, Triggered, Enable_Only)
            VALUES (source.Job, source.Step, source.Target_Step, source.Condition_Test, source.Test_Value,
                    source.Evaluated, source.Triggered, source.Enable_Only)
        ;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        -- Fill in the dependencies for jobs that didn't have any data in T_Job_Step_Dependencies
        --
        CREATE TABLE #Tmp_JobsMissingDependencies (
            Job int NOT NULL,
            Script varchar(64) NOT NULL,
            SimilarJob int NULL
        )

        -- Find jobs that didn't have cached dependencies
        --
        INSERT INTO #Tmp_JobsMissingDependencies( Job,
                                                  Script )
        SELECT DISTINCT J.Job, J.Script
        FROM T_Jobs J
             INNER JOIN #Tmp_JobsToCopy Src
               ON J.Job = Src.Job
             LEFT OUTER JOIN T_Job_Step_Dependencies D
               ON J.Job = D.Job
        WHERE D.Job IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If Exists (Select * From #Tmp_JobsMissingDependencies)
        Begin
            -- One or more jobs did not have cached dependencies
            -- For each job, find a matching job that used the same script and _does_ have cached dependencies

            UPDATE #Tmp_JobsMissingDependencies
            SET SimilarJob = Source.SimilarJob
            FROM #Tmp_JobsMissingDependencies target
                 INNER JOIN ( SELECT Job,
                                     SimilarJob,
                                     Script
                              FROM ( SELECT MD.Job,
                                            JobsWithDependencies.Job AS SimilarJob,
                                            JobsWithDependencies.Script,
                                            Row_Number() OVER ( Partition By MD.Job
                                                                Order By JobsWithDependencies.Job ) AS SimilarJobRank
                                     FROM #Tmp_JobsMissingDependencies MD
                                          INNER JOIN ( SELECT JH.Job, JH.Script
                                                       FROM T_Jobs_History JH INNER JOIN
                                                            T_Job_Step_Dependencies_History JSD ON JH.Job = JSD.Job
                                                     ) AS JobsWithDependencies
                                            ON MD.Script = JobsWithDependencies.Script AND
                  JobsWithDependencies.Job > MD.Job
                       ) AS MatchQ
                              WHERE SimilarJobRank = 1
                 ) AS source
                   ON Target.Job = Source.Job
             --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            INSERT INTO T_Job_Step_Dependencies( Job,
                                                 Step,
                                                 Target_Step,
                                                 Condition_Test,
                                                 Test_Value,
                                                 Evaluated,
                                                 Triggered,
                                                 Enable_Only )
            SELECT MD.Job AS Job,
                   Step,
                   Target_Step,
                   Condition_Test,
                   Test_Value,
                   0 AS Evaluated,
                   0 AS Triggered,
                   Enable_Only
            FROM T_Job_Step_Dependencies_History H
                 INNER JOIN #Tmp_JobsMissingDependencies MD
                   ON H.Job = MD.SimilarJob
                 --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

        commit transaction @transName


        ---------------------------------------------------
        -- Jobs successfully copied
        ---------------------------------------------------
        --
        Set @message = 'Copied ' + Convert(varchar(12), @JobsCopied) + ' jobs from the history tables to the main tables'
        exec post_log_entry 'Normal', @message, 'copy_history_to_job_multi'

        Declare @Job int = 0
        Declare @JobsRefreshed int = 0

        Declare @continue tinyint = 1
        Declare @LastStatusTime datetime = GetDate()
        Declare @ProgressMsg varchar(128)

        Set @CurrentLocation = 'Updating job parameters and storage server info'

        While @continue = 1
        Begin
            SELECT TOP 1 @Job = Job
            FROM #Tmp_JobsToCopy
            WHERE Job > @Job
            ORDER BY Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @continue = 0
            Else
            Begin
                ---------------------------------------------------
                -- Update the job parameters in case any parameters have changed (in particular, storage path)
                ---------------------------------------------------
                --
                Set @CurrentLocation = 'Call update_job_parameters for job ' + Convert(varchar(12), @job)
                --
                exec @myError = update_job_parameters @Job, @infoOnly=0

                ---------------------------------------------------
                -- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
                ---------------------------------------------------
                --
                Set @CurrentLocation = 'Call validate_job_server_info for job ' + Convert(varchar(12), @job)
                --
                exec validate_job_server_info @Job, @UseJobParameters=1

                Set @JobsRefreshed = @JobsRefreshed + 1

                If DateDiff(second, @LastStatusTime, GetDate()) >= 60
                Begin
                    Set @LastStatusTime = GetDate()
                    Set @ProgressMsg = 'Updating job parameters and storage info for copied jobs: ' + Convert(varchar(12), @JobsRefreshed) + ' / ' + Convert(varchar(12), @JobsCopied)
                    exec post_log_entry 'Progress', @ProgressMsg, 'copy_history_to_job_multi'
                End
            End

        End
    End Try
    Begin Catch
        If @@trancount > 0
            Rollback

        -- Error caught; log the error
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'copy_history_to_job_multi')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[copy_history_to_job_multi] TO [DDL_Viewer] AS [dbo]
GO
