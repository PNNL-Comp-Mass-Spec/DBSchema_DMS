/****** Object:  StoredProcedure [dbo].[copy_job_to_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[copy_job_to_history]
/****************************************************
**
**  Desc:
**      For a given job, copies the job details, steps,
**      and parameters to the history tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          12/17/2008 grk - Initial alpha
**          02/06/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          04/05/2011 mem - Now copying column Special_Processing
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          07/05/2011 mem - Now copying column Tool_Version_ID
**          11/14/2011 mem - Now copying column Transfer_Folder_Path
**          01/09/2012 mem - Added column Owner
**          01/19/2012 mem - Added columns DataPkgID and Memory_Usage_MB
**          03/26/2013 mem - Added column Comment
**          01/20/2014 mem - Added T_Job_Step_Dependencies_History
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          05/13/2017 mem - Add Remote_Info_Id
**          01/19/2018 mem - Add Runtime_Minutes
**          07/25/2019 mem - Add Remote_Start and Remote_Finish
**          08/17/2021 mem - Fix typo in argument @saveTimeOverride
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**
*****************************************************/
(
    @job int,
    @jobState int,
    @message varchar(512) output,
    @overrideSaveTime tinyint = 0,        -- Set to 1 to use @saveTimeOverride for the SaveTime instead of GetDate()
    @saveTimeOverride datetime = Null
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    set @message = ''

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------
    --
     if IsNull(@job, 0) = 0
        goto Done

    ---------------------------------------------------
    -- Bail if not a state we save for
    ---------------------------------------------------
    --
    if not @jobState in (4,5)
    Begin
          Set @message = 'Job state not 4 or 5; aborting'
          Print @message
        goto Done
    End

    ---------------------------------------------------
    -- Define a common timestamp for all history entries
    ---------------------------------------------------
    --
    Declare @saveTime datetime

    If IsNull(@overrideSaveTime, 0) <> 0
        Set @SaveTime = IsNull(@saveTimeOverride, GetDate())
    Else
        set @saveTime = GetDate()

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    Declare @transName varchar(64) = 'MoveJobsToHistory'
    begin transaction @transName

    ---------------------------------------------------
    -- Copy jobs
    ---------------------------------------------------
    --
    INSERT INTO T_Jobs_History (
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
        Comment,
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
        Organism_DB_Name,
        Special_Processing,
        Imported,
        Start,
        Finish,
        Runtime_Minutes,
        Transfer_Folder_Path,
        Owner,
        DataPkgID,
        Comment,
        @saveTime
    FROM T_Jobs
    WHERE Job = @job
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
    -- Copy Steps
    ---------------------------------------------------
    --
    INSERT INTO T_Job_Steps_History (
        Job,
        Step,
        Tool,
        Memory_Usage_MB,
        Shared_Result_Version,
        Signature,
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
        Tool_Version_ID,
        Remote_Info_Id,
        Remote_Start,
        Remote_Finish
    )
    SELECT
        Job,
        Step,
        Tool,
        Memory_Usage_MB,
        Shared_Result_Version,
        Signature,
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
        Tool_Version_ID,
        Remote_Info_Id,
        Remote_Start,
        Remote_Finish
    FROM T_Job_Steps
    WHERE Job = @job
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
    -- Copy parameters
    ---------------------------------------------------
    --
    INSERT INTO T_Job_Parameters_History( Job,
                                          [Parameters],
                                          Saved )
    SELECT Job,
           [Parameters],
           @saveTime
    FROM T_Job_Parameters
    WHERE Job = @job
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
    -- First delete any extra steps for this job that are in T_Job_Step_Dependencies_History
    DELETE T_Job_Step_Dependencies_History
    FROM T_Job_Step_Dependencies_History Target
         LEFT OUTER JOIN T_Job_Step_Dependencies Source
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
        set @message = 'Error '
        goto Done
    end

    -- Now add/update the job step dependencies
    --
    MERGE T_Job_Step_Dependencies_History AS target
    USING ( SELECT Job, Step, Target_Step, Condition_Test, Test_Value,
                   Evaluated, Triggered, Enable_Only
            FROM T_Job_Step_Dependencies
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
        set @message = 'Error '
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
GRANT VIEW DEFINITION ON [dbo].[copy_job_to_history] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[copy_job_to_history] TO [Limited_Table_Write] AS [dbo]
GO
