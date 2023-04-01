/****** Object:  StoredProcedure [dbo].[copy_task_to_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[copy_task_to_history]
/****************************************************
**
**  Desc:
**      For a given job, copies the job details, steps,
**      and parameters to the history tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/12/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/25/2011 mem - Removed priority column from T_Task_Steps
**          03/12/2012 mem - Now copying column Tool_Version_ID
**          03/10/2015 mem - Added T_Task_Step_Dependencies_History
**          03/22/2016 mem - Update @message when cannot copy a job
**          11/04/2016 mem - Return a more detailed error message in @message
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @job int,
    @jobState int,
    @message varchar(512) output,
    @overrideSaveTime tinyint = 0,      -- Set to 1 to use @SaveTimeOverride for the SaveTime instead of GetDate()
    @saveTimeOverride datetime = Null
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------
    --
    If IsNull(@job, 0) = 0
    Begin
        Set @message = 'Job cannot be 0'
        goto Done
    End

    ---------------------------------------------------
    -- Bail if not a state we save for
    ---------------------------------------------------
    --
    If not @JobState in (3,5)
    Begin
        Set @message = 'Job state must be 3 or 5 to be copied to T_Tasks_History (this is not an error)'
        goto Done
    End

    ---------------------------------------------------
    -- Define a common timestamp for all history entries
    ---------------------------------------------------
    --
    declare @saveTime datetime

    If IsNull(@OverrideSaveTime, 0) <> 0
        Set @SaveTime = IsNull(@saveTimeOverride, GetDate())
    Else
        set @saveTime = GetDate()

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    declare @transName varchar(64)
    set @transName = 'MoveJobsToHistory'
    begin transaction @transName

    ---------------------------------------------------
    -- copy jobs
    ---------------------------------------------------
    --
    INSERT INTO T_Tasks_History (
        Job,
        Priority,
        Script,
        State,
        Dataset,
        Dataset_ID,
        Results_Folder_Name,
        Imported,
        Start,
        Finish,
        Saved
    )
    SELECT
        Job,
        Priority,
        Script,
        State,
        Dataset,
        Dataset_ID,
        Results_Folder_Name,
        Imported,
        Start,
        Finish,
        @saveTime
    FROM
      T_Tasks
    WHERE  Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error inserting into T_Tasks_History'
        goto Done
    end

    ---------------------------------------------------
    -- copy steps
    ---------------------------------------------------
    --
    INSERT INTO T_Task_Steps_History (
        Job,
        Step,
        Tool,
        State,
        Input_Folder_Name,
        Output_Folder_Name,
        Processor,
        Start,
        Finish,
        Completion_Code,
        Completion_Message,
        Evaluation_Code,
        Evaluation_Message,
        Saved,
        Tool_Version_ID
    )
    SELECT
        Job,
        Step,
        Tool,
        State,
        Input_Folder_Name,
        Output_Folder_Name,
        Processor,
        Start,
        Finish,
        Completion_Code,
        Completion_Message,
        Evaluation_Code,
        Evaluation_Message,
        @saveTime,
        Tool_Version_ID
    FROM
      T_Task_Steps
    WHERE  Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error inserting into T_Task_Steps_History'
        goto Done
    end

    ---------------------------------------------------
    -- copy parameters
    ---------------------------------------------------
    --
    INSERT INTO T_Task_Parameters_History (
        Job,
        Parameters,
        Saved
    )
    SELECT
        Job,
        Parameters,
        @saveTime
    FROM
        T_Task_Parameters
    WHERE
        Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error inserting into T_Task_Parameters_History'
        goto Done
    end

    ---------------------------------------------------
    -- Copy job step dependencies
    ---------------------------------------------------
    --
    -- First delete any extra steps for this job that are in T_Task_Step_Dependencies_History
    DELETE T_Task_Step_Dependencies_History
    FROM T_Task_Step_Dependencies_History Target
         LEFT OUTER JOIN T_Task_Step_Dependencies Source
           ON Target.Job = Source.Job AND
              Target.Step = Source.Step AND
              Target.Target_Step = Source.Target_Step
    WHERE Target.Job = @job AND
          Source.Job IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error deleting extra steps from T_Task_Step_Dependencies_History'
        goto Done
    end

    -- Now add/update the job step dependencies
    --
    MERGE T_Task_Step_Dependencies_History AS target
    USING ( SELECT Job, Step, Target_Step, Condition_Test, Test_Value,
                   Evaluated, Triggered, Enable_Only
            FROM T_Task_Step_Dependencies
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
            Enable_Only = source.Enable_Only,
            Saved = @saveTime
    WHEN Not Matched THEN
        INSERT (Job, Step, Target_Step, Condition_Test, Test_Value,
                Evaluated, Triggered, Enable_Only, Saved)
        VALUES (source.Job, source.Step, source.Target_Step, source.Condition_Test, source.Test_Value,
                source.Evaluated, source.Triggered, source.Enable_Only, @saveTime)
    ;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error inserting into T_Task_Step_Dependencies_History'
        goto Done
    end

    commit transaction @transName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[copy_task_to_history] TO [DDL_Viewer] AS [dbo]
GO
