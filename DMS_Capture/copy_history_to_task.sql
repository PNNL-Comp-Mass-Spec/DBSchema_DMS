/****** Object:  StoredProcedure [dbo].[copy_history_to_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[copy_history_to_task]
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
**  Date:   02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from T_Task_Steps
**          03/12/2012 mem - Added column Tool_Version_ID
**          03/21/2012 mem - Now disabling identity_insert prior to inserting a row into T_Tasks
**                         - Fixed bug finding most recent successful job in T_Tasks_History
**          08/27/2013 mem - Now calling update_parameters_for_task
**          10/21/2013 mem - Added @AssignNewJobNumber
**          03/10/2015 mem - Added T_Task_Step_Dependencies_History
**          03/10/2015 mem - Now updating T_Task_Steps.Dependencies if it doesn't match the dependent steps listed in T_Task_Step_Dependencies
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @job int,
    @assignNewJobNumber tinyint = 0,            -- Set to 1 to assign a new job number when copying
    @message varchar(512) = '' output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''
    set @debugMode = IsNull(@debugMode, 0)

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------
    --
    if IsNull(@job, 0) = 0
        goto Done

    Set @AssignNewJobNumber = IsNull(@AssignNewJobNumber, 0)

    If @debugMode <> 0
        Print 'Looking for job ' + Cast(@job as varchar(12)) + ' in the history tables'

    ---------------------------------------------------
    -- Bail if job already exists in main tables
    ---------------------------------------------------
    --
    if exists (select * from T_Tasks where Job = @job)
    begin
        If @debugMode <> 0
            Print 'Already exists in T_Tasks; aborting'

        GOTO Done
    end

    ---------------------------------------------------
    -- Get job status from most recent completed historic job
    ---------------------------------------------------
    --
    declare @dateStamp datetime
    --
    -- find most recent successful historic job
    SELECT @dateStamp = MAX(Saved)
    FROM T_Tasks_History
    WHERE Job = @job AND State = 3
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error '
        goto Done
    end

    If @dateStamp Is Null
    Begin
        Print 'No successful jobs found in T_Tasks_History for job ' + Cast(@job as varchar(12)) + '; will look for a failed job'

        -- Find most recent historic job, regardless of job state
        --
        SELECT @dateStamp = MAX(Saved)
        FROM T_Tasks_History
        WHERE Job = @job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Select 'Job not found in T_Tasks_History: ' + Cast(@job as varchar(12)) AS Warning
            Goto Done
        End

        Print 'Match found, saved on ' + Convert(varchar(30), @dateStamp)
    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    declare @transName varchar(64)
    set @transName = 'copy_history_to_task'
    begin transaction @transName

    Declare @NewJob int = @Job
    Declare @JobDateDescription varchar(64) = 'job ' + Cast(@job as varchar(12)) + ' and date ' + convert(varchar(24), @dateStamp, 121)

    If @AssignNewJobNumber = 0
    Begin

        set identity_insert dbo.T_Tasks ON

        If @debugMode <> 0
            Print 'Insert into T_Tasks from T_Tasks_History for ' + @JobDateDescription

        INSERT INTO T_Tasks (Job, Priority, Script, State,
                            Dataset, Dataset_ID, Results_Folder_Name,
                            Imported, Start, Finish )
        SELECT Job, Priority, Script, State,
               Dataset, Dataset_ID, Results_Folder_Name,
               Imported, Start, Finish
        FROM T_Tasks_History
        WHERE Job = @job AND
              Saved = @dateStamp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Error inserting into T_Tasks for ' + @JobDateDescription
            goto Done
        end

        set identity_insert dbo.T_Tasks OFF

        If @myRowCount = 0
        Begin
            set @message = 'No rows were added to T_Tasks from T_Tasks_History for ' + @JobDateDescription
            print @message
            rollback transaction @transName
            goto Done
        End


    End
    Else
    Begin

        If @debugMode <> 0
            Print 'Insert into T_Tasks from T_Tasks_History for ' + @JobDateDescription + '; assign a new job number'

        INSERT INTO T_Tasks( Priority, Script, State,
                            Dataset, Dataset_ID, Results_Folder_Name,
                            Imported, Start, Finish )
        SELECT Priority, Script, State,
               Dataset, Dataset_ID, Results_Folder_Name,
               GetDate(), Start, Finish
        FROM T_Tasks_History
        WHERE Job = @job AND
              Saved = @dateStamp
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount, @NewJob = Scope_Identity()
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Error '
            goto Done
        end

        If @NewJob is null
        Begin
            rollback transaction @transName
            set @message = 'Error: Scope_Identity() returned null for ' + @JobDateDescription
            goto Done
        end

        Print 'Cloned job ' + Cast(@job as varchar(12)) + ' to create job ' + Convert(varchar(12), @NewJob)
    End

    ---------------------------------------------------
    -- copy steps
    ---------------------------------------------------
    --
    INSERT INTO T_Task_Steps (
        Job,
        Step,
        Tool,
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
        Evaluation_Message
    )
    SELECT
        @NewJob AS Job,
        Step,
        Tool,
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
        Evaluation_Message
    FROM
        T_Task_Steps_History
    WHERE
        Job = @job AND
        Saved = @dateStamp
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error '
        goto Done
    end

    If @debugMode <> 0
        Print 'Inserted ' + Cast(@myRowCount as varchar(12)) + ' steps into T_Task_Steps for ' + @JobDateDescription

    -- Change any waiting or enabled steps to state 7 (holding)
    -- This is a safety feature to avoid job steps from starting inadvertently
    --
    UPDATE T_Task_Steps
    SET State = 7
    WHERE Job = @NewJob AND
          State IN (1, 2)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- copy parameters
    ---------------------------------------------------
    --
    INSERT INTO T_Task_Parameters (
        Job,
        Parameters
    )
    SELECT
        @NewJob AS Job,
        Parameters
    FROM
        T_Task_Parameters_History
    WHERE
        Job = @job AND
        Saved = @dateStamp
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error '
        goto Done
    end

    If @debugMode <> 0
        Print 'Inserted ' + Cast(@myRowCount as varchar(12)) + ' row into T_Task_Parameters for ' + @JobDateDescription

    ---------------------------------------------------
    -- Copy job step dependencies
    ---------------------------------------------------
    --
    -- First delete any extra steps for this job that are in T_Task_Step_Dependencies
    --
    DELETE T_Task_Step_Dependencies
    FROM T_Task_Step_Dependencies Target
         LEFT OUTER JOIN T_Task_Step_Dependencies_History Source
           ON Target.Job = Source.Job AND
              Target.Step = Source.Step AND
              Target.Target_Step = Source.Target_Step
    WHERE Target.Job = @NewJob AND
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

    -- Check whether this job has entries in T_Task_Step_Dependencies_History
    --
    If Not Exists (Select * From T_Task_Step_Dependencies_History Where Job = @job)
    Begin
        -- Job did not have cached dependencies
        -- Look for a job that used the same script

        Declare @SimilarJob int = 0

        SELECT @SimilarJob = MIN(H.Job)
        FROM T_Task_Step_Dependencies_History H
             INNER JOIN ( SELECT Job
                          FROM T_Tasks_History
                          WHERE Job > @job AND
                                Script = ( SELECT Script
                                           FROM T_Tasks_History
                                           WHERE Job = @job AND
                                                 Most_Recent_Entry = 1 )
                         ) SimilarJobQ
               ON H.Job = SimilarJobQ.Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            If @debugMode <> 0
                print 'Insert Into T_Task_Step_Dependencies using model job ' + Cast(@SimilarJob as varchar(12))

            INSERT INTO T_Task_Step_Dependencies(Job, Step, Target_Step, Condition_Test, Test_Value,
                                                Evaluated, Triggered, Enable_Only)
            SELECT @NewJob As Job, Step, Target_Step, Condition_Test, Test_Value, 0 AS Evaluated, 0 AS Triggered, Enable_Only
            FROM T_Task_Step_Dependencies_History H
            WHERE Job = @SimilarJob
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @debugMode <> 0
                print 'Added ' + cast(@myRowCount as varchar(12)) + ' rows to T_Task_Step_Dependencies for ' + @JobDateDescription + ' using model job ' + Cast(@SimilarJob as varchar(12))

        End
        Else
        Begin
            -- No similar jobs
            -- Create default dependencies

            If @debugMode <> 0
                print 'Create default dependencies for job ' + Cast(@NewJob as varchar(12))

            INSERT INTO T_Task_Step_Dependencies( Job,
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
            FROM T_Task_Steps
            WHERE (Job = @NewJob) AND
                  (Step > 1)

            If @debugMode <> 0
                print 'Added ' + cast(@myRowCount as varchar(12)) + ' rows to T_Task_Step_Dependencies'
        End

    End
    Else
    Begin

        If @debugMode <> 0
            print 'Insert into T_Task_Step_Dependencies using T_Task_Step_Dependencies_History for ' + @JobDateDescription

        -- Now add/update the job step dependencies
        --
        MERGE T_Task_Step_Dependencies AS target
        USING ( SELECT @NewJob AS Job, Step, Target_Step, Condition_Test, Test_Value,
                       Evaluated, Triggered, Enable_Only
                FROM T_Task_Step_Dependencies_History
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
    -- Manually create the job parameters if they were not present in T_Task_Parameters
    ---------------------------------------------------

    If Not Exists (SELECT * FROM T_Task_Parameters WHERE Job = @NewJob)
    Begin
        exec update_parameters_for_task @NewJob
    End

    ---------------------------------------------------
    -- Make sure Storage_Server is up-to-date in T_Tasks
    ---------------------------------------------------
    --
    Declare @jobList varchar(max) = Cast(@NewJob as varchar(12))

    exec update_parameters_for_task @jobList

    ---------------------------------------------------
    -- Make sure the Dependencies column is up-to-date in T_Task_Steps
    ---------------------------------------------------
    --
    UPDATE T_Task_Steps
    SET Dependencies = T.dependencies
    FROM T_Task_Steps JS
         INNER JOIN ( SELECT Step,
                             COUNT(*) AS dependencies
                      FROM T_Task_Step_Dependencies
                      WHERE (Job = @NewJob)
                      GROUP BY Step
                    ) T
           ON T.Step = JS.Step
    WHERE (JS.Job = @NewJob) AND
          T.Dependencies > JS.Dependencies
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    if @myError <> 0
        print @message

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[copy_history_to_task] TO [DDL_Viewer] AS [dbo]
GO
