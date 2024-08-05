/****** Object:  StoredProcedure [dbo].[request_ctm_step_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[request_ctm_step_task]
/****************************************************
**
**  Desc:
**      Looks for capture task job step that is appropriate for the given processor name.
**      If found, step is assigned to caller
**
**      Task assignment will be based on:
**      Assignment restrictions:
**              Job not in hold state
**              Processor on storage machine (for step tools that require it)
**              Bionet access (for step tools that reqire it)
**              Maximum simultaneous captures for instrument (for step tools that reqire it)
**            Job-Tool priority
**            Job priority
**            Job number
**            Step Number
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/11/2010 grk - Job must be in new or busy states
**          01/20/2010 grk - Added logic for instrument/processor assignment
**          02/01/2010 grk - Added instrumentation for more logging of reject requests
**          03/12/2010 grk - Fixed problem with inadvertent throttling of step tools that aren't subject to it
**          03/21/2011 mem - Switched T_Tasks.State test from State IN (1,2) to State < 100
**          04/12/2011 mem - Now making an entry in T_Task_Step_Processing_Log for each job step assigned
**          05/18/2011 mem - No longer making an entry in T_Job_Request_Log for every request
**                         - Now showing the top @JobCountToPreview candidate steps when @infoOnly is > 0
**          07/26/2012 mem - Added parameter @serverPerspectiveEnabled
**          09/17/2012 mem - Now returning metadata for step tool DatasetQuality instead of step tool DatasetInfo
**          02/25/2013 mem - Now returning the Machine name when @infoOnly > 0
**          09/24/2014 mem - Removed reference to Machine in T_Task_Steps
**          11/05/2015 mem - Consider column Enabled when checking T_Processor_Instrument for @processorName
**          01/11/2016 mem - When looking for running capture jobs for each instrument, now ignoring job steps that started over 18 hours ago
**          01/27/2017 mem - Show additional information when @infoOnly > 0
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/01/2017 mem - Improve info displayed when @infoOnly > 0 and no jobs are available
**          08/01/2017 mem - Use THROW if not authorized
**          06/12/2018 mem - Update code formatting
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/07/2023 mem - Rename columns in temporary table
**          04/01/2023 mem - Rename procedures and functions
**          08/04/2024 mem - Rename @job argument to @job
**                         - Rename @infoOnly argument to @infoLevel
**                         - Rename @stepnumber variable to @step
**
*****************************************************/
(
    @processorName varchar(128),
    @job int = 0 OUTPUT,                        -- Job number assigned; 0 if no job available
    @message varchar(512) OUTPUT,
    @infoLevel tinyint = 0,                     -- Set to 1 to preview the job that would be returned; Set to 2 to print debug statements with preview
    @managerVersion varchar(128) = '',
    @jobCountToPreview int = 10,
    @serverPerspectiveEnabled tinyint = 0,      -- The Capture Task Manager does not set the value for this parameter, meaning it is always 0
    @returnCode varchar(64) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @jobAssigned tinyint = 0

    Declare @CandidateJobStepsToRetrieve int = 25

    Declare @excludeCaptureTasks tinyint = 0

    Set @returnCode = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'request_ctm_step_task', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    Set @processorName = ISNULL(@processorName, '')
    Set @job = 0
    Set @message = ''
    Set @infoLevel = ISNULL(@infoLevel, 0)
    Set @ManagerVersion = ISNULL(@ManagerVersion, '')
    Set @JobCountToPreview = ISNULL(@JobCountToPreview, 10)
    Set @serverPerspectiveEnabled = ISNULL(@serverPerspectiveEnabled, 0)


    If @JobCountToPreview > @CandidateJobStepsToRetrieve
        Set @CandidateJobStepsToRetrieve = @JobCountToPreview

    ---------------------------------------------------
    -- The capture task manager expects a non-zero
    -- return value if no jobs are available
    -- Code 53000 is used for this
    ---------------------------------------------------
    --
    Declare @jobNotAvailableErrorCode int = 53000

    If @infoLevel > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_ctm_step_task: Starting; make sure this is a valid processor'

    ---------------------------------------------------
    -- Make sure this is a valid processor
    -- (and capitalize it according to T_Local_Processors)
    ---------------------------------------------------
    --
    Declare @machine varchar(64)
    --
    SELECT @machine = Machine,
           @processorName = Processor_Name
    FROM T_Local_Processors
    WHERE Processor_Name = @processorName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error looking for processor in T_Local_Processors'
        Goto Done
    End

    -- check if no processor found?
    If @myRowCount = 0
    Begin
        Set @message = 'Processor not defined in T_Local_Processors: ' + @processorName
        Set @myError = @jobNotAvailableErrorCode
        Goto Done
    End


    ---------------------------------------------------
    -- Show processor name and machine if @infoLevel is non-zero
    ---------------------------------------------------
    --
    If @infoLevel <> 0
        SELECT 'Processor and Machine Info' as Information, @processorName AS Processor, @infoLevel AS InfoOnlyLevel, @Machine as Machine

    ---------------------------------------------------
    -- Update processor's request timestamp
    -- (to show when the processor was most recently active)
    ---------------------------------------------------
    --
    If @infoLevel = 0
    Begin
        UPDATE T_Local_Processors
        Set Latest_Request = GETDATE(),
            Manager_Version = @ManagerVersion
        WHERE Processor_Name = @processorName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error updating latest processor request time'
            Goto Done
        End
    End

    ---------------------------------------------------
    -- Get list of step tools currently assigned to processor
    -- active tools that are presently handled by this processor
    -- (don't use tools that require bionet if processor machine doesn't have it)
    ---------------------------------------------------
    --
    CREATE TABLE #AvailableProcessorTools
    (
        Tool_Name varchar(64),
        Tool_Priority TINYINT,
        Only_On_Storage_Server CHAR(1),
        Instrument_Capacity_Limited CHAR(1),
        Bionet_OK CHAR(1),
        Processor_Assignment_Applies CHAR(1)
    )
    --
    INSERT INTO #AvailableProcessorTools( Tool_Name,
                                          Tool_Priority,
                                          Only_On_Storage_Server,
                                          Instrument_Capacity_Limited,
                                          Bionet_OK,
                                          Processor_Assignment_Applies )
    SELECT ProcTool.Tool_Name,
           ProcTool.Priority,
           Tools.Only_On_Storage_Server,
           Tools.Instrument_Capacity_Limited,
           CASE
               WHEN (Bionet_Required = 'Y') AND
                    (Bionet_Available <> 'Y') THEN 'N'
               Else 'Y'
           End AS Bionet_OK,
           Tools.Processor_Assignment_Applies
    FROM T_Local_Processors LP
         INNER JOIN T_Processor_Tool ProcTool
           ON LP.Processor_Name = ProcTool.Processor_Name
         INNER JOIN T_Step_Tools Tools
           ON ProcTool.Tool_Name = Tools.Name
         INNER JOIN T_Machines M
           ON LP.Machine = M.Machine
    WHERE (ProcTool.Enabled > 0) AND
          (LP.State = 'E') AND
          (LP.Processor_Name = @processorName)

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error getting processor tools'
        Goto Done
    End

    If @infoLevel > 1
    Begin
        Select 'Tools enabled for this processor' as Information, *
        FROM #AvailableProcessorTools
        ORDER BY Tool_Name
    End

    ---------------------------------------------------
    -- Bail out if no tools available, and we are not
    -- in infoOnly mode
    ---------------------------------------------------
    --
    Declare @num_tools int = 0
    SELECT @num_tools = COUNT(*)
    FROM #AvailableProcessorTools
    --
    If @infoLevel = 0 AND @num_tools = 0
    Begin
          Set @message = 'No tools presently available for processor "'+ @processorName +'"'
          Set @myError = @jobNotAvailableErrorCode
          Goto Done
    End

    ---------------------------------------------------
    -- Get a list of instruments and their current loading
    -- (steps in busy state that have step tools that are
    -- instrument capacity limited tools, summed by Instrument)
    --
    -- Ignore job steps that started over 18 hours ago; they're probably stalled
    --
    -- In practice, the only step tool that is instrument-capacity limited is DatasetCapture
    ---------------------------------------------------
    --
    CREATE TABLE #InstrumentLoading
    (
        Instrument varchar(64),
        Captures_In_Progress int,
        Max_Simultaneous_Captures int,
        Available_Capacity int
    )
    --
    INSERT INTO #InstrumentLoading( Instrument,
                                    Captures_In_Progress,
                                    Max_Simultaneous_Captures,
                                    Available_Capacity )
    SELECT J.Instrument,
           COUNT(*) AS Captures_In_Progress,
           J.Max_Simultaneous_Captures,
           Available_Capacity = J.Max_Simultaneous_Captures - COUNT(*)
    FROM T_Task_Steps JS
         INNER JOIN T_Step_Tools Tools
           ON JS.Tool = Tools.Name
         INNER JOIN T_Tasks J
           ON JS.Job = J.Job
    WHERE JS.State = 4 AND
          Tools.Instrument_Capacity_Limited = 'Y' AND
          JS.Start >= dateAdd(hour, -18, GetDate())
    GROUP BY J.Instrument, J.Max_Simultaneous_Captures
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
          Set @message = 'Error populating #InstrumentLoading temp table'
          Goto Done
    End

    ---------------------------------------------------
    -- Is processor assigned to any instrument?
    ---------------------------------------------------
    --
    Declare @processorIsAssigned int = 0
    Declare @processorLockedToInstrument tinyint = 0
    --
    SELECT @processorIsAssigned = COUNT(*)
    FROM T_Processor_Instrument
    WHERE Processor_Name = @processorName AND
          Enabled > 0

    ---------------------------------------------------
    -- Get list of instruments that have processor assignments
    ---------------------------------------------------
    --
    CREATE TABLE #InstrumentProcessor
    (
        Instrument varchar(64),
        Assigned_To_This_Processor int,
        Assigned_To_Any_Processor int
    )

    INSERT INTO #InstrumentProcessor( Instrument,
                                      Assigned_To_This_Processor,
                                      Assigned_To_Any_Processor )
    SELECT Instrument_Name AS Instrument,
           SUM(CASE
                   WHEN Processor_Name = @processorName THEN 1
                   Else 0
               End) AS Assigned_To_This_Processor,
           SUM(1) AS Assigned_To_Any_Processor
    FROM T_Processor_Instrument
    WHERE Enabled = 1
    GROUP BY Instrument_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating #InstrumentProcessor temp table'
        Goto Done
    End

    If @processorIsAssigned = 0 And @serverPerspectiveEnabled <> 0
    Begin
        -- The capture task managers running on the Proto-x servers have "perspective" = "server"
        -- During dataset capture, if perspective="server" then the manager will use dataset paths of the form E:\Exact04\2012_1
        --   In contrast, CTM's with  perspective="client" will use dataset paths of the form \\proto-5\Exact04\2012_1
        -- Therefore, capture tasks that occur on the Proto-x servers should be limited to instruments whose data is stored on the same server as the CTM
        --   This is accomplished via one or more mapping rows in table T_Processor_Instrument in the DMS_Capture DB
        -- If a capture task manager running on a Proto-x server has the DatasetCapture tool enabled, yet does not have an entry in T_Processor_Instrument,
        --   then we do not allow capture tasks to be assigned (to thus avoid drive path problems)
        Set @excludeCaptureTasks = 1

        If @infoLevel > 0
            Print 'Note: setting @excludeCaptureTasks=1 because this processor does not have any entries in T_Processor_Instrument yet @serverPerspectiveEnabled=1'
    End

    If Exists (Select * From #InstrumentProcessor WHERE Assigned_To_This_Processor > 0)
    Begin
        Set @processorLockedToInstrument = 1
        If @infoLevel > 1
        Begin
            SELECT 'Instruments locked to this processor' AS Information,
                   @processorName AS Processor,
                   *
            FROM #InstrumentProcessor
            ORDER BY Instrument
        End
    End

    ---------------------------------------------------
    -- Table variable to hold job step candidates
    -- for possible assignment
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_CandidateJobSteps
    (
        Seq smallint IDENTITY(1, 1) NOT NULL,
        Job int,
        Step int,
        Job_Priority int,
        Tool varchar(64),
        Tool_Priority int
    )

    ---------------------------------------------------
    -- Get list of viable job step assignments organized
    -- by processor in order of assignment priority
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_CandidateJobSteps( Job,
                                        Step,
                                        Job_Priority,
                                        Tool,
                                        Tool_Priority )
    SELECT TOP ( @CandidateJobStepsToRetrieve ) J.Job,
                                                JS.Step,
                                                J.Priority,
                                                JS.Tool,
                                                APT.Tool_Priority
    FROM T_Task_Steps JS
         INNER JOIN dbo.T_Tasks J
           ON JS.Job = J.Job
         INNER JOIN #AvailableProcessorTools APT
           ON JS.Tool = APT.Tool_Name
         LEFT OUTER JOIN #InstrumentProcessor IP
           ON IP.Instrument = J.Instrument
         LEFT OUTER JOIN #InstrumentLoading IL
           ON IL.Instrument = J.Instrument
    WHERE GETDATE() > JS.Next_Try AND
          (JS.State = 2) AND
          APT.Bionet_OK = 'Y' AND
          J.State < 100 AND
          NOT (APT.Only_On_Storage_Server = 'Y' AND Storage_Server <> @machine) AND
          NOT (@excludeCaptureTasks = 1 AND JS.Tool = 'DatasetCapture') AND
          (APT.Instrument_Capacity_Limited = 'N'  OR (NOT ISNULL(IL.Available_Capacity, 1) < 1)) AND
          (APT.Processor_Assignment_Applies = 'N' OR (
             (@processorIsAssigned > 0 AND ISNULL(IP.Assigned_To_This_Processor, 0) > 0) OR
             (@processorIsAssigned = 0 AND ISNULL(IP.Assigned_To_Any_Processor,  0) = 0)))
    ORDER BY APT.Tool_Priority, J.Priority, J.Job, JS.Step
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    Declare @num_candidates int = @myRowCount

    ---------------------------------------------------
    -- Bail out if no steps available, and we are not
    -- in infoOnly mode
    ---------------------------------------------------
    --
    If @infoLevel = 0 AND @num_candidates = 0
    Begin
        Set @message = 'No candidates presently available'
        Set @myError = @jobNotAvailableErrorCode
        Goto Done
    End

    ---------------------------------------------------
    -- Try to assign step
    ---------------------------------------------------

    If @infoLevel > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_ctm_step_task: Start transaction'

    ---------------------------------------------------
    -- Start a transaction
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'request_ctm_step_task'

    Begin TRANSACTION @transName

    ---------------------------------------------------
    -- Get best step candidate in order of preference:
    --   Assignment priority (prefer directly associated jobs to general pool)
    --   Job-Tool priority
    --   Overall job priority
    --   Later steps over earler steps
    --   Job number
    ---------------------------------------------------
    --
    Declare @step int = 0
    Declare @stepTool varchar(64)
    --
    SELECT TOP 1 @job = TJS.Job,
                 @step = TJS.Step,
                 @stepTool = TJS.Tool
    FROM T_Task_Steps TJS WITH ( HOLDLOCK )
         INNER JOIN #Tmp_CandidateJobSteps CJS
       ON CJS.Job = TJS.Job AND
          CJS.Step = TJS.Step
    WHERE TJS.State = 2
    ORDER BY Seq
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        ROLLBACK TRANSACTION @transName
        Set @message = 'Error searching for job step'
        Goto Done
    End

    If @myRowCount > 0
        Set @jobAssigned = 1

    ---------------------------------------------------
    -- If a job step was assigned and
    -- if we are not in infoOnly mode
    -- then update the step state to Running
    ---------------------------------------------------
    --
    If @jobAssigned = 1 AND @infoLevel = 0
    Begin --<e>
        UPDATE T_Task_Steps
        Set State = 4,
            Processor = @processorName,
            Start = GETDATE(),
            Finish = NULL
        WHERE Job = @job AND
              Step = @step
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            ROLLBACK TRANSACTION @transName
            Set @message = 'Error updating job step'
            Goto Done
        End
    End --<e>

    -- update was successful
    COMMIT TRANSACTION @transName

    ---------------------------------------------------
    -- Temp table to hold job parameters
    ---------------------------------------------------

    CREATE TABLE #ParamTab
    (
        [Section] varchar(128),
        [Name] varchar(128),
        [Value] varchar(MAX)
    )

    If @jobAssigned = 1
    Begin

        If @infoLevel = 0
        Begin
            ---------------------------------------------------
            -- Add entry to T_Task_Step_Processing_Log
            ---------------------------------------------------

            INSERT INTO T_Task_Step_Processing_Log (Job, Step, Processor)
            VALUES (@job, @step, @processorName)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        If @infoLevel > 1
            Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_ctm_step_task: Call get_task_step_params'

        ---------------------------------------------------
        -- Job was assigned; get step parameters
        ---------------------------------------------------

        -- Populate #ParamTab with job step parameters
        EXEC @myError = get_task_step_params @job, @step, @message OUTPUT, @DebugMode = @infoLevel

        If @infoLevel <> 0 AND LEN(@message) = 0
            Set @message = 'Job ' + CONVERT(varchar(12), @job) + ', Step '+ CONVERT(varchar(12), @step) + ' would be assigned to ' + @processorName
    End
    Else
    Begin
        ---------------------------------------------------
        -- No job step found; update @myError and @message
        ---------------------------------------------------
        --
      Set @myError = @jobNotAvailableErrorCode
      Set @message = 'No available jobs'

    End

    ---------------------------------------------------
    -- dump candidate list if in infoOnly mode
    ---------------------------------------------------
    --
    If @infoLevel <> 0
    Begin
        If @infoLevel > 1
            Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_ctm_step_task: Preview results'

        Declare @machineLockedStepTools varchar(64) = null

        SELECT @machineLockedStepTools = Coalesce(@machineLockedStepTools + ', ' + [Name], [Name])
        FROM T_Step_Tools
        WHERE (Only_On_Storage_Server = 'Y')

        -- Preview the next @JobCountToPreview available jobs

        If Exists (Select * From #Tmp_CandidateJobSteps)
        Begin
            SELECT TOP ( @JobCountToPreview ) 'Candidate Job Steps for ' + @processorName AS Information,
                   Seq,
                   Tool_Priority,
                   Job_Priority,
                   CJS.Job,
                   Step,
                   Tool,
                   J.Dataset
            FROM #Tmp_CandidateJobSteps CJS
                 INNER JOIN T_Tasks J
                   ON CJS.Job = J.Job
        End
        Else
        Begin
            SELECT 'Candidate Job Steps for ' + @processorName AS Information,
                   @machine AS Machine,
                   'No candidate job steps found (jobs with step tools ' + @machineLockedStepTools +
                   ' only assigned if dataset stored on ' + @machine + ')' AS Message,
                   CASE
                       WHEN @processorLockedToInstrument > 0 THEN 'Processor locked to instrument'
                       ELSE ''
                   END AS Warning

        End

        ---------------------------------------------------
        -- dump candidate list if infoOnly mode is 2 or higher
        ---------------------------------------------------
        --
        If @infoLevel >= 2
        Begin
            EXEC request_ctm_step_task_explanation @processorName, @processorIsAssigned, @infoLevel, @machine
        End

    End

    ---------------------------------------------------
    -- Output job parameters as resultset
    ---------------------------------------------------
    --
    SELECT [Name] AS Parameter,
           [Value]
    FROM #ParamTab

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Set @returnCode = Cast(@myError As varchar(64))
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[request_ctm_step_task] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[request_ctm_step_task] TO [DMS_SP_User] AS [dbo]
GO
