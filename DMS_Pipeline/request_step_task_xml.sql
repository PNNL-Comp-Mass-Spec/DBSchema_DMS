/****** Object:  StoredProcedure [dbo].[request_step_task_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[request_step_task_xml]
/****************************************************
**
**  Desc:
**      Looks for analysis job step that is appropriate for the given Processor Name.
**      If found, step is assigned to caller
**
**      Job assignment will be based on:
**      Assignment type:
**         Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
**         Directly associated steps ('Specific Association', aka Association_Type=2):
**         Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
**         Non-associated steps ('Non-associated', aka Association_Type=3):
**         Generic processing steps ('Non-associated Generic', aka Association_Type=4):
**         No processing load available on machine, aka Association_Type=101 (disqualified)
**         Transfer tool steps for jobs that are in the midst of an archive operation, aka Association_Type=102 (disqualified)
**         Specifically assigned to alternate processor, aka Association_Type=103 (disqualified)
**         Too many recently started job steps for the given tool, aka Association_Type=104 (disqualified)
**      Job-Tool priority
**      Job priority
**      Job number
**      Step Number
**      Max_Job_Priority for the step tool associated with a manager
**      Next_Try
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          08/23/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          12/03/2008 grk - included processor-tool priority in assignement logic
**          12/04/2008 mem - Now returning @jobNotAvailableErrorCode if @processorName is not in T_Local_Processors
**          12/11/2008 mem - Rearranged preference order for job assignment priorities
**          12/11/2008 grk - Rewrote to use tool/processor priority in assignment logic
**          12/29/2008 mem - Now setting Finish to Null when a job step's state changes to 4=Running
**          01/13/2009 mem - Added parameter AnalysisManagerVersion (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          01/14/2009 mem - Now checking for T_Jobs.State = 8 (holding)
**          01/15/2009 mem - Now previewing the next 10 available jobs when @infoOnly <> 0 (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          01/25/2009 mem - Now checking for Enabled > 0 in T_Processor_Tool
**          02/09/2009 mem - Altered job step ordering to account for parallelized Inspect jobs
**          02/18/2009 grk - Populating candidate table with single query ("big-bang") instead of multiple queries
**          02/26/2009 mem - Now making an entry in T_Job_Step_Processing_Log for each job step assigned
**          05/14/2009 mem - Fixed logic that checks whether @cpuLoadExceeded should be non-zero
**                         - Updated to report when a job is invalid for this processor, but is specifically associated with another processor (Association_Type 103)
**          06/02/2009 mem - Optimized Big-bang query (which populates #Tmp_CandidateJobSteps) due to high LockRequest/sec rates when we have thousands of active jobs (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - Added parameter @useBigBangQuery to allow for disabling use of the Big-Bang query
**          06/03/2009 mem - When finding candidate tasks, now treating Results_Transfer steps as step "100" so that they are assigned first, and so that they are assigned grouped by Job when multiple Results_Transfer tasks are "Enabled" for a given job
**          08/20/2009 mem - Now checking for @Machine in T_Machines when @infoOnly is non-zero
**          09/02/2009 mem - Now using T_Processor_Tool_Groups and T_Processor_Tool_Group_Details to determine the processor tool priorities for the given processor
**          09/03/2009 mem - Now verifying that the processor is enabled and the processor tool group is enabled
**          10/12/2009 mem - Now treating enabled states <= 0 as disabled for processor tool groups
**          03/03/2010 mem - Added parameters @throttleByStartTime and @maxStepNumToThrottle
**          03/10/2010 mem - Fixed bug that ignored @maxStepNumToThrottle when updating #Tmp_CandidateJobSteps
**          08/20/2010 mem - No longer ordering by Step Descending prior to job number; this caused problems choosing the next appropriate Sequest job since Sequest_DTARefinery jobs run Sequest as step 4 while normal Sequest jobs run Sequest as step 3
**                         - Sort order is now: Association_Type, Tool_Priority, Job Priority, Favor Results_Transfer steps, Job, Step
**          09/09/2010 mem - Bumped @maxStepNumToThrottle up to 10
**                         - Added parameter @throttleAllStepTools, defaulting to 0 (meaning we will not throttle Sequest or Results_Transfer steps)
**          09/29/2010 mem - Tweaked throttling logic to move the Tool exclusion test to the outer WHERE clause
**          06/09/2011 mem - Added parameter @logSPUsage, which posts a log entry to T_SP_Usage if non-zero
**          10/17/2011 mem - Now considering Memory_Usage_MB
**          11/01/2011 mem - Changed @HoldoffWindowMinutes from 7 to 3 minutes
**          12/19/2011 mem - Now showing memory amounts in "Not enough memory available" error message
**          04/25/2013 mem - Increased @MaxSimultaneousJobCount from 10 to 75; this is feasible since the storage servers now have the DMS_LockFiles share, which is used to prioritize copying large files
**          01/10/2014 mem - Now only assigning Results_Transfer tasks to the storage server on which the dataset resides
**                         - Changed @throttleByStartTime to 0
**          09/24/2014 mem - Removed reference to Machine in T_Job_Steps
**          04/21/2015 mem - Now using column Uses_All_Cores
**          06/01/2015 mem - No longer querying T_Local_Job_Processors since we have deprecated processor groups
**                         - Also now ignoring GP_Groups and Available_For_General_Processing
**          11/18/2015 mem - Now using Actual_CPU_Load instead of CPU_Load
**          02/15/2016 mem - Re-enabled use of T_Local_Job_Processors and processor groups
**                         - Added job step exclusion using T_Local_Processor_Job_Step_Exclusion
**          05/04/2017 mem - Filter on column Next_Try
**          05/11/2017 mem - Look for jobs in state 2 or 9
**                           Commit the transaction earlier to reduce the time that a HoldLock is on table T_Job_Steps
**                           Pass @jobIsRunningRemote to get_job_step_params_xml
**          05/15/2017 mem - Consider MonitorRunningRemote when looking for candidate jobs
**          05/16/2017 mem - Do not update T_Job_Step_Processing_Log if checking the status of a remotely running job
**          05/18/2017 mem - Add parameter @remoteInfo
**          05/22/2017 mem - Limit assignment of RunningRemote jobs to managers with the same RemoteInfoID as the job
**          05/23/2017 mem - Update Remote_Start, Remote_Finish, and Remote_Progress
**          05/26/2017 mem - Treat state 9 (Running_Remote) as having a CPU_Load of 0
**          06/08/2017 mem - Remove use of column MonitorRunningRemote in T_Machines since @remoteInfo replaces it
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/03/2017 mem - Use column Max_Job_Priority in table T_Processor_Tool_Group_Details
**          02/17/2018 mem - When previewing job candidates, show jobs that would be excluded due to Next_Try
**          03/08/2018 mem - Reset Next_Try and Retry_Count when a job is assigned
**          03/14/2018 mem - When finding job steps to assign, prevent multiple managers on a given machine from analyzing the same dataset simultaneously (filtering on job started within the last 10 minutes)
**          03/29/2018 mem - Ignore CPU checks when the manager runs jobs remotely (@remoteInfoID is greater than 1 because @remoteInfo is non-blank)
**                         - Update Remote_Info_ID when assigning a new job, both in T_Job_Steps and in T_Job_Step_Processing_Log
**          02/21/2019 mem - Reset Completion_Code and Completion_Message when a job is assigned
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**          02/06/2023 bcg - Update after view column rename
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps
**          03/29/2023 mem - Add support for state 11 (Waiting_For_File)
**
*****************************************************/
(
    @processorName varchar(128),                -- Name of the processor (aka manager) requesting a job
    @jobNumber int = 0 output,                  -- Job number assigned; 0 if no job available
    @parameters varchar(max) output,            -- job step parameters (in XML)
    @message varchar(512) output,               -- Output message
    @infoOnly tinyint = 0,                      -- Set to 1 to preview the job that would be returned; if 2, will print debug statements
    @analysisManagerVersion varchar(128) = '',  -- Used to update T_Local_Processors
    @remoteInfo varchar(900) = '',              -- Provided by managers that stage jobs to run remotely; used to assure that we don't stage too many jobs at once and to assure that we only check remote progress using a manager that has the same remote info as a job step
    @jobCountToPreview int = 10,                -- The number of jobs to preview when @infoOnly >= 1
    @useBigBangQuery tinyint = 1,               -- Ignored and always set to 1 by this procedure (When non-zero, uses a single, large query to find candidate steps, which can be very expensive if there is a large number of active jobs (i.e. over 10,000 active jobs))
    @throttleByStartTime tinyint = 0,           -- Set to 1 to limit the number of job steps that can start simultaneously on a given storage server (to avoid overloading the disk and network I/O on the server); this is no longer a necessity because copying of large files now uses lock files (effective January 2013)
    @maxStepNumToThrottle int = 10,             -- Only used if @throttleByStartTime is non-zero
    @throttleAllStepTools tinyint = 0,          -- Only used if @throttleByStartTime is non-zero; when 0, will not throttle Sequest or Results_Transfer steps
    @logSPUsage tinyint = 0,
    @returnCode varchar(64) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @jobAssigned tinyint = 0

    Declare @CandidateJobStepsToRetrieve int = 15

    Declare @HoldoffWindowMinutes int
    Declare @MaxSimultaneousJobCount int

    Declare @remoteInfoID int = 0
    Declare @maxSimultaneousRunningRemoteSteps int = 0
    Declare @runningRemoteLimitReached tinyint = 0

    Set @returnCode = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'request_step_task_xml', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- These 3 hard-coded values give optimal performance
    -- (note that @useBigBangQuery overrides the value passed into this procedure)
    ---------------------------------------------------
    --
    Set @HoldoffWindowMinutes = 3                -- Typically 3
    Set @MaxSimultaneousJobCount = 75            -- Increased from 10 to 75 on 4/25/2013
    Set @useBigBangQuery = 1                     -- Always forced by this procedure to be 1

    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    Set @processorName = IsNull(@processorName, '')
    Set @jobNumber = 0
    Set @parameters = ''
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @analysisManagerVersion = IsNull(@analysisManagerVersion, '')
    Set @remoteInfo = IsNull(@remoteInfo, '')
    Set @jobCountToPreview = IsNull(@jobCountToPreview, 10)
    If @JobCountToPreview <= 0
        Set @JobCountToPreview= 10

    Set @useBigBangQuery = IsNull(@useBigBangQuery, 1)

    Set @throttleByStartTime = IsNull(@throttleByStartTime, 0)
    Set @maxStepNumToThrottle = IsNull(@maxStepNumToThrottle, 10)
    Set @throttleAllStepTools = IsNull(@throttleAllStepTools, 0)

    If @maxStepNumToThrottle < 1
        Set @maxStepNumToThrottle = 1000000

    If @jobCountToPreview > @CandidateJobStepsToRetrieve
        Set @CandidateJobStepsToRetrieve = @jobCountToPreview

    ---------------------------------------------------
    -- The analysis manager expects a non-zero
    -- return value if no jobs are available
    -- Code 53000 is used for this
    ---------------------------------------------------
    --
    Declare @jobNotAvailableErrorCode int = 53000

    If @infoOnly > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Starting; make sure this is a valid processor'

    ---------------------------------------------------
    -- Make sure this is a valid processor (and capitalize it according to T_Local_Processors)
    ---------------------------------------------------
    --
    Declare @machine varchar(64)
    Declare @availableCPUs smallint
    Declare @availableMemoryMB int
    Declare @ProcessorState char
    Declare @ProcessorID int
    Declare @Enabled smallint
    Declare @ProcessToolGroup varchar(128)
    --
    Declare @processorDoesGP int = -1
    --
    SELECT
        @processorDoesGP = 1,        -- Prior to May 2015 used: @processorDoesGP = GP_Groups
        @machine = Machine,
        @processorName = Processor_Name,
        @ProcessorState = State,
        @ProcessorID = ID
    FROM    T_Local_Processors
    WHERE    Processor_Name = @processorName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error looking for processor in T_Local_Processors'
        Goto Done
    End

    -- Check if no processor found?
    If @myRowCount = 0
    Begin
        Set @message = 'Processor not defined in T_Local_Processors: ' + @processorName
        Set @myError = @jobNotAvailableErrorCode

        INSERT INTO T_SP_Usage( Posted_By,
                                ProcessorID,
                                Calling_User )
        VALUES('request_step_task_xml', null, SUSER_SNAME() + ' Invalid processor: ' + @processorName)


        goto Done
    end

    ---------------------------------------------------
    -- Update processor's request timestamp
    -- (to show when the processor was most recently active)
    ---------------------------------------------------
    --
    If @infoOnly = 0
    Begin
        UPDATE T_Local_Processors
        SET Latest_Request = GETDATE(),
            Manager_Version = @analysisManagerVersion
        WHERE Processor_Name = @processorName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error updating latest processor request time'
            Goto Done
        End

        if IsNull(@logSPUsage, 0) <> 0
            INSERT INTO T_SP_Usage (
                            Posted_By,
                            ProcessorID,
                            Calling_User )
            VALUES('request_step_task_xml', @ProcessorID, SUSER_SNAME())

    end

    ---------------------------------------------------
    -- Abort if not enabled in T_Local_Processors
    ---------------------------------------------------
    If @ProcessorState <> 'E'
    Begin
        Set @message = 'Processor is not enabled in T_Local_Processors: ' + @processorName
        Set @myError = @jobNotAvailableErrorCode
        Goto Done
    End

    ---------------------------------------------------
    -- Make sure this processor's machine is in T_Machines
    ---------------------------------------------------
    If Not Exists (SELECT * FROM T_Machines Where Machine = @machine)
    Begin
        Set @message = 'Machine "' + @machine + '" is not present in T_Machines (but is defined in T_Local_Processors for processor "' + @processorName + '")'
        Set @myError = @jobNotAvailableErrorCode
        Goto Done
    End

    ---------------------------------------------------
    -- Lookup the number of CPUs available and amount of memory available for this processor's machine
    -- In addition, make sure this machine is a member of an enabled group
    ---------------------------------------------------
    Set @availableCPUs = 0
    Set @availableMemoryMB = 0
    Set @Enabled = 0
    Set @ProcessToolGroup = ''

    SELECT @availableCPUs = M.CPUs_Available,
           @availableMemoryMB = M.Memory_Available,
           @Enabled = PTG.Enabled,
           @ProcessToolGroup = PTG.Group_Name
    FROM T_Machines M
         INNER JOIN T_Processor_Tool_Groups PTG
           ON M.ProcTool_Group_ID = PTG.Group_ID
    WHERE M.Machine = @machine
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error querying T_Machines and T_Processor_Tool_Groups'
        Goto Done
    end

    If @Enabled <= 0
    Begin
        Set @message = 'Machine "' + @machine + '" is in a disabled tool group; no tasks will be assigned for processor ' + @processorName
        Set @myError = @jobNotAvailableErrorCode
        Goto Done
    End

    If @infoOnly <> 0
    Begin -- <PreviewProcessorTools>

        ---------------------------------------------------
        -- Get list of step tools currently assigned to processor
        ---------------------------------------------------
        --
        Declare @availableProcessorTools TABLE (
            Processor_Tool_Group varchar(128),
            Tool_Name varchar(64),
            CPU_Load smallint,
            Memory_Usage_MB int,
            Tool_Priority tinyint,
            GP int,                    -- 1 when tool is designated as a "Generic Processing" tool, meaning it ignores processor groups
            Max_Job_Priority tinyint,
            Exceeds_Available_CPU_Load tinyint NOT NULL,
            Exceeds_Available_Memory tinyint NOT NULL
        )
        --
        INSERT INTO @availableProcessorTools (
            Processor_Tool_Group, Tool_Name,
            CPU_Load, Memory_Usage_MB,
            Tool_Priority, GP, Max_Job_Priority,
            Exceeds_Available_CPU_Load,
            Exceeds_Available_Memory)
        SELECT PTG.Group_Name,
               PTGD.Tool_Name,
               ST.CPU_Load,
               ST.Memory_Usage_MB,
               PTGD.Priority,
               1 AS GP,            -- Prior to May 2015 used: CASE WHEN ST.Available_For_General_Processing = 'N' THEN 0 ELSE 1 END AS GP,
               PTGD.Max_Job_Priority,
               CASE WHEN ST.CPU_Load > @availableCPUs THEN 1 ELSE 0 END AS Exceeds_Available_CPU_Load,
               CASE WHEN ST.Memory_Usage_MB > @availableMemoryMB THEN 1 ELSE 0 END AS Exceeds_Available_Memory
        FROM T_Machines M
             INNER JOIN T_Local_Processors LP
               ON M.Machine = LP.Machine
             INNER JOIN T_Processor_Tool_Groups PTG
               ON M.ProcTool_Group_ID = PTG.Group_ID
             INNER JOIN T_Processor_Tool_Group_Details PTGD
               ON PTG.Group_ID = PTGD.Group_ID AND
                  LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
             INNER JOIN T_Step_Tools ST
               ON PTGD.Tool_Name = ST.Name
        WHERE LP.Processor_Name = @processorName AND
              PTGD.Enabled > 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error getting processor tools'
            Goto Done
        End

        -- Preview the tools for this processor (as defined in @availableProcessorTools, which we just populated)
        SELECT PT.Processor_Tool_Group,
               PT.Tool_Name,
               PT.CPU_Load,
               PT.Memory_Usage_MB,
               PT.Tool_Priority,
               PT.Max_Job_Priority,
               MachineQ.Total_CPUs,
               MachineQ.CPUs_Available,
               MachineQ.Total_Memory_MB,
               MachineQ.Memory_Available,
               PT.Exceeds_Available_CPU_Load,
               PT.Exceeds_Available_Memory,
             CASE WHEN @processorDoesGP > 0 THEN 'Yes' ELSE 'No' END AS Processor_Does_General_Proc
        FROM @availableProcessorTools PT
             CROSS JOIN ( SELECT M.Total_CPUs,
           M.CPUs_Available,
               M.Total_Memory_MB,
                                 M.Memory_Available
                          FROM T_Local_Processors LP
                             INNER JOIN T_Machines M
                    ON LP.Machine = M.Machine
                          WHERE LP.Processor_Name = @processorName ) MachineQ
        ORDER BY PT.Tool_Name

    End -- </PreviewProcessorTools>


    If @remoteInfo <> ''
    Begin -- <CheckRunningRemoteTasks>

        ---------------------------------------------------
        -- Get list of job steps that are currently RunningRemote
        -- on the remote server associated with this manager
        ---------------------------------------------------
        --
        Declare @stepsRunningRemotely int = 0

        Exec @remoteInfoID = get_remote_info_id @remoteInfo

        -- Note that @remoteInfoID 1 means the @remoteInfo is 'Unknown'

        If @remoteInfoID > 1
        Begin
            If @infoOnly <> 0
            Begin
                Print '@remoteInfoID is ' + Cast(@remoteInfoID As varchar(9)) + ' for ' + @remoteInfo
            End

            SELECT @stepsRunningRemotely = COUNT(*)
            FROM T_Job_Steps
            WHERE State IN (4, 9) AND Remote_Info_ID = @remoteInfoID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @stepsRunningRemotely > 0
            Begin
                SELECT @maxSimultaneousRunningRemoteSteps = Max_Running_Job_Steps
                FROM T_Remote_Info
                WHERE Remote_Info_ID = @remoteInfoID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @stepsRunningRemotely >= IsNull(@maxSimultaneousRunningRemoteSteps, 1)
                Begin
                    Set @runningRemoteLimitReached = 1
                End
            End

            If @infoOnly <> 0
            Begin
                -- Preview RunningRemote tasks on the remote host associated with this manager
                --
                SELECT RemoteInfo.Remote_Info_ID,
                       RemoteInfo.Remote_Info,
                       RemoteInfo.Most_Recent_Job,
                       RemoteInfo.Last_Used,
                       RemoteInfo.Max_Running_Job_Steps,
                       JS.Job,
                       JS.Dataset,
                       JS.State_Name,
                       JS.State,
                       JS.Start,
                       JS.Finish
                FROM T_Remote_Info RemoteInfo
                     INNER JOIN V_Job_Steps JS
                       ON RemoteInfo.Remote_Info_ID = JS.Remote_Info_ID
                WHERE RemoteInfo.Remote_Info_ID = @remoteInfoID AND
                      JS.State IN (4, 9)
                ORDER BY Job, Step
            End

        End
        Else
        Begin
            If @infoOnly <> 0
            Begin
                Print 'Could not resolve ' + @remoteInfo + ' to Remote_Info_ID'
            End
        End

    End -- </CheckRunningRemoteTasks>

    ---------------------------------------------------
    -- Table variable to hold job step candidates
    -- for possible assignment
    ---------------------------------------------------

    Create Table #Tmp_CandidateJobSteps (
        Seq smallint IDENTITY(1,1) NOT NULL,
        Job int,
        Step int,
        State int,
        Job_Priority int,
        Tool varchar(64),
        Tool_Priority tinyint,
        Max_Job_Priority tinyint,
        Memory_Usage_MB int,
        Association_Type tinyint NOT NULL,                -- Valid types are: 1=Exclusive Association, 2=Specific Association, 3=Non-associated, 4=Non-Associated Generic, etc.
        Machine varchar(64),
        Alternate_Specific_Processor varchar(128),        -- This field is only used if @infoOnly is non-zero and if jobs exist with Association_Type 103
        Storage_Server varchar(128),
        Dataset_ID int,
        Next_Try datetime
    )

    If @infoOnly > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Populate #Tmp_CandidateJobSteps'

    ---------------------------------------------------
    -- Look for available Results_Transfer steps
    -- Only assign a Results_Transfer step to a manager running on the job's storage server
    ---------------------------------------------------

    If Exists (SELECT *
               FROM T_Local_Processors LP
                    INNER JOIN T_Machines M
                      ON LP.Machine = M.Machine
                    INNER JOIN T_Processor_Tool_Group_Details PTGD
                      ON LP.ProcTool_Mgr_ID = PTGD.Mgr_ID AND
                         M.ProcTool_Group_ID = PTGD.Group_ID
               WHERE LP.Processor_Name = @processorName And
                     PTGD.Enabled > 0 And
                     PTGD.Tool_Name = 'Results_Transfer')
    Begin
        -- Look for Results_Transfer candidates
        --
        INSERT INTO #Tmp_CandidateJobSteps (
            Job,
            Step,
            State,
            Job_Priority,
            Tool,
            Tool_Priority,
            Memory_Usage_MB,
            Storage_Server,
            Dataset_ID,
            Machine,
            Association_Type,
            Next_Try
        )
        SELECT TOP (@CandidateJobStepsToRetrieve)
            JS.Job,
            JS.Step,
            JS.State,
            J.Priority AS Job_Priority,
            JS.Tool,
            1 As Tool_Priority,
            JS.Memory_Usage_MB,
            J.Storage_Server,
            J.Dataset_ID,
            TP.Machine,
            CASE
                WHEN (J.Archive_Busy = 1)
                    -- Transfer tool steps for jobs that are in the midst of an archive operation
                    -- The Archive_Busy flag in T_Jobs is updated by sync_job_info
                    -- It uses S_DMS_V_Get_Analysis_Jobs_For_Archive_Busy (which uses V_Get_Analysis_Jobs_For_Archive_Busy) to look for jobs that have an archive in progress
                    -- However, if the dataset has been in state "Archive In Progress" for over 90 minutes, Archive_Busy will be changed back to 0 (false)
                    THEN 102
                WHEN J.Storage_Server Is Null
                    -- Results_Transfer step for job without a specific storage server
                    THEN 6
                WHEN JS.Next_Try > GETDATE()
                    -- Job won't start until after Next_Try
                    THEN 20
                ELSE 5   -- Results_Transfer step to be run on the job-specific storage server
            END AS Association_Type,
            JS.Next_Try
        FROM ( SELECT TJ.Job,
                      TJ.Priority,        -- Job_Priority
                      TJ.Archive_Busy,
                      TJ.Storage_Server,
                      TJ.Dataset_ID
               FROM T_Jobs TJ
               WHERE TJ.State <> 8
             ) J
             INNER JOIN T_Job_Steps JS
               ON J.Job = JS.Job
             INNER JOIN ( SELECT LP.Processor_Name,
                                 M.Machine
                          FROM T_Machines M
                               INNER JOIN T_Local_Processors LP
                                 ON M.Machine = LP.Machine
                               INNER JOIN T_Processor_Tool_Group_Details PTGD
                                 ON LP.ProcTool_Mgr_ID = PTGD.Mgr_ID AND
                                    M.ProcTool_Group_ID = PTGD.Group_ID
                          WHERE LP.Processor_Name = @processorName AND
                                PTGD.Enabled > 0 AND
                                PTGD.Tool_Name = 'Results_Transfer'
             ) TP
               ON JS.Tool = 'Results_Transfer' AND
                  TP.Machine = IsNull(J.Storage_Server, TP.Machine)        -- Must use IsNull here to handle jobs where the storage server is not defined in T_Jobs
        WHERE JS.State = 2 And (GETDATE() > JS.Next_Try Or @infoOnly > 0)
        ORDER BY
            Association_Type,
            J.Priority,        -- Job_Priority
            Job,
            Step
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0 And @infoOnly <> 0
        Begin
            -- Look for results transfer tasks that need to be handled by another storage server
            --
            INSERT INTO #Tmp_CandidateJobSteps (
                Job,
                Step,
                State,
                Job_Priority,
                Tool,
                Tool_Priority,
                Memory_Usage_MB,
                Storage_Server,
                Dataset_ID,
                Machine,
                Association_Type,
                Next_Try
            )
            SELECT TOP (@CandidateJobStepsToRetrieve)
                JS.Job,
                JS.Step,
                JS.State,
                J.Priority AS Job_Priority,
                JS.Tool,
                1 As Tool_Priority,
                JS.Memory_Usage_MB,
                J.Storage_Server,
                J.Dataset_ID,
                TP.Machine,
                CASE
                    WHEN JS.Next_Try > GETDATE()
                        -- Job won't start until after Next_Try
                        THEN 20
                    WHEN (J.Archive_Busy = 1)
                        -- Transfer tool steps for jobs that are in the midst of an archive operation
                        THEN 102
                    ELSE 106  -- Results_Transfer step to be run on the job-specific storage server
                END AS Association_Type,
                JS.Next_Try
            FROM ( SELECT TJ.Job,
                        TJ.Priority,        -- Job_Priority
                        TJ.Archive_Busy,
                        TJ.Storage_Server,
                        TJ.Dataset_ID
                    FROM T_Jobs TJ
                    WHERE TJ.State <> 8
                  ) J
                  INNER JOIN T_Job_Steps JS
                    ON J.Job = JS.Job
                  INNER JOIN ( SELECT LP.Processor_Name,
                                    M.Machine
                            FROM T_Machines M
                                INNER JOIN T_Local_Processors LP
                                    ON M.Machine = LP.Machine
                                INNER JOIN T_Processor_Tool_Group_Details PTGD
                                    ON LP.ProcTool_Mgr_ID = PTGD.Mgr_ID AND
                                       M.ProcTool_Group_ID = PTGD.Group_ID
                            WHERE LP.Processor_Name = @processorName AND
                                  PTGD.Enabled > 0 AND
                                  PTGD.Tool_Name = 'Results_Transfer'
                ) TP
                ON JS.Tool = 'Results_Transfer' AND
                    TP.Machine <> J.Storage_Server
               WHERE JS.State = 2 And (GETDATE() > JS.Next_Try Or @infoOnly > 0)
            ORDER BY
                Association_Type,
                J.Priority,        -- Job_Priority
                Job,
                Step
        End

    End

    ---------------------------------------------------
    -- Get list of viable job step assignments organized
    -- by processor in order of assignment priority
    ---------------------------------------------------
    --
    If @useBigBangQuery <> 0 OR @infoOnly <> 0
    Begin -- <UseBigBang>
        -- *********************************************************************************
        -- Big-bang query
        -- This query can be very expensive if there is a large number of active jobs
        -- and SQL Server gets confused about which indices to use (more likely on SQL Server 2005)
        --
        -- This can lead to huge "lock request/sec" rates, particularly when there are
        -- thouands of jobs in T_Jobs with state <> 8 and steps with state IN (2, 9)
        -- *********************************************************************************
        --
        INSERT INTO #Tmp_CandidateJobSteps (
            Job,
            Step,
            State,
            Job_Priority,
            Tool,
            Tool_Priority,
            Memory_Usage_MB,
            Storage_Server,
            Dataset_ID,
            Machine,
            Association_Type,
            Next_Try
        )
        SELECT TOP (@CandidateJobStepsToRetrieve)
            JS.Job,
            JS.Step,
            JS.State,
            J.Priority AS Job_Priority,
            JS.Tool,
            TP.Tool_Priority,
            JS.Memory_Usage_MB,
            J.Storage_Server,
            J.Dataset_ID,
            TP.Machine,
            CASE
                WHEN (TP.CPUs_Available < CASE WHEN JS.State = 9 Or @remoteInfoID > 1 Then -50
                                               ELSE TP.CPU_Load END)
                    -- No processing load available on machine
                    THEN 101
                WHEN (Tool = 'Results_Transfer' AND J.Archive_Busy = 1)
                    -- Transfer tool steps for jobs that are in the midst of an archive operation
                    THEN 102
                WHEN (TP.Memory_Available < JS.Memory_Usage_MB)
                    -- Not enough memory available on machine
                    THEN 105
                WHEN JS.State = 2 AND @runningRemoteLimitReached > 0
                    -- Too many remote tasks are already running
                    THEN 107
                WHEN JS.State = 9 AND JS.Remote_Info_ID <> @remoteInfoID
                    -- Remotely running task; only check status using a manager with the same Remote_Info
                    THEN 108
                WHEN (JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name))
                    -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                    THEN 2
                WHEN (NOT JS.Job IN (SELECT Job FROM T_Local_Job_Processors))
                    -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                    THEN 4
                WHEN JS.Next_Try > GETDATE()
                    -- Job won't start until after Next_Try
                    THEN 20
                WHEN (JS.Job IN (SELECT Job FROM T_Local_Job_Processors))
                    -- Job associated with an alternate, specific processor
                    THEN 99
            /*
                ---------------------------------------------------
                -- Deprecated in May 2015:
                --
                WHEN (Processor_GP > 0 AND Tool_GP = 'Y' AND JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name))
                    -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                    THEN 2
                WHEN (Processor_GP > 0 AND Tool_GP = 'Y')
                    -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                    THEN 4
                WHEN (Processor_GP > 0 AND Tool_GP = 'N' AND JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name))
                    -- Directly associated steps ('Specific Association', aka Association_Type=2):
                    THEN 2
                WHEN (Processor_GP > 0 AND Tool_GP = 'N' AND NOT JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor <> Processor_Name AND General_Processing = 0))
                    -- Non-associated steps ('Non-associated', aka Association_Type=3):
                    THEN 3
                WHEN (Processor_GP = 0 AND Tool_GP = 'N' AND JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name AND General_Processing = 0))
                    -- Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
                    THEN 1
            */
                ELSE 100 -- not recognized assignment ('<Not recognized>')
            END AS Association_Type,
            JS.Next_Try
        FROM ( SELECT TJ.Job,
                      TJ.Priority,        -- Job_Priority
                      TJ.Archive_Busy,
                      TJ.Storage_Server,
                      TJ.Dataset_ID
               FROM T_Jobs TJ
               WHERE TJ.State <> 8
             ) J
             INNER JOIN T_Job_Steps JS
               ON J.Job = JS.Job
             INNER JOIN ( -- Viable processors/step tool combinations (with CPU loading, memory usage,and processor group information)
                          SELECT LP.Processor_Name,
                                 LP.ID AS Processor_ID,
                                 PTGD.Tool_Name,
                                 PTGD.Priority AS Tool_Priority,
                                 PTGD.Max_Job_Priority,
                                 /*
                                 ---------------------------------------------------
                                 -- Deprecated in May 2015:
                                 --
                                 LP.GP_Groups AS Processor_GP,
                                 ST.Available_For_General_Processing AS Tool_GP,
                                 */
                                 M.CPUs_Available,
                                 ST.CPU_Load,
                                 M.Memory_Available,
                                 M.Machine
                          FROM T_Machines M
                               INNER JOIN T_Local_Processors LP
                                 ON M.Machine = LP.Machine
                               INNER JOIN T_Processor_Tool_Group_Details PTGD
                                 ON LP.ProcTool_Mgr_ID = PTGD.Mgr_ID AND
                                    M.ProcTool_Group_ID = PTGD.Group_ID
                               INNER JOIN T_Step_Tools ST
                                 ON PTGD.Tool_Name = ST.Name
                          WHERE LP.Processor_Name = @processorName AND
                                PTGD.Enabled > 0 AND
                                PTGD.Tool_Name <> 'Results_Transfer'        -- Candidate Result_Transfer steps were found above
             ) TP
               ON TP.Tool_Name = JS.Tool
        WHERE (GETDATE() > JS.Next_Try Or @infoOnly > 0) AND
              J.Priority <= TP.Max_Job_Priority AND
              (JS.State In (2, 11) OR @remoteInfoID > 1 And JS.State = 9) AND
              NOT EXISTS (SELECT * FROM T_Local_Processor_Job_Step_Exclusion WHERE ID = TP.Processor_ID And Step = JS.Step)
        ORDER BY
            Association_Type,
            Tool_Priority,
            J.Priority,        -- Job_Priority
            CASE WHEN Tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by Job
                 ELSE 0
            END DESC,
            Job,
            Step
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End -- </UseBigBang>
    Else
    Begin -- <UseMultiStep>
        -- Not using the Big-bang query

        /*
        Declare @ProcessorGP int

        ---------------------------------------------------
        -- Deprecated in May 2015:
        --
        -- Lookup the GP_Groups count for this processor

        SELECT DISTINCT @ProcessorGP = LP.GP_Groups
        FROM T_Machines M
            INNER JOIN T_Local_Processors LP
                ON M.Machine = LP.Machine
            INNER JOIN T_Processor_Tool_Group_Details PTGD
                ON LP.ProcTool_Mgr_ID = PTGD.Mgr_ID AND
                M.ProcTool_Group_ID = PTGD.Group_ID
            INNER JOIN T_Step_Tools ST
                ON PTGD.Tool_Name = ST.Name
        WHERE PTGD.Enabled > 0 AND
              LP.Processor_Name = @processorName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @ProcessorGP = IsNull(@ProcessorGP, 0)

        If @ProcessorGP = 0
        Begin -- <LimitedProcessingMachine>
            -- Processor does not do general processing
            INSERT INTO #Tmp_CandidateJobSteps (
                Job,
                Step,
                State,
                Job_Priority,
                Tool,
                Tool_Priority,
                Storage_Server,
                Dataset_ID,
                Machine,
                Association_Type,
                Next_Try
            )
            SELECT TOP (@CandidateJobStepsToRetrieve)
                JS.Job,
                Step,
                State,
                J.Priority AS Job_Priority,
                Tool,
                Tool_Priority,
                J.Storage_Server,
                J.Dataset_ID,
                TP.Machine,
                1 AS Association_Type,
                JS.Next_Try
            FROM ( SELECT TJ.Job,
                          TJ.Priority,        -- Job_Priority
                          TJ.Archive_Busy,
                          TJ.Storage_Server,
                          TJ.Dataset_ID
                   FROM T_Jobs TJ
               WHERE TJ.State <> 8 ) J
               INNER JOIN T_Job_Steps JS
                   ON J.Job = JS.Job
                 INNER JOIN ( -- Viable processors/step tools combinations (with CPU loading and processor group information)
                              SELECT LP.Processor_Name,
                                     LP.ID AS Processor_ID,
                                     PTGD.Tool_Name,
                                     PTGD.Priority AS Tool_Priority,
                                     LP.GP_Groups AS Processor_GP,
                                     ST.Available_For_General_Processing AS Tool_GP,
                                     M.CPUs_Available,
                                     ST.CPU_Load,
                                     M.Memory_Available,
                                     M.Machine
                              FROM T_Machines M
                                   INNER JOIN T_Local_Processors LP
                                     ON M.Machine = LP.Machine
                                   INNER JOIN T_Processor_Tool_Group_Details PTGD
                                     ON LP.ProcTool_Mgr_ID = PTGD.Mgr_ID AND
                                        M.ProcTool_Group_ID = PTGD.Group_ID
                                   INNER JOIN T_Step_Tools ST
                                     ON PTGD.Tool_Name = ST.Name
                              WHERE PTGD.Enabled > 0 AND
                LP.Processor_Name = @processorName AND
                PTGD.Tool_Name <> 'Results_Transfer'        -- Candidate Result_Transfer steps were found above
                            ) TP
                   ON TP.Tool_Name = JS.Tool
            WHERE (TP.CPUs_Available >= CASE WHEN JS.State = 9 THEN 0 ELSE TP.CPU_Load END) AND
                  GETDATE() > JS.Next_Try AND
                  (JS.State IN (2, 11) OR JS.State = 9 AND JS.Remote_Info_ID = @remoteInfoId) AND
                  TP.Memory_Available >= JS.Memory_Usage_MB AND
                  NOT (Tool = 'Results_Transfer' AND J.Archive_Busy = 1) AND
                  NOT EXISTS (SELECT * FROM T_Local_Processor_Job_Step_Exclusion WHERE ID = TP.Processor_ID And Step = JS.Step) AND
                  -- Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
                  -- (Processor_GP = 0 AND Tool_GP = 'N' AND JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name AND General_Processing = 0))
            ORDER BY
                Association_Type,
                Tool_Priority,
                J.Priority,    -- Job_Priority
                CASE WHEN Tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by Job
                    ELSE 0
                END DESC,
                Job,
                Step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End -- </LimitedProcessingMachine>
        Else
        Begin -- <GeneralProcessingMachine>
        */

            -- Processor does do general processing
            INSERT INTO #Tmp_CandidateJobSteps (
                Job,
                Step,
                State,
                Job_Priority,
                Tool,
                Tool_Priority,
                Storage_Server,
                Dataset_ID,
                Machine,
                Association_Type,
                Next_Try
            )
            SELECT TOP (@CandidateJobStepsToRetrieve)
                JS.Job,
                Step,
                State,
                J.Priority AS Job_Priority,
                Tool,
                Tool_Priority,
                J.Storage_Server,
                J.Dataset_ID,
                TP.Machine,
                CASE
                    WHEN JS.State = 2 AND @runningRemoteLimitReached > 0
                        -- Too many remote tasks are already running
                        THEN 107
                    WHEN JS.State = 9 AND JS.Remote_Info_ID <> @remoteInfoID
                        -- Remotely running task; only check status using a manager with the same Remote_Info
                        THEN 108
                    WHEN (JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name))
                        -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                        THEN 2
                    WHEN (Not JS.Job IN (SELECT Job FROM T_Local_Job_Processors))
                        -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                        THEN 4
                    WHEN JS.Next_Try > GETDATE()
                        -- Job won't start until after Next_Try
                        Then 20
                    WHEN (JS.Job IN (SELECT Job FROM T_Local_Job_Processors))
                        -- Job associated with an alternate, specific processor
                        THEN 99
                    ELSE 100    -- not recognized assignment ('<Not recognized>')
                END AS Association_Type,
                JS.Next_Try
            FROM ( SELECT TJ.Job,
                          TJ.Priority,        -- Job_Priority
                          TJ.Archive_Busy,
                          TJ.Storage_Server,
                          TJ.Dataset_ID
                   FROM T_Jobs TJ
                   WHERE TJ.State <> 8 ) J
                 INNER JOIN T_Job_Steps JS
                   ON J.Job = JS.Job
                 INNER JOIN ( -- Viable processors/step tools combinations (with CPU loading and processor group information)
                              SELECT LP.Processor_Name,
                                     LP.ID as Processor_ID,
                                     PTGD.Tool_Name,
                                     PTGD.Priority AS Tool_Priority,
                                     PTGD.Max_Job_Priority,
                                     /*
                                     ---------------------------------------------------
                                     -- Deprecated in May 2015:
                                     --
                                     ST.Available_For_General_Processing AS Tool_GP,
                                     */
                                     M.CPUs_Available,
                                     ST.CPU_Load,
                                     M.Memory_Available,
                                     M.Machine
                              FROM T_Machines M
                                   INNER JOIN T_Local_Processors LP
                                     ON M.Machine = LP.Machine
                                   INNER JOIN T_Processor_Tool_Group_Details PTGD
                                     ON LP.ProcTool_Mgr_ID = PTGD.Mgr_ID AND
                                        M.ProcTool_Group_ID = PTGD.Group_ID
                                   INNER JOIN T_Step_Tools ST
                                     ON PTGD.Tool_Name = ST.Name
                              WHERE PTGD.Enabled > 0 AND
                                    LP.Processor_Name = @processorName AND
                                    PTGD.Tool_Name <> 'Results_Transfer'            -- Candidate Result_Transfer steps were found above
                            ) TP
                   ON TP.Tool_Name = JS.Tool
            WHERE (TP.CPUs_Available >= CASE WHEN JS.State = 9 Or @remoteInfoID > 1 Then -50 ELSE TP.CPU_Load END) AND
                  J.Priority <= TP.Max_Job_Priority AND
                  (GETDATE() > JS.Next_Try Or @infoOnly > 0) AND
                  (JS.State In (2, 11) OR @remoteInfoID > 1 And JS.State = 9) AND
                  TP.Memory_Available >= JS.Memory_Usage_MB AND
                  NOT (Tool = 'Results_Transfer' AND J.Archive_Busy = 1) AND
                  NOT EXISTS (SELECT * FROM T_Local_Processor_Job_Step_Exclusion WHERE ID = TP.Processor_ID And Step = JS.Step)
                    /*
                    ** To improve query speed remove the Case Statement above and uncomment the following series of tests
                    AND
                    (
                        -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                        -- Type 2
                        (Tool_GP = 'Y' AND JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name)) OR

                        -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                        -- Type 4
                        (Tool_GP = 'Y') OR

                        -- Directly associated steps ('Specific Association', aka Association_Type=2):
                        -- Type 2
                        (Tool_GP = 'N' AND JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name)) OR

                        -- Non-associated steps ('Non-associated', aka Association_Type=3):
                        -- Type 3
                        (Tool_GP = 'N' AND NOT JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor <> Processor_Name AND General_Processing = 0))
                    )
                    */
            ORDER BY
                Association_Type,
                Tool_Priority,
                J.Priority,        -- Job_Priority
                CASE WHEN Tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by Job
                    ELSE 0
                END DESC,
                Job,
                Step
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Comment this end statement out due to deprecating processor groups
        -- End     -- </GeneralProcessingMachine>

    End -- </UseMultiStep>

    ---------------------------------------------------
    -- Check for jobs with Association_Type 101
    ---------------------------------------------------
    --
    If @infoOnly > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Check for jobs with Association_Type 101'

    Declare @cpuLoadExceeded int = 0

    If Exists (SELECT * FROM #Tmp_CandidateJobSteps WHERE Association_Type = 101)
        Set @cpuLoadExceeded = 1

    ---------------------------------------------------
    -- Check for storage servers for which too many
    -- steps have recently started (and are still running)
    --
    -- As of January 2013, this is no longer a necessity because copying of large files now uses lock files
    ---------------------------------------------------
    --
    If @throttleByStartTime <> 0
    Begin
        If @infoOnly > 1
            Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Check for servers that need to be throttled'

        -- The following query counts the number of job steps that recently started,
        --  grouping by storage server, and only examining steps numbers <= @maxStepNumToThrottle
        -- If @throttleAllStepTools is 0, then it excludes Sequest and Results_Transfer steps
        -- It then looks for storage servers where too many steps have recently started (count >= @MaxSimultaneousJobCount)
        -- We then link those results into #Tmp_CandidateJobSteps via Storage_Server
        -- If any matches are found, then Association_Type is updated to 104 so that the given candidate(s) will be excluded
        --
        UPDATE #Tmp_CandidateJobSteps
        SET Association_Type = 104
        FROM #Tmp_CandidateJobSteps CJS
            INNER JOIN ( -- Look for Storage Servers with too many recently started tasks
                        SELECT Storage_Server
                        FROM (  -- Look for running steps that started within the last @HoldoffWindow minutes
                                -- Group by storage server
                                -- Only examine steps <= @maxStepNumToThrottle
                                SELECT T_Jobs.Storage_Server,
                                        COUNT(*) AS Running_Steps_Recently_Started
                                FROM T_Job_Steps JS
                                    INNER JOIN T_Jobs
                                        ON JS.Job = T_Jobs.Job
                                WHERE (JS.Start >= DATEADD(MINUTE, -@HoldoffWindowMinutes, GETDATE())) AND
                                      (JS.Step <= @maxStepNumToThrottle) AND
                                      (JS.State = 4)
                                GROUP BY T_Jobs.Storage_Server
                            ) LookupQ
                        WHERE (Running_Steps_Recently_Started >= @MaxSimultaneousJobCount)
                        ) ServerQ
            ON ServerQ.Storage_Server = CJS.Storage_Server
        WHERE CJS.Step <= @maxStepNumToThrottle AND
              (NOT Tool IN ('Sequest', 'Results_Transfer') OR @throttleAllStepTools > 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End

    ---------------------------------------------------
    -- Look for any active job steps running on the same machine as this manager
    -- Exclude any jobs in #Tmp_CandidateJobSteps that correspond to a dataset
    -- that has a job step that started recently on this machine
    ---------------------------------------------------
    --
    UPDATE #Tmp_CandidateJobSteps
    SET Association_Type = 109
    FROM #Tmp_CandidateJobSteps CJS
         INNER JOIN ( SELECT J.Dataset_ID,
                             LP.Machine
                      FROM T_Job_Steps JS
                           INNER JOIN T_Jobs J
                             ON JS.Job = J.Job
                           INNER JOIN T_Local_Processors LP
                             ON JS.Processor = LP.Processor_Name
                      WHERE JS.State = 4 AND
                            JS.Start >= DateAdd(minute, -10, GetDate())
                     ) RecentStartQ
           ON CJS.Dataset_ID = RecentStartQ.Dataset_ID And
              CJS.Machine = RecentStartQ.Machine
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- If @infoOnly = 0, remove candidates with non-viable association types
    -- otherwise keep everything
    ---------------------------------------------------
    --
    Declare @AssociationTypeIgnoreThreshold int = 10

    -- Assure that any jobs with a Next_Try before now have an association type over 10
    --
    UPDATE #Tmp_CandidateJobSteps
    SET Association_Type = 20
    WHERE Association_Type < @AssociationTypeIgnoreThreshold And Next_Try > GetDate()
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @infoOnly = 0
    Begin
        DELETE FROM #Tmp_CandidateJobSteps
        WHERE Association_Type > @AssociationTypeIgnoreThreshold
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error'
            Goto Done
        End
    End
    Else
    Begin
        -- See if any jobs have Association_Type 99
        -- They are assigned to specific processors, but not to this processor
        If Exists (SELECT * FROM #Tmp_CandidateJobSteps WHERE Association_Type = 99)
        Begin
            -- Update the state to 103 for jobs associated with another processor, but not this processor
            UPDATE #Tmp_CandidateJobSteps
            SET Association_Type = 103,
                Alternate_Specific_Processor = LJP.Alternate_Processor +
                         CASE WHEN Alternate_Processor_Count > 1
                                               THEN ' and others'
                                               ELSE ''
                                         END
            FROM #Tmp_CandidateJobSteps CJS
                 INNER JOIN ( SELECT Job,
                                     Min(Processor) AS Alternate_Processor,
                                     COUNT(*) AS Alternate_Processor_Count
                              FROM T_Local_Job_Processors
                              WHERE Processor <> @processorName
                              GROUP BY Job
                            ) LJP
                   ON CJS.Job = LJP.Job
            WHERE CJS.Association_Type = 99 AND
                  NOT EXISTS ( SELECT Job
                               FROM T_Local_Job_Processors
                               WHERE Processor = @processorName )

            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

    End

    ---------------------------------------------------
    -- If no tools available, bail
    ---------------------------------------------------
    --
    If Not Exists (SELECT * FROM #Tmp_CandidateJobSteps)
    Begin
        Set @message = 'No candidates presently available'
        Set @myError = @jobNotAvailableErrorCode
        Goto Done
    end

    If @infoOnly > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Start transaction'

    ---------------------------------------------------
    -- set up transaction parameters
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'RequestStepTask'

    -- Start transaction
    Begin transaction @transName

    ---------------------------------------------------
    -- get best step candidate in order of preference:
    --   Assignment priority (prefer directly associated jobs to general pool)
    --   Job-Tool priority
    --   Overall job priority
    --   Later steps over earlier steps
    --   Job number
    ---------------------------------------------------
    --
    Declare @stepNumber int = 0

    -- This is set to 1 if the assigned job had state 9 and thus the manager is checking the status of a job step already running remotely
    Declare @jobIsRunningRemote tinyint = 0

    SELECT TOP 1
        @jobNumber =  JS.Job,
        @stepNumber = JS.Step,
        @machine = CJS.Machine,
        @jobIsRunningRemote = CASE WHEN JS.State = 9 THEN 1 ELSE 0 END
    FROM
        T_Job_Steps JS WITH (HOLDLOCK) INNER JOIN
        #Tmp_CandidateJobSteps CJS ON CJS.Job = JS.Job AND CJS.Step = JS.Step
    WHERE JS.State IN (2, 9, 11) And CJS.Association_Type <= @AssociationTypeIgnoreThreshold
    ORDER BY Seq
      --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error searching for job step'
        Goto Done
    End

    If @myRowCount > 0
        Set @jobAssigned = 1

    Set @jobIsRunningRemote = IsNull(@jobIsRunningRemote, 0)

    ---------------------------------------------------
    -- If a job step was found (@jobNumber <> 0) and if @infoOnly = 0,
    --  then update the step state to Running
    ---------------------------------------------------
    --
    If @jobAssigned = 1 AND @infoOnly = 0
    Begin --<e>
        /* Declare @debugMsg varchar(512) =
            'Assigned job ' + Cast(@jobNumber as varchar(9)) + ', step ' + Cast(@stepNumber as varchar(9)) + '; ' +
            'remoteInfoID=' + Cast(@remoteInfoId as varchar(9)) + ', ' +
            'jobIsRunningRemote=' + Cast(@jobIsRunningRemote as varchar(3)) + ', ' +
            'setting Remote_Start to ' +
                CASE WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 0 THEN Cast(GetDate() as varchar(32))
                WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 1 THEN 'existing Remote_Start value'
                ELSE 'Null'
                END

           Exec post_log_entry 'Debug', @debugMsg, 'request_step_task_xml'
        */

        UPDATE T_Job_Steps
        SET
            State = 4,
            Processor = @processorName,
            Start = GetDate(),
            Finish = Null,
            Actual_CPU_Load = CASE WHEN @remoteInfoId > 1 THEN 0 ELSE CPU_Load END,
            Next_Try =        CASE WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 1 THEN Next_Try
                                   ELSE DateAdd(second, 30, GetDate())
                              END,
            Remote_Info_ID =  CASE WHEN @remoteInfoID <= 1 THEN 1 ELSE @remoteInfoID END,
            Retry_Count =     CASE WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 1 THEN Retry_Count
                              ELSE 0
                              END,
            Remote_Start =    CASE WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 0 THEN GetDate()
                                   WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 1 THEN Remote_Start
                                   ELSE NULL
                              END,
            Remote_Finish =   CASE WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 0 THEN Null
                                   WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 1 THEN Remote_Finish
                                   ELSE NULL
                              END,
            Remote_Progress = CASE WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 0 THEN 0
                                   WHEN @remoteInfoId > 1 AND @jobIsRunningRemote = 1 THEN Remote_Progress
                                   ELSE NULL
                              END,
            Completion_Code = 0,
            Completion_Message = CASE WHEN IsNull(Completion_Code, 0) > 0 THEN '' ELSE Null END,
            Evaluation_Code =    CASE WHEN Evaluation_Code Is Null THEN Null ELSE 0 END,
            Evaluation_Message = CASE WHEN Evaluation_Code Is Null THEN Null ELSE '' END
        WHERE Job = @jobNumber AND
              Step = @stepNumber
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            set @message = 'Error updating job step'
            goto Done
        End

    End --<e>

    -- update was successful
    commit transaction @transName

    If @infoOnly > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Transaction committed'

    If @jobAssigned = 1 AND @infoOnly = 0 And @remoteInfoID <= 1
    Begin --<f>
        ---------------------------------------------------
        -- Update CPU loading for this processor's machine
        ---------------------------------------------------
        --
        UPDATE T_Machines
        SET CPUs_Available = Total_CPUs - CPUQ.CPUs_Busy
        FROM T_Machines Target
             INNER JOIN ( SELECT LP.Machine,
                                 SUM(CASE
                                         WHEN @jobIsRunningRemote > 0 AND
                                              JS.Step = @stepNumber THEN 0
                                         WHEN Tools.Uses_All_Cores > 0 AND
                                              JS.Actual_CPU_Load = JS.CPU_Load THEN IsNull(M.Total_CPUs, JS.CPU_Load)
                                         ELSE JS.Actual_CPU_Load
                                     END) AS CPUs_Busy
                          FROM T_Job_Steps JS
                               INNER JOIN T_Local_Processors LP
                                 ON JS.Processor = LP.Processor_Name
                               INNER JOIN T_Step_Tools Tools
                                 ON Tools.Name = JS.Tool
                               INNER JOIN T_Machines M
                                 ON LP.Machine = M.Machine
                          WHERE LP.Machine = @machine AND
                                JS.State = 4
                          GROUP BY LP.Machine
                      ) CPUQ
               ON CPUQ.Machine = Target.Machine
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error updating CPU loading'
        end
    End --<f>

    If @jobAssigned = 1
    Begin

        If @infoOnly = 0 And @jobIsRunningRemote = 0
        Begin
            ---------------------------------------------------
            -- Add entry to T_Job_Step_Processing_Log
            -- However, skip this step if checking the status of a remote job
            ---------------------------------------------------

            INSERT INTO T_Job_Step_Processing_Log (Job, Step, Processor, Remote_Info_ID)
            VALUES (@jobNumber, @stepNumber, @processorName, @remoteInfoID)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        If @infoOnly > 1
            Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Call get_job_step_params_xml'

        ---------------------------------------------------
        -- Job was assigned; return parameters in XML
        ---------------------------------------------------
        --
        exec @myError = get_job_step_params_xml
                                @jobNumber,
                                @stepNumber,
                                @parameters output,
                                @message output,
                                @jobIsRunningRemote=@jobIsRunningRemote,
                                @DebugMode=@infoOnly

        If @infoOnly <> 0 And Len(@message) = 0
            Set @message = 'Job ' + Convert(varchar(12), @jobNumber) + ', Step ' + Convert(varchar(12), @stepNumber) + ' would be assigned to ' + @processorName
    End
    Else
    Begin
        ---------------------------------------------------
        -- No job step found; update @myError and @message
        ---------------------------------------------------
        --
        set @myError = @jobNotAvailableErrorCode
        set @message = 'No available jobs'

        If @cpuLoadExceeded > 0
            set @message = @message + ' (note: one or more step tools would exceed the available CPU load)'
    End

    ---------------------------------------------------
    -- Dump candidate list if in infoOnly mode
    ---------------------------------------------------
    --
    If @infoOnly <> 0
    Begin
        If @infoOnly > 1
            Print Convert(varchar(32), GetDate(), 21) + ', ' + 'request_step_task_xml: Preview results'

        -- Preview the next @jobCountToPreview available jobs

        SELECT TOP ( @jobCountToPreview )
               CJS.Seq,
               CASE CJS.Association_Type
                   WHEN 1 Then   'Exclusive Association'
                   WHEN 2 Then   'Specific Association'
                   WHEN 3 THEN   'Non-associated'
                   WHEN 4 THEN   'Non-associated Generic'
                   WHEN 5 THEN   'Results_Transfer task (specific to this processor''s server)'
                   WHEN 6 THEN   'Results_Transfer task (null storage_server)'
                   WHEN 20 THEN  'Time earlier than Next_Try value'
                   WHEN 99 THEN  'Logic error: this should have been updated to 103'
                   WHEN 100 THEN 'Invalid: Not recognized'
                   WHEN 101 THEN 'Invalid: CPUs all busy'
                   WHEN 102 THEN 'Invalid: Archive in progress'
                   WHEN 103 THEN 'Invalid: Job associated with ' + Alternate_Specific_Processor
                   WHEN 104 THEN 'Invalid: Storage Server has had ' + Convert(varchar(12), @MaxSimultaneousJobCount) + ' job steps start within the last ' + Convert(varchar(12), @HoldoffWindowMinutes)  + ' minutes'
                   WHEN 105 THEN 'Invalid: Not enough memory available (' + Convert(varchar(12), CJS.Memory_Usage_MB) + ' > ' + Convert(varchar(12), @availableMemoryMB) + ', see T_Job_Steps.Memory_Usage_MB)'
                   WHEN 106 THEN 'Invalid: Results_transfer task must run on ' + CJS.Storage_Server
                   WHEN 107 THEN 'Invalid: Remote server already running ' + Cast(@maxSimultaneousRunningRemoteSteps as varchar(9)) + ' job steps; limit reached'
                   WHEN 108 THEN 'Invalid: Manager not configured to access remote server for running job step'
                   WHEN 109 THEN 'Invalid: Another manager on this processor''s server recently started processing this dataset'
                   ELSE          'Warning: Unknown association type'
               END AS Association_Type,
               CJS.Tool_Priority,
               CJS.Job_Priority,
               CJS.Job,
               CJS.Step,
               CJS.State,
               CJS.Tool,
               J.Dataset,
               JS.Next_Try,
               JS.Remote_Info_ID,
               @remoteInfoID AS Proc_Remote_Info_ID,
               @processorName AS Processor
        FROM #Tmp_CandidateJobSteps CJS
             INNER JOIN T_Jobs J
               ON CJS.Job = J.Job
             INNER JOIN T_Job_Steps JS
               ON CJS.Job = JS.Job AND CJS.Step = JS.Step
        ORDER BY Seq
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Set @returnCode = Cast(@myError As varchar(64))
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[request_step_task_xml] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[request_step_task_xml] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[request_step_task_xml] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[request_step_task_xml] TO [svc-dms] AS [dbo]
GO
