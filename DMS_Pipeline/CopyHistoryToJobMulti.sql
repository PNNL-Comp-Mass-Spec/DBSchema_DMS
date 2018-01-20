/****** Object:  StoredProcedure [dbo].[CopyHistoryToJobMulti] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CopyHistoryToJobMulti]
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
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/12/2017 mem - Add Remote_Info_ID
**          01/19/2018 mem - Add Runtime_Minutes
**    
*****************************************************/
(
    @JobList varchar(max),
    @InfoOnly tinyint = 0,
    @message varchar(512)='' output
)
As
    Set XACT_ABORT, nocount on
    
    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0
    
    set @message = ''
    
    Declare @JobsCopied int = 0
    
    ---------------------------------------------------
    -- Populate a temporary table with the jobs in @JobList
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_JobsToCopy (
        Job int NOT NULL,
        DateStamp datetime NULL
    )
    
    CREATE CLUSTERED INDEX #IX_Tmp_JobsToCopy ON #Tmp_JobsToCopy (Job)
    
    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'
        
    Begin Try
        
        INSERT INTO #Tmp_JobsToCopy (Job)
        SELECT Value
        FROM dbo.udfParseDelimitedIntegerList(@JobList, ',')
        
        ---------------------------------------------------
        -- Bail if no candidates found
        ---------------------------------------------------
        --
         if not exists (SELECT * FROM #Tmp_JobsToCopy)
         Begin
             set @message = '@JobList was empty or contained no jobs'
             print @message
            goto Done
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
        if not exists (SELECT * FROM #Tmp_JobsToCopy)
        Begin
            set @message = 'All jobs in @JobList already exist in T_Jobs'
            print @message
            goto Done
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
        if not exists (SELECT * FROM #Tmp_JobsToCopy)
         Begin
             set @message = 'None of the jobs in @JobList exists in T_Jobs_History'
             print @message
            goto Done
        End

        ---------------------------------------------------
        -- Lookup the max Saved date for each job    
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
                        GROUP BY JH.Job 
                        ) DateQ
            ON #Tmp_JobsToCopy.Job = DateQ.Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error '
            goto Done
        end

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
             Print 'Deleted ' + Convert(varchar(12), @myRowCount) + ' job(s) from @JobList because they do not exist in T_Jobs_History with state 4'
         End
         
         if @InfoOnly <> 0
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
        declare @transName varchar(64)
        set @transName = 'CopyHistoryToJob'
        begin transaction @transName

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
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Error '
            goto Done
        end
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
            Step_Number,
            Step_Tool,
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
            Remote_Info_ID
        )
        SELECT H.Job,
            H.Step_Number,
            H.Step_Tool,
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
            H.Remote_Info_ID
        FROM T_Job_Steps_History H
            INNER JOIN T_Step_Tools ST
              ON H.Step_Tool = ST.Name
            INNER JOIN #Tmp_JobsToCopy Src
              ON H.Job = Src.Job AND
                 H.Saved = Src.DateStamp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Error '
            goto Done
        end

        ---------------------------------------------------
        -- copy parameters
        ---------------------------------------------------
        --
        Set @CurrentLocation = 'Populate T_Job_Parameters'
        --
        INSERT INTO T_Job_Parameters (
            Job, 
            Parameters
        )
        SELECT
            JPH.Job, 
            JPH.Parameters
        FROM
            T_Job_Parameters_History JPH
            INNER JOIN #Tmp_JobsToCopy Src
              ON JPH.Job = Src.Job AND
                 JPH.Saved = Src.DateStamp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Error '
            goto Done
        end
                 
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
                  Target.Step_Number = Source.Step_Number AND
                  Target.Target_Step_Number = Source.Target_Step_Number
        WHERE Target.Job IN ( SELECT Job
                                 FROM #Tmp_JobsToCopy ) AND
              Source.Job IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Error '
            goto Done
        end
        
        -- Now add/update the job step dependencies
        --    
        MERGE T_Job_Step_Dependencies AS target
        USING ( SELECT H.Job, H.Step_Number, H.Target_Step_Number, H.Condition_Test, H.Test_Value, 
                       H.Evaluated, H.Triggered, H.Enable_Only
                FROM T_Job_Step_Dependencies_History H
                     INNER JOIN #Tmp_JobsToCopy Src
                       ON H.Job = Src.Job
            ) AS Source (Job, Step_Number, Target_Step_Number, Condition_Test, Test_Value, Evaluated, Triggered, Enable_Only)
            ON (target.Job = source.Job And 
                target.Step_Number = source.Step_Number And
                target.Target_Step_Number = source.Target_Step_Number)
        WHEN Matched THEN 
            UPDATE Set 
                Condition_Test = source.Condition_Test,
                Test_Value = source.Test_Value,
                Evaluated = source.Evaluated,
                Triggered = source.Triggered,
                Enable_Only = source.Enable_Only
        WHEN Not Matched THEN
            INSERT (Job, Step_Number, Target_Step_Number, Condition_Test, Test_Value, 
                    Evaluated, Triggered, Enable_Only)
            VALUES (source.Job, source.Step_Number, source.Target_Step_Number, source.Condition_Test, source.Test_Value, 
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
        INSERT INTO #Tmp_JobsMissingDependencies (Job, Script)
        SELECT DISTINCT J.Job,
                        J.Script
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
                                                 Step_Number,
                                                 Target_Step_Number,
                                                 Condition_Test,
                                                 Test_Value,
                                                 Evaluated,
                                                 Triggered,
                                                 Enable_Only )
            SELECT MD.Job AS Job,
                   Step_Number,
                   Target_Step_Number,
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
        exec PostLogEntry 'Normal', @message, 'CopyHistoryToJobMulti'
        
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
                Set @CurrentLocation = 'Call UpdateJobParameters for job ' + Convert(varchar(12), @job)
                --
                exec @myError = UpdateJobParameters @Job, @infoOnly=0

                ---------------------------------------------------
                -- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
                ---------------------------------------------------
                --
                Set @CurrentLocation = 'Call ValidateJobServerInfo for job ' + Convert(varchar(12), @job)
                --
                exec ValidateJobServerInfo @Job, @UseJobParameters=1

                Set @JobsRefreshed = @JobsRefreshed + 1
                
                If DateDiff(second, @LastStatusTime, GetDate()) >= 60
                Begin
                    Set @LastStatusTime = GetDate()
                    Set @ProgressMsg = 'Updating job parameters and storage info for copied jobs: ' + Convert(varchar(12), @JobsRefreshed) + ' / ' + Convert(varchar(12), @JobsCopied)
                    exec PostLogEntry 'Progress', @ProgressMsg, 'CopyHistoryToJobMulti'
                End
            End
            
        End
    End Try
    Begin Catch
        -- Error caught; log the error
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'CopyHistoryToJobMulti')
        exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
                                @ErrorNum = @myError output, @message = @message output
        If @@trancount > 0
            Rollback
    End Catch
    
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[CopyHistoryToJobMulti] TO [DDL_Viewer] AS [dbo]
GO
