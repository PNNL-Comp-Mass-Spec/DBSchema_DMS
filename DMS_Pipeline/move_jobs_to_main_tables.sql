/****** Object:  StoredProcedure [dbo].[move_jobs_to_main_tables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[move_jobs_to_main_tables]
/****************************************************
**
**  Desc:
**  Copy contents of four temporary tables:
**      #Jobs
**      #Job_Steps
**      #Job_Step_Dependencies
**      #Job_Parameters
**  To main database tables
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   02/06/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          09/14/2015 mem - Added parameter @DebugMode
**          11/18/2015 mem - Add Actual_CPU_Load
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**
*****************************************************/
(
    @message varchar(512) output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''
    set @DebugMode = IsNull(@DebugMode, 0)

    ---------------------------------------------------
    -- set up transaction parameters
    ---------------------------------------------------
    --
    declare @transName varchar(32)
    set @transName = 'move_jobs_to_main_tables'

    ---------------------------------------------------
    -- populate actual tables from accumulated entries
    ---------------------------------------------------

    If @DebugMode <> 0
    Begin
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobs') Drop table T_Tmp_NewJobs
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobSteps') Drop table T_Tmp_NewJobSteps
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobStepDependencies') Drop table T_Tmp_NewJobStepDependencies
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobParameters') Drop table T_Tmp_NewJobParameters

        select * INTO T_Tmp_NewJobs from #Jobs
        select * INTO T_Tmp_NewJobSteps from #Job_Steps
        select * INTO T_Tmp_NewJobStepDependencies from #Job_Step_Dependencies
        select * INTO T_Tmp_NewJobParameters from #Job_Parameters
    End

    begin transaction @transName

    UPDATE T_Jobs
    SET
        T_Jobs.State = #Jobs.State,
        T_Jobs.Results_Folder_Name = #Jobs.Results_Folder_Name
    FROM T_Jobs INNER JOIN #Jobs ON
        T_Jobs.Job = #Jobs.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end

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
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end

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
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error'
        goto Done
    end

    INSERT INTO T_Job_Parameters (
        Job,
        Parameters
    )
    SELECT
        Job,
        Parameters
    FROM #Job_Parameters
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
GRANT VIEW DEFINITION ON [dbo].[move_jobs_to_main_tables] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[move_jobs_to_main_tables] TO [Limited_Table_Write] AS [dbo]
GO
