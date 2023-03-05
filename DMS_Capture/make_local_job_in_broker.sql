/****** Object:  StoredProcedure [dbo].[make_local_job_in_broker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_local_job_in_broker]
/****************************************************
**
**  Desc:
**      Create capture job directly in broker database
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**          05/03/2010 grk - Initial release
**          05/25/2011 mem - Updated call to create_steps_for_job and removed Priority from #Job_Steps
**          09/24/2014 mem - Rename Job in T_Task_Step_Dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/17/2019 mem - Switch from folder to directory
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @scriptName varchar(64),
    @priority int,
    @jobParamXML xml,
    @comment varchar(512),
    @debugMode tinyint = 0,            -- When setting this to 1, you can optionally specify a job using @existingJob to view the steps that would be created for that job    Declare @job int
    @job int OUTPUT,
    @resultsDirectoryName varchar(128) OUTPUT,
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_WARNINGS ON
    SET ANSI_PADDING ON

    BEGIN TRY

    ---------------------------------------------------
    -- create temporary tables to accumulate job steps
    -- job step dependencies, and job parameters for
    -- jobs being created
    ---------------------------------------------------

    CREATE TABLE #Jobs (
        [Job] int NOT NULL,
        [Priority] int NULL,
        [Script] varchar(64) NULL,
        [State] int NOT NULL,
        [Dataset] varchar(128) NULL,
        [Dataset_ID] int NULL,
        [Results_Directory_Name] varchar(128) NULL,
        Storage_Server varchar(64) NULL,
        Instrument varchar(24) NULL,
        Instrument_Class VARCHAR(32) NULL,
        Max_Simultaneous_Captures int NULL,
        Capture_Subdirectory varchar(255) NULL
    )

--    CREATE INDEX #IX_Jobs_Job ON #Jobs (Job)

    CREATE TABLE #Job_Steps (
        [Job] int NOT NULL,
        [Step_Number] int NOT NULL,
        [Step_Tool] varchar(64) NOT NULL,
        [CPU_Load] [smallint] NULL,
        [Dependencies] tinyint NULL ,
        [Filter_Version] smallint NULL,
        [Signature] int NULL,
        [State] tinyint NULL ,
        [Input_Directory_Name] varchar(128) NULL,
        [Output_Directory_Name] varchar(128) NULL,
        [Processor] varchar(128) NULL,
        Special_Instructions varchar(128) NULL,
        Holdoff_Interval_Minutes smallint NOT NULL,
        Retry_Count smallint NOT NULL
    )

--    CREATE INDEX #IX_Job_Steps_Job_Step ON #Job_Steps (Job, Step_Number)

    CREATE TABLE #Job_Step_Dependencies (
        [Job] int NOT NULL,
        [Step_Number] int NOT NULL,
        [Target_Step_Number] int NOT NULL,
        [Condition_Test] varchar(50) NULL,
        [Test_Value] varchar(256) NULL,
        [Enable_Only] tinyint NULL
    )

--    CREATE INDEX #IX_Job_Step_Dependencies_Job_Step ON #Job_Step_Dependencies (Job, Step_Number)

    CREATE TABLE #Job_Parameters (
        [Job] int NOT NULL,
        [Parameters] xml NULL
    )

--    CREATE INDEX #IX_Job_Parameters_Job ON #Job_Parameters (Job)


    ---------------------------------------------------
    -- dataset
    ---------------------------------------------------

    Declare @datasetName varchar(128)
    Declare @datasetID int
    SET @datasetName = 'na'
    SET @datasetID = 0

    ---------------------------------------------------
    -- script
    ---------------------------------------------------
    --
    Declare @paramsXML xml
    Declare @scriptXML xml
    Declare @tag varchar(8)
    set @tag = 'unk'
    --
    --
    -- get contents of script and tag for results Directory name
    SELECT @scriptXML = Contents, @tag = Results_Tag
    FROM T_Scripts
    WHERE Script = @scriptName

    ---------------------------------------------------
    -- Add job to temp table
    ---------------------------------------------------
    --
    INSERT INTO #Jobs( Job,
                       Priority,
                       Script,
                       State,
                       Dataset,
                       Dataset_ID,
                       Results_Directory_Name )
    VALUES(@job,
           @priority,
           @scriptName,
           1,
           @datasetName,
           @datasetID,
           NULL)


    ---------------------------------------------------
    -- save job parameters as XML into temp table
    ---------------------------------------------------
    -- FUTURE: need to get set of parameters normally provided by get_job_param_table,
    -- except for the job specifc ones which need to be provided as initial content of @jobParamXML
    --
    INSERT INTO #Job_Parameters (Job, Parameters)
    VALUES (@job, @jobParamXML)


    ---------------------------------------------------
    -- create the basic job structure (steps and dependencies)
    -- Details are stored in #Job_Steps and #Job_Step_Dependencies
    ---------------------------------------------------
    --
    exec @myError = create_steps_for_job @job, @scriptXML, @resultsDirectoryName, @message output

    ---------------------------------------------------
    -- Perform a mixed bag of operations on the jobs
    -- in the temporary tables to finalize them before
    --  copying to the main database tables
    ---------------------------------------------------
    --
    exec @myError = finish_job_creation @job, @message output

    ---------------------------------------------------
    -- transaction
    ---------------------------------------------------
    Declare @transName varchar(32)
    set @transName = 'make_local_job_in_broker'

    ---------------------------------------------------
    -- move temp tables to main tables
    ---------------------------------------------------
    If @DebugMode = 0
    begin

        begin transaction @transName

        -- move_jobs_to_main_tables sproc assumes that T_Tasks table entry is already there
        --
        INSERT INTO T_Tasks
            (
              Priority,
              Script,
              State,
              Dataset,
              Dataset_ID,
              Transfer_Folder_Path,
              Comment,
              Storage_Server
            )
        VALUES
            (
              @priority,
              @scriptName,
              1,
              @datasetName,
              @datasetID,
              NULL,
              @comment,
              NULL
            )

        set @job = IDENT_CURRENT('T_Tasks')

        UPDATE #Jobs  SET Job = @Job
        UPDATE #Job_Steps  SET Job = @Job
        UPDATE #Job_Step_Dependencies  SET Job = @Job
        UPDATE #Job_Parameters  SET Job = @Job

        exec @myError = move_jobs_to_main_tables @message output

        commit transaction @transName
    end

    ---------------------------------------------------
    -- FUTURE: commit transaction
    ---------------------------------------------------

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    If @DebugMode <> 0
    begin
        SELECT '#Jobs' AS T, * FROM #Jobs
        SELECT '#Job_Steps' AS T, * FROM #Job_Steps
        SELECT '#Job_Step_Dependencies' AS T, * FROM #Job_Step_Dependencies
        SELECT '#Job_Parameters' AS T, * FROM #Job_Parameters
    end

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'make_local_job_in_broker'
    END CATCH
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[make_local_job_in_broker] TO [DDL_Viewer] AS [dbo]
GO
