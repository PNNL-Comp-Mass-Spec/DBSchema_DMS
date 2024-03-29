/****** Object:  StoredProcedure [dbo].[update_job_in_main_tables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_job_in_main_tables]
/****************************************************
**
**  Desc:   Updates T_Jobs, T_Job_Steps, and T_Job_Parameters
**          using the information in #Job_Parameters, #Jobs, and #Job_Steps
**
**          Note: Does not update job steps in state 5 = Complete
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   mem
**          03/11/2009 mem - Initial release (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          03/21/2011 mem - Changed transaction name to match procedure name
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          11/18/2015 mem - Add Actual_CPU_Load
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**
*****************************************************/
(
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int

    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------
    --
    declare @transName varchar(32)
    set @transName = 'update_job_in_main_tables'
    --
    begin transaction @transName
    --
    ---------------------------------------------------
    -- Replace job parameters
    ---------------------------------------------------
    --
    UPDATE T_Job_Parameters
    SET T_Job_Parameters.Parameters = #Job_Parameters.Parameters
    FROM T_Job_Parameters
         INNER JOIN #Job_Parameters
           ON #Job_Parameters.Job = T_Job_Parameters.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end

    ---------------------------------------------------
    -- Update job
    ---------------------------------------------------
    --
    UPDATE T_Jobs
    SET Priority = #Jobs.Priority,
        State = #Jobs.State,
        Imported = Getdate(),
        Start = Getdate(),
        Finish = NULL
    FROM T_Jobs
         INNER JOIN #Jobs
           ON #Jobs.Job = T_Jobs.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end


    -- Delete job step dependencies for job steps that are not yet completed
    DELETE T_Job_Step_Dependencies
    FROM T_Job_Step_Dependencies JSD
         INNER JOIN T_Job_Steps JS
           ON JSD.Job = JS.Job AND
              JSD.Step = JS.Step
         INNER JOIN #Job_Steps
           ON JS.Job = #Job_Steps.Job AND
              JS.Step = #Job_Steps.Step
    WHERE JS.State <> 5         -- 5 = Complete
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end

    -- Delete job steps that are not yet completed
    DELETE T_Job_Steps
    FROM T_Job_Steps JS
         INNER JOIN #Job_Steps
           ON JS.Job = #Job_Steps.Job AND
              JS.Step = #Job_Steps.Step
    WHERE JS.State <> 5         -- 5 = Complete
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end

    ---------------------------------------------------
    -- Add steps for job that currently aren't in main tables
    ---------------------------------------------------

    INSERT INTO T_Job_Steps (
        Job,
        Step,
        Tool,
        CPU_Load,
        Actual_CPU_Load,
        Memory_Usage_MB,
        Dependencies,
        Shared_Result_Version,
        Signature,
        State,
        Input_Folder_Name,
        Output_Folder_Name,
        Processor
    )
    SELECT
        Src.Job,
        Src.Step,
        Src.Tool,
        Src.CPU_Load,
        Src.CPU_Load,
        Src.Memory_Usage_MB,
        Src.Dependencies,
        Src.Shared_Result_Version,
        Src.Signature,
        1,          -- State
        Src.Input_Folder_Name,
        Src.Output_Folder_Name,
        Src.Processor
    FROM #Job_Steps Src
         LEFT OUTER JOIN T_Job_Steps JS
           ON JS.Job = Src.Job AND
              JS.Step = Src.Step
    WHERE JS.Job Is Null
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end

    ---------------------------------------------------
    -- add step dependencies for job that currently aren't
    -- in main tables
    ---------------------------------------------------

    INSERT INTO T_Job_Step_Dependencies (
        Job,
        Step,
        Target_Step,
        Condition_Test,
        Test_Value,
        Enable_Only
    )
    SELECT
        Src.Job,
        Src.Step,
        Src.Target_Step,
        Src.Condition_Test,
        Src.Test_Value,
        Src.Enable_Only
    FROM #Job_Step_Dependencies Src
         LEFT OUTER JOIN T_Job_Step_Dependencies JSD
           ON JSD.Job = Src.Job AND
              JSD.Step = Src.Step
    WHERE JSD.Job IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
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
GRANT VIEW DEFINITION ON [dbo].[update_job_in_main_tables] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_job_in_main_tables] TO [Limited_Table_Write] AS [dbo]
GO
