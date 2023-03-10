/****** Object:  StoredProcedure [dbo].[merge_jobs_to_main_tables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[merge_jobs_to_main_tables]
/****************************************************
**
**  Desc:   Merges data in the temp tables into T_Jobs, T_Job_Steps, etc.
**          Intended for use with an extension job script
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          10/22/2010 mem - Added parameter @DebugMode
**          03/21/2011 mem - Renamed @DebugMode to @InfoOnly
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          11/18/2015 mem - Add Actual_CPU_Load
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**
*****************************************************/
(
    @message varchar(512) output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''


    if @InfoOnly <> 0
    Begin
        SELECT '#Jobs' as [Table], * FROM #Jobs
        SELECT '#Job_Parameters ' as [Table], * FROM #Job_Parameters

        -- No need to output these tables, since SP create_job_steps will have already displayed them
        -- SELECT '#Job_Steps ' as [Table], * FROM #Job_Steps
        -- SELECT '#Job_Step_Dependencies' as [Table], * FROM #Job_Step_Dependencies

        Goto Done
    End

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
    -- update job
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

    ---------------------------------------------------
    -- add steps for job that currently aren't in main tables
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
        Job,
        Step,
        Tool,
        CPU_Load,
        CPU_Load,
        Memory_Usage_MB,
        Dependencies,
        Shared_Result_Version,
        Signature,
        State,
        Input_Folder_Name,
        Output_Folder_Name,
        Processor
    FROM #Job_Steps
    WHERE NOT EXISTS
    (
        SELECT *
        FROM T_Job_Steps
        WHERE
            T_Job_Steps.Job = #Job_Steps.Job and
            T_Job_Steps.Step = #Job_Steps.Step
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

    INSERT INTO T_Job_Step_Dependencies (
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
        FROM T_Job_Step_Dependencies
        WHERE
            T_Job_Step_Dependencies.Job = #Job_Step_Dependencies.Job and
            T_Job_Step_Dependencies.Step = #Job_Step_Dependencies.Step
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
GRANT VIEW DEFINITION ON [dbo].[merge_jobs_to_main_tables] TO [Limited_Table_Write] AS [dbo]
GO
