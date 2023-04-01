/****** Object:  StoredProcedure [dbo].[merge_jobs_to_main_tables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[merge_jobs_to_main_tables]
/****************************************************
**
**  Desc:   Updates T_Tasks, T_Task_Parameters, and T_Task_Steps
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from T_Task_Steps
**          09/24/2014 mem - Rename Job in T_Task_Step_Dependencies
**          05/17/2019 mem - Switch from folder to directory
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/07/2023 mem - Rename columns in temporary table
**
*****************************************************/
(
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

/*
select * from #Jobs
select * from #Job_Steps
select * from #Job_Step_Dependencies
select * from #Job_Parameters
goto Done
*/

    ---------------------------------------------------
    --
    ---------------------------------------------------
    --
    declare @transName varchar(32)
    set @transName = 'merge_jobs_to_main_tables'
    --
    begin transaction @transName
    --
    ---------------------------------------------------
    -- replace job parameters
    ---------------------------------------------------
    --
    UPDATE T_Task_Parameters
    SET T_Task_Parameters.Parameters = #Job_Parameters.Parameters
    FROM T_Task_Parameters INNER JOIN
    #Job_Parameters ON #Job_Parameters.Job = T_Task_Parameters.Job
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
    -- update job
    ---------------------------------------------------
    --
    UPDATE T_Tasks
    SET
        Priority = #Jobs.Priority,
        State = #Jobs.State,
        Imported = Getdate(),
        Start = Getdate(),
        Finish = NULL
    FROM T_Tasks INNER JOIN
    #Jobs ON #Jobs.Job = T_Tasks.Job
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
    -- add steps for job that currently aren't in main tables
    ---------------------------------------------------

    INSERT INTO T_Task_Steps (
        Job,
        Step,
        Tool,
        CPU_Load,
        Dependencies,
        State,
        Input_Folder_Name,
        Output_Folder_Name,
        Processor,
        Holdoff_Interval_Minutes,
        Retry_Count
    )
    SELECT
        Job,
        Step,
        Tool,
        CPU_Load,
        Dependencies,
        State,
        Input_Directory_Name,
        Output_Directory_Name,
        Processor,
        Holdoff_Interval_Minutes,
        Retry_Count
    FROM #Job_Steps
    WHERE NOT EXISTS
    (
        SELECT *
        FROM T_Task_Steps
        WHERE
            T_Task_Steps.Job = #Job_Steps.Job and
            T_Task_Steps.Step = #Job_Steps.Step
    )
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

    INSERT INTO T_Task_Step_Dependencies (
        Job,
        Step,
        Target_Step,
        Condition_Test,
        Test_Value,
        Enable_Only
    )
    SELECT
        Job,
        Step,
        Target_Step,
        Condition_Test,
        Test_Value,
        Enable_Only
    FROM #Job_Step_Dependencies
    WHERE NOT EXISTS
    (
        SELECT *
        FROM T_Task_Step_Dependencies
        WHERE
            T_Task_Step_Dependencies.Job = #Job_Step_Dependencies.Job and
            T_Task_Step_Dependencies.Step = #Job_Step_Dependencies.Step
    )
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
GRANT VIEW DEFINITION ON [dbo].[merge_jobs_to_main_tables] TO [DDL_Viewer] AS [dbo]
GO
