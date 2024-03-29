/****** Object:  StoredProcedure [dbo].[create_task_steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_task_steps]
/****************************************************
**
**  Desc:
**      Make entries in the capture task job steps table and the
**      job step dependency table for each newly added capture task job,
**      as defined by the script for that job
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/25/2011 mem - Updated call to create_steps_for_task
**          04/09/2013 mem - Added additional comments
**          09/24/2014 mem - Rename Job in T_Task_Step_Dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          09/17/2015 mem - Added parameter @infoOnly
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/07/2023 mem - Rename columns in temporary tables
**          04/01/2023 mem - Rename procedures and functions
**          11/01/2023 bcg - Add special handling for script 'LCDatasetCapture' to skip step creation when the target dataset does not have an LC instrument defined
**          11/02/2023 bcg - Delete job parameters from #Job_Parameters when skipping a capture task job
**          11/02/2023 mem - Remove unused modes 'ExtendExistingJob' and 'UpdateExistingJob'
**
*****************************************************/
(
    @message varchar(512) output,
    @debugMode tinyint = 0,                             -- When setting this to 1, you can optionally specify a capture task job using @existingJob to view the steps that would be created for that job
    @mode varchar(32) = 'CreateFromImportedJobs',       -- Modes: CreateFromImportedJobs
    @existingJob int = 0,                               -- Only used if @debugMode <> 0
    @extensionScriptNameList varchar(512) = '',
    @maxJobsToProcess int = 0,
    @logIntervalThreshold int = 15,         -- If this procedure runs longer than this threshold, then status messages will be posted to the log
    @loggingEnabled tinyint = 0,            -- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @LogIntervalThreshold seconds elapse
    @loopingUpdateInterval int = 5,         -- Seconds between detailed logging while looping through the dependencies,
    @infoOnly tinyint = 0
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @StepCount int = 0
    Declare @StepCountNew int = 0

    Declare @MaxJobsToAdd int

    Declare @StartTime datetime
    Declare @LastLogTime datetime
    Declare @StatusMessage varchar(512)

    Declare @JobCountToProcess int
    Declare @JobsProcessed int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @DebugMode = IsNull(@DebugMode, 0)
    Set @existingJob = IsNull(@existingJob, 0)
    Set @mode = IsNull(@mode, '')
    Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

    If Not @mode In ('CreateFromImportedJobs')
    Begin
        Set @message = 'Unknown mode: ' + @Mode
        Set @myError = 50001
        Goto Done
    End

    Set @StartTime = GetDate()
    Set @LoggingEnabled = IsNull(@LoggingEnabled, 0)
    Set @LogIntervalThreshold = IsNull(@LogIntervalThreshold, 15)
    Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)

    If @LogIntervalThreshold = 0
        Set @LoggingEnabled = 1

    If @LoopingUpdateInterval < 2
        Set @LoopingUpdateInterval = 2

    If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
    Begin
        Set @StatusMessage = 'Entering'
        exec post_log_entry 'Progress', @StatusMessage, 'create_task_steps'
    End

    ---------------------------------------------------
    -- Create temporary tables to accumulate capture task job steps,
    -- job step dependencies, and job parameters
    ---------------------------------------------------

    CREATE TABLE #Jobs (
        Job int NOT NULL,
        Priority int NULL,
        Script varchar(64) NULL,
        State int NOT NULL,
        Dataset varchar(128) NULL,
        Dataset_ID int NULL,
        Results_Directory_Name varchar(128) NULL,
        Storage_Server varchar(64) NULL,
        Instrument varchar(24) NULL,
        Instrument_Class varchar(32),
        Max_Simultaneous_Captures int NULL,
        Capture_Subdirectory varchar(255) NULL
    )

    CREATE INDEX #IX_Jobs_Job ON #Jobs (Job)

    CREATE TABLE #Job_Steps (
        Job int NOT NULL,
        Step int NOT NULL,
        Tool varchar(64) NOT NULL,
        CPU_Load smallint NULL,
        Dependencies tinyint NULL ,
        Filter_Version smallint NULL,
        Signature int NULL,
        State tinyint NULL ,
        Input_Directory_Name varchar(128) NULL,
        Output_Directory_Name varchar(128) NULL,
        Processor varchar(128) NULL,
        Special_Instructions varchar(128) NULL,
        Holdoff_Interval_Minutes smallint NOT NULL,
        Retry_Count smallint NOT NULL,
        Next_Try datetime NULL default GetDate()
    )

    CREATE INDEX #IX_Job_Steps_Job_Step ON #Job_Steps (Job, Step)

    CREATE TABLE #Job_Step_Dependencies (
        Job int NOT NULL,
        Step int NOT NULL,
        Target_Step int NOT NULL,
        Condition_Test varchar(50) NULL,
        Test_Value varchar(256) NULL,
        Enable_Only tinyint NULL
    )

    CREATE INDEX #IX_Job_Step_Dependencies_Job_Step ON #Job_Step_Dependencies (Job, Step)

    CREATE TABLE #Job_Parameters (
        Job int NOT NULL,
        Parameters xml NULL
    )

    CREATE INDEX #IX_Job_Parameters_Job ON #Job_Parameters (Job)

    ---------------------------------------------------
    -- Get capture task jobs that need to be processed
    ---------------------------------------------------

    If @mode = 'CreateFromImportedJobs'
    Begin
        If @MaxJobsToProcess > 0
            Set @MaxJobsToAdd = @MaxJobsToProcess
        Else
            Set @MaxJobsToAdd = 1000000

        If @DebugMode = 0 Or (@DebugMode <> 0 And @existingJob = 0)
        Begin
            INSERT INTO #Jobs(
                Job,
                Priority,
                Script,
                State,
                Dataset,
                Dataset_ID,
                Results_Directory_Name,
                Storage_Server,
                Instrument,
                Instrument_Class,
                Max_Simultaneous_Captures,
                Capture_Subdirectory
            )
            SELECT TOP ( @MaxJobsToAdd )
                   TJ.Job,
                   TJ.Priority,
                   TJ.Script,
                   TJ.State,
                   TJ.Dataset,
                   TJ.Dataset_ID,
                   TJ.Results_Folder_Name As Results_Directory_Name,
                   VDD.Storage_Server_Name,
                   VDD.Instrument_Name,
                   VDD.Instrument_Class,
                   VDD.Max_Simultaneous_Captures,
                   VDD.Capture_Subfolder As Capture_Subdirectory
            FROM T_Tasks TJ
                 INNER JOIN V_DMS_Get_Dataset_Definition AS VDD
                   ON TJ.Dataset_ID = VDD.Dataset_ID
            WHERE TJ.State = 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Error trying to get capture task jobs for processing'
                goto Done
            End
        End

        If @DebugMode <> 0 And @existingJob <> 0
        Begin
            INSERT INTO #Jobs(
                Job,
                Priority,
                Script,
                State,
                Dataset,
                Dataset_ID,
                Results_Directory_Name
            )
            SELECT Job,
                   Priority,
                   Script,
                   State,
                   Dataset,
                   Dataset_ID,
                   NULL
            FROM T_Tasks
            WHERE Job = @existingJob
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @message = 'Capture task job ' + Convert(varchar(12), @existingJob) + ' not found in T_Tasks; unable to continue debugging'
                Set @myError = 50000
                goto Done
            End
        End
    End

    ---------------------------------------------------
    -- Loop through capture task jobs and process them into temp tables
    ---------------------------------------------------

    Declare @job int
    Declare @prevJob int
    Declare @scriptName varchar(64)
    Declare @resultsDirectoryName varchar(128)
    Declare @datasetID int
    Declare @done tinyint
    Declare @scriptXML2 xml
    Declare @instrumentName varchar(256)

    SELECT @JobCountToProcess = COUNT(*)
    FROM #Jobs
    --
    Set @JobCountToProcess = IsNull(@JobCountToProcess, 0)

    Set @done = 0
    Set @prevJob = 0
    Set @JobsProcessed = 0
    Set @LastLogTime = GetDate()

    While @done = 0
    Begin
        ---------------------------------------------------
        -- Get next unprocessed capture task job
        ---------------------------------------------------
        --
        Set @job = 0

        SELECT TOP 1 @job = Job,
                     @scriptName = Script,
                     @datasetID = Dataset_ID,
                     @resultsDirectoryName = ISNULL(Results_Directory_Name, '')
        FROM #Jobs
        WHERE Job > @prevJob
        ORDER BY Job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error trying to get next unitiated job'
            goto Done
        End

        ---------------------------------------------------
        -- If no capture task job was found, we are done
        -- Otherwise, process the job
        ---------------------------------------------------

        If @job = 0
            Set @done = 1
        Else
        Begin
            -- Set up to get next capture task job on next pass
            Set @prevJob = @job

            Declare @paramsXML xml
            Declare @scriptXML xml
            Declare @tag varchar(8) = 'unk'

            -- Get contents of script and tag for results directory name
            SELECT @scriptXML = Contents, @tag = Results_Tag
            FROM T_Scripts
            WHERE Script = @scriptName

            -- Add additional script if extending an existing job
            If @extensionScriptNameList <> ''
            Begin
                Set @scriptXML2 = ''

                SELECT @scriptXML2 = Contents
                FROM T_Scripts
                WHERE Script = @extensionScriptNameList -- FUTURE: process as list

                Set @scriptXML = convert(varchar(2048), @scriptXML) + convert(varchar(2048), @scriptXML2)
            End

            -- Get parameters for the capture task job (and also store in #Job_Parameters)
            -- Parameters are returned in @paramsXML
            Exec @myError = create_parameters_for_task @job, @datasetID, @scriptName, @paramsXML output, @message output, @DebugMode = @DebugMode

            -- If the script is 'LCDatasetCapture' and the instrument name is not defined, set the task state to 'Skipped', add a comment, and don't create steps for the task
            If @scriptName = 'LCDatasetCapture'
            Begin
                Set @instrumentName = ''

                SELECT @instrumentName = x.i.value('@Value', 'nvarchar(256)')
                FROM @paramsXML.nodes('./Param') AS x(i)
                WHERE x.i.value('@Section', 'nvarchar(256)') = 'JobParameters'
                  AND x.i.value('@Name', 'nvarchar(256)') = 'Instrument_Name'

                If LTrim(RTrim(Coalesce(@instrumentName, ''))) = ''
                Begin
                    UPDATE T_Tasks
                    SET State = 15, -- Skipped
                        Comment = 'No instrument name found matching LC cart name'
                    WHERE Job = @job

                    UPDATE #Jobs
                    SET State = 15
                    WHERE Job = @job

                    DELETE FROM #Job_Parameters
                    WHERE Job = @job

                    goto NoSteps
                End
            End

            -- Create the basic capture task job structure (steps and dependencies)
            -- Details are stored in #Job_Steps and #Job_Step_Dependencies

            Exec @myError = create_steps_for_task @job, @scriptXML, @resultsDirectoryName, @message output

            If @DebugMode <> 0
            Begin
                SELECT @StepCount = COUNT(*) FROM #Job_Steps
                SELECT * FROM #Job_Steps
                SELECT * FROM #Job_Step_Dependencies
            End

            -- Perform a mixed bag of operations on the capture task jobs in the temporary tables to finalize them before
            -- copying to the main database tables
            Exec @myError = finish_task_creation @job, @message output

            If @scriptName = 'LCDatasetCapture'
            Begin
                -- Set a default delayed start for LCDatasetCapture steps; we want to give the 'DatasetArchive' task a chance to run before the 'LCDatasetCapture' task starts
                -- This can just be bulk-applied to all steps for this capture task job
                UPDATE #Job_Steps
                SET Next_Try = DATEADD(minute, 30, GetDate())
                WHERE Job = @job
            End

            Set @JobsProcessed = @JobsProcessed + 1
        End

NoSteps:
        If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
        Begin
            -- Make sure @LoggingEnabled is 1
            Set @LoggingEnabled = 1

            Set @StatusMessage = '... Creating job steps: ' + Convert(varchar(12), @JobsProcessed) + ' / ' + Convert(varchar(12), @JobCountToProcess)
            Exec post_log_entry 'Progress', @StatusMessage, 'create_task_steps'
            Set @LastLogTime = GetDate()
        End

    End

    ---------------------------------------------------
    -- We've got new capture task jobs in temp tables - what to do?
    ---------------------------------------------------

    If @infoOnly = 0
    Begin
        If @mode = 'CreateFromImportedJobs'
        Begin
            -- Copy data from the following temp tables into actual database tables:
            --     #Jobs
            --     #Job_Steps
            --     #Job_Step_Dependencies
            --     #Job_Parameters
            exec move_tasks_to_main_tables @message output, @DebugMode
        End

    End

    If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
    Begin
        Set @LoggingEnabled = 1
        Set @StatusMessage = 'create_task_steps complete'
        Exec post_log_entry 'Progress', @StatusMessage, 'create_task_steps'
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
    Begin
        Set @StatusMessage = 'Exiting'
        Exec post_log_entry 'Progress', @StatusMessage, 'create_task_steps'
    End

    If @DebugMode <> 0
    Begin
        SELECT * FROM #Jobs
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_task_steps] TO [DDL_Viewer] AS [dbo]
GO
