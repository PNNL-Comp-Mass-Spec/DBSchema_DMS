/****** Object:  StoredProcedure [dbo].[copy_history_to_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[copy_history_to_job]
/****************************************************
**
**  Desc:
**      For a given job, copies the job details, steps,
**      and parameters from the most recent successful
**      run in the history tables back into the main tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          10/05/2009 mem - Now looking up CPU_Load for each step tool
**          04/05/2011 mem - Now copying column Special_Processing
**          05/19/2011 mem - Now calling update_job_parameters
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          07/12/2011 mem - Now calling validate_job_server_info
**          10/17/2011 mem - Added column Memory_Usage_MB
**          11/01/2011 mem - Added column Tool_Version_ID
**          11/14/2011 mem - Added column Transfer_Folder_Path
**          01/09/2012 mem - Added column Owner
**          01/19/2012 mem - Added column DataPkgID
**          03/26/2013 mem - Added column Comment
**          12/10/2013 mem - Added support for failed jobs
**          01/20/2014 mem - Added T_Job_Step_Dependencies_History
**          01/21/2014 mem - Added support for jobs that don't have cached dependencies in T_Job_Step_Dependencies_History
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          03/10/2015 mem - Now adding default dependencies if a similar job cannot be found
**          03/10/2015 mem - Now updating T_Job_Steps.Dependencies if it doesn't match the dependent steps listed in T_Job_Step_Dependencies
**          11/18/2015 mem - Add Actual_CPU_Load
**          05/12/2017 mem - Add Remote_Info_ID
**          01/19/2018 mem - Add Runtime_Minutes
**          07/25/2019 mem - Add Remote_Start and Remote_Finish
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**
*****************************************************/
(
    @job int,
    @message varchar(512)='' output
)
AS
    Set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------
    --
    If IsNull(@job, 0) = 0
        Goto Done

    ---------------------------------------------------
    -- Bail if job already exists in main tables
    ---------------------------------------------------
    --
    If exists (select * from T_Jobs where Job = @job)
    Begin
        Goto Done
    End

    ---------------------------------------------------
    -- Get job status from most recent completed historic job
    ---------------------------------------------------
    --
    Declare @dateStamp datetime

    -- Find most recent successful historic job
    --
    SELECT @dateStamp = MAX(Saved)
    FROM T_Jobs_History
    WHERE Job = @job AND State = 4
    GROUP BY Job, State
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error '
        Goto Done
    End

    If @dateStamp Is Null
    Begin
        Print 'No successful jobs found in T_Jobs_History for job ' + Convert(varchar(12), @job) + '; will look for a failed job'

        -- Find most recent historic job, regardless of job state
        --
        SELECT @dateStamp = MAX(Saved)
        FROM T_Jobs_History
        WHERE Job = @job
        GROUP BY Job, State
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Select 'Job not found in T_Jobs_History: ' + Convert(varchar(12), @job) AS Warning
            Goto Done
        End

        Print 'Match found, saved on ' + Convert(varchar(30), @dateStamp)

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
    FROM
        T_Jobs_History
    WHERE
        Job = @job AND
        Saved = @dateStamp
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
    -- Copy Steps
    ---------------------------------------------------
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
    WHERE H.Job = @job AND
          H.Saved = @dateStamp
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error '
        Goto Done
    End

    -- Change any waiting, enabled, or running steps to state 7 (holding)
    -- This is a safety feature to avoid job steps from starting inadvertently
    --
    UPDATE T_Job_Steps
    SET State = 7
    WHERE Job = @Job AND
          State IN (1, 2, 4, 9)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Copy parameters
    ---------------------------------------------------
    --
    INSERT INTO T_Job_Parameters( Job,
                                  [Parameters] )
    SELECT Job,
           [Parameters]
    FROM T_Job_Parameters_History
    WHERE Job = @job AND
          Saved = @dateStamp
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
    -- First delete any extra steps for this job that are in T_Job_Step_Dependencies
    --
    DELETE T_Job_Step_Dependencies
    FROM T_Job_Step_Dependencies Target
         LEFT OUTER JOIN T_Job_Step_Dependencies_History Source
           ON Target.Job = Source.Job AND
              Target.Step = Source.Step AND
              Target.Target_Step = Source.Target_Step
    WHERE Target.Job = @job AND
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

    -- Check whether this job has entries in T_Job_Step_Dependencies_History
    --
    If Not Exists (Select * From T_Job_Step_Dependencies_History Where Job = @job)
    Begin
        -- Job did not have cached dependencies
        -- Look for a job that used the same script

        Declare @SimilarJob int = 0

        SELECT @SimilarJob = MIN(H.Job)
        FROM T_Job_Step_Dependencies_History H
             INNER JOIN ( SELECT Job
                          FROM T_Jobs_History
                          WHERE Job > @job AND
                                Script = ( SELECT Script
                                           FROM T_Jobs_History
                WHERE Job = @job AND
                                                 Most_Recent_Entry = 1 )
                         ) SimilarJobQ
               ON H.Job = SimilarJobQ.Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin

            INSERT INTO T_Job_Step_Dependencies( Job,
                                                 Step,
                                                 Target_Step,
                                                 Condition_Test,
                                                 Test_Value,
                                                 Evaluated,
                                                 Triggered,
                                                 Enable_Only )
            SELECT @job AS Job,
                   Step,
                   Target_Step,
                   Condition_Test,
                   Test_Value,
                   0 AS Evaluated,
                   0 AS Triggered,
                   Enable_Only
            FROM T_Job_Step_Dependencies_History H
            WHERE Job = @SimilarJob

        End
        Else
        Begin
            -- No similar jobs
            -- Create default dependencenies

            INSERT INTO T_Job_Step_Dependencies( Job,
                                                 Step,
                                                 Target_Step,
                                                 Evaluated,
                                                 Triggered,
                                                 Enable_Only )
            SELECT Job,
                   Step,
                   Step - 1 AS Target_Step,
                   0 AS Evaluated,
                   0 AS Triggered,
                   0 AS Enable_Only
            FROM T_Job_Steps
            WHERE (Job = @job) AND
                  (Step > 1)
        End

    End
    Else
    Begin

        -- Now add/update the job step dependencies
        --
        MERGE T_Job_Step_Dependencies AS target
        USING ( SELECT Job, Step, Target_Step, Condition_Test, Test_Value,
                       Evaluated, Triggered, Enable_Only
                FROM T_Job_Step_Dependencies_History
                WHERE Job = @job
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

    End

    commit transaction @transName

    ---------------------------------------------------
    -- Update the job parameters in case any parameters have changed (in particular, storage path)
    ---------------------------------------------------
    --
    exec @myError = update_job_parameters @job, @infoOnly=0

    ---------------------------------------------------
    -- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
    ---------------------------------------------------
    --
    exec validate_job_server_info @job, @UseJobParameters=1

    ---------------------------------------------------
    -- Make sure the Dependencies column is up-to-date in T_Job_Steps
    ---------------------------------------------------
    --
    UPDATE T_Job_Steps
    SET Dependencies = T.dependencies
    FROM T_Job_Steps JS
         INNER JOIN ( SELECT Step,
                             COUNT(*) AS dependencies
                      FROM T_Job_Step_Dependencies
                      WHERE (Job = @job)
                      GROUP BY Step
                    ) T
           ON T.Step = JS.Step
    WHERE (JS.Job = @job) AND
          T.Dependencies > JS.Dependencies
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[copy_history_to_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[copy_history_to_job] TO [Limited_Table_Write] AS [dbo]
GO
