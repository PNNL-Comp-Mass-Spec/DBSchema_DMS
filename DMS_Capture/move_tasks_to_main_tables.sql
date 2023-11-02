/****** Object:  StoredProcedure [dbo].[move_tasks_to_main_tables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[move_tasks_to_main_tables]
/****************************************************
**
**  Desc:
**      Copy contents of temporary tables:
**        #Jobs
**        #Job_Steps
**        #Job_Step_Dependencies
**        #Job_Parameters
**      To main database tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/06/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          01/14/2010 grk - removed path ID fields
**          05/25/2011 mem - Removed priority column from T_Task_Steps
**          09/24/2014 mem - Rename Job in T_Task_Step_Dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          09/17/2015 mem - Added parameter @DebugMode
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/07/2023 mem - Rename columns in temporary table
**          04/01/2023 mem - Rename procedures and functions
**          11/01/2023 bcg - Update Next_Try in T_Task_Steps when adding rows from #Job_Steps
**
*****************************************************/
(
    @message varchar(512) output,
    @debugMode tinyint = 0
)
AS
    Set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Set @message = ''
    Set @DebugMode = IsNull(@DebugMode, 0)

    ---------------------------------------------------
    -- set up transaction parameters
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'move_tasks_to_main_tables'

    ---------------------------------------------------
    -- populate actual tables from accumulated entries
    ---------------------------------------------------

    If @DebugMode <> 0
    Begin
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobs') Drop table T_Tmp_NewJobs
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobSteps') Drop table T_Tmp_NewJobSteps
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobStepDependencies') Drop table T_Tmp_NewJobStepDependencies
        If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobParameters') Drop table T_Tmp_NewJobParameters

        SELECT * INTO T_Tmp_NewJobs FROM #Jobs
        SELECT * INTO T_Tmp_NewJobSteps FROM #Job_Steps
        SELECT * INTO T_Tmp_NewJobStepDependencies FROM #Job_Step_Dependencies
        SELECT * INTO T_Tmp_NewJobParameters FROM #Job_Parameters
    End

    Begin transaction @transName

    UPDATE T_Tasks
    SET [State] = #Jobs.[State],
        Results_Folder_Name = #Jobs.Results_Directory_Name,
        Storage_Server = #Jobs.Storage_Server,
        Instrument = #Jobs.Instrument,
        Instrument_Class = #Jobs.Instrument_Class,
        Max_Simultaneous_Captures = #Jobs.Max_Simultaneous_Captures,
        Capture_Subfolder = #Jobs.Capture_Subdirectory
    FROM T_Tasks Target
         INNER JOIN #Jobs
           ON Target.Job = #Jobs.Job

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Rollback transaction @transName
        Set @message = 'Error'
        goto Done
    End

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
        Retry_Count,
        Next_Try
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
        Retry_Count,
        Next_Try
    FROM #Job_Steps
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Rollback transaction @transName
        Set @message = 'Error'
        goto Done
    End

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
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Rollback transaction @transName
        Set @message = 'Error'
        goto Done
    End

    INSERT INTO T_Task_Parameters (
        Job,
        Parameters
    )
    SELECT
        Job,
        [Parameters]
    FROM #Job_Parameters
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Rollback transaction @transName
        Set @message = 'Error'
        goto Done
    End

    Commit transaction @transName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[move_tasks_to_main_tables] TO [DDL_Viewer] AS [dbo]
GO
