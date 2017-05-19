/****** Object:  StoredProcedure [dbo].[RequestStepTaskXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestStepTaskXML
/****************************************************
**
** Desc: 
**	Looks for analysis job step that is appropriate for the given Processor Name.
**	If found, step is assigned to caller
**
**	Job assignment will be based on:
**	Assignment type:
**		Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
**		Directly associated steps ('Specific Association', aka Association_Type=2):
**		Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
**		Non-associated steps ('Non-associated', aka Association_Type=3):
**		Generic processing steps ('Non-associated Generic', aka Association_Type=4):
**		No processing load available on machine, aka Association_Type=101 (disqualified)
**		Transfer tool steps for jobs that are in the midst of an archive operation, aka Association_Type=102 (disqualified)
**		Specifically assigned to alternate processor, aka Association_Type=103 (disqualified)
**		Too many recently started job steps for the given tool, aka Association_Type=104 (disqualified)
**	Job-Tool priority
**	Job priority
**	Job number
**	Step Number
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**			08/23/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			12/03/2008 grk - included processor-tool priority in assignement logic
**			12/04/2008 mem - Now returning @jobNotAvailableErrorCode if @processorName is not in T_Local_Processors
**			12/11/2008 mem - Rearranged preference order for job assignment priorities
**			12/11/2008 grk - Rewrote to use tool/processor priority in assignment logic
**			12/29/2008 mem - Now setting Finish to Null when a job step's state changes to 4=Running
**			01/13/2009 mem - Added parameter AnalysisManagerVersion (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**			01/14/2009 mem - Now checking for T_Jobs.State = 8 (holding)
**			01/15/2009 mem - Now previewing the next 10 available jobs when @infoOnly <> 0 (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**			01/25/2009 mem - Now checking for Enabled > 0 in T_Processor_Tool
**			02/09/2009 mem - Altered job step ordering to account for parallelized Inspect jobs
**			02/18/2009 grk - Populating candidate table with single query ("big-bang") instead of multiple queries
**			02/26/2009 mem - Now making an entry in T_Job_Step_Processing_Log for each job step assigned
**			05/14/2009 mem - Fixed logic that checks whether @cpuLoadExceeded should be non-zero
**						   - Updated to report when a job is invalid for this processor, but is specifically associated with another processor (Association_Type 103)
**			06/02/2009 mem - Optimized Big-bang query (which populates #Tmp_CandidateJobSteps) due to high LockRequest/sec rates when we have thousands of active jobs (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**						   - Added parameter @useBigBangQuery to allow for disabling use of the Big-Bang query
**			06/03/2009 mem - When finding candidate tasks, now treating Results_Transfer steps as step "100" so that they are assigned first, and so that they are assigned grouped by Job when multiple Results_Transfer tasks are "Enabled" for a given job
**			08/20/2009 mem - Now checking for @Machine in T_Machines when @infoOnly is non-zero
**			09/02/2009 mem - Now using T_Processor_Tool_Groups and T_Processor_Tool_Group_Details to determine the processor tool priorities for the given processor
**			09/03/2009 mem - Now verifying that the processor is enabled and the processor tool group is enabled
**			10/12/2009 mem - Now treating enabled states <= 0 as disabled for processor tool groups
**			03/03/2010 mem - Added parameters @throttleByStartTime and @maxStepNumToThrottle
**			03/10/2010 mem - Fixed bug that ignored @maxStepNumToThrottle when updating #Tmp_CandidateJobSteps
**			08/20/2010 mem - No longer ordering by Step_Number Descending prior to job number; this caused problems choosing the next appropriate Sequest job since Sequest_DTARefinery jobs run Sequest as step 4 while normal Sequest jobs run Sequest as step 3
**						   - Sort order is now: Association_Type, Tool_Priority, Job Priority, Favor Results_Transfer steps, Job, Step_Number
**			09/09/2010 mem - Bumped @maxStepNumToThrottle up to 10
**						   - Added parameter @throttleAllStepTools, defaulting to 0 (meaning we will not throttle Sequest or Results_Transfer steps)
**			09/29/2010 mem - Tweaked throttling logic to move the Step_Tool exclusion test to the outer WHERE clause
**			06/09/2011 mem - Added parameter @logSPUsage, which posts a log entry to T_SP_Usage if non-zero
**			10/17/2011 mem - Now considering Memory_Usage_MB
**			11/01/2011 mem - Changed @HoldoffWindowMinutes from 7 to 3 minutes
**			12/19/2011 mem - Now showing memory amounts in "Not enough memory available" error message
**			04/25/2013 mem - Increased @MaxSimultaneousJobCount from 10 to 75; this is feasible since the storage servers now have the DMS_LockFiles share, which is used to prioritize copying large files
**			01/10/2014 mem - Now only assigning Results_Transfer tasks to the storage server on which the dataset resides
**						   - Changed @throttleByStartTime to 0
**			09/24/2014 mem - Removed reference to Machine in T_Job_Steps
**			04/21/2015 mem - Now using column Uses_All_Cores
**			06/01/2015 mem - No longer querying T_Local_Job_Processors since we have deprecated processor groups
**						   - Also now ignoring GP_Groups and Available_For_General_Processing
**			11/18/2015 mem - Now using Actual_CPU_Load instead of CPU_Load
**			02/15/2016 mem - Re-enabled use of T_Local_Job_Processors and processor groups
**						   - Added job step exclusion using T_Local_Processor_Job_Step_Exclusion
**			05/04/2017 mem - Filter on column Next_Try
**			05/11/2017 mem - Look for jobs in state 2 or 9
**			                 Commit the transaction earlier to reduce the time that a HoldLock is on table T_Job_Steps
**			                 Pass @jobIsRunningRemote to GetJobStepParamsXML
**			05/15/2017 mem - Consider MonitorRunningRemote when looking for candidate jobs
**			05/16/2017 mem - Do not update T_Job_Step_Processing_Log if checking the status of a remotely running job
**			05/18/2017 mem - Add parameter @remoteInfo
**
*****************************************************/
(
	@processorName varchar(128),				-- Name of the processor requesting a job
	@jobNumber int = 0 output,					-- Job number assigned; 0 if no job available
	@parameters varchar(max) output,			-- job step parameters (in XML)
    @message varchar(512) output,				-- Output message
	@infoOnly tinyint = 0,						-- Set to 1 to preview the job that would be returned; if 2, then will print debug statements
	@analysisManagerVersion varchar(128) = '',	-- Used to update T_Local_Processors
	@remoteInfo varchar(900) = '',				-- Provided by managers that stage jobs to run remotely; used to assure that we don't stage too many jobs at once
	@jobCountToPreview int = 10,				-- The number of jobs to preview when @infoOnly >= 1
	@useBigBangQuery tinyint = 1,				-- Ignored and always set to 1 by this procedure (When non-zero, then uses a single, large query to find candidate steps.  Can be very expensive if there is a large number of active jobs (i.e. over 10,000 active jobs))
	@throttleByStartTime tinyint = 0,			-- Set to 1 to limit the number of job steps that can start simultaneously on a given storage server (to avoid overloading the disk and network I/O on the server); this is no longer a necessity because copying of large files now uses lock files (effective January 2013)
	@maxStepNumToThrottle int = 10,
	@throttleAllStepTools tinyint = 0,			-- When 0, then will not throttle Sequest or Results_Transfer steps
	@logSPUsage tinyint = 0
)
As
	set nocount on

	declare @myError int = 0
	declare @myRowCount int = 0
	
	declare @jobAssigned tinyint = 0

	Declare @CandidateJobStepsToRetrieve int = 15
	
	Declare @HoldoffWindowMinutes int
	Declare @MaxSimultaneousJobCount int

	Declare @maxSimultaneousRunningRemoteSteps int = 0
	Declare @runningRemoteLimitReached tinyint = 0

	---------------------------------------------------
	-- These 3 hard-coded values give optimal performance 
	-- (note that @useBigBangQuery overrides the value passed into this procedure)
	---------------------------------------------------
	--
	Set @HoldoffWindowMinutes = 3				-- Typically 3
	Set @MaxSimultaneousJobCount = 75			-- Increased from 10 to 75 on 4/25/2013
	Set @useBigBangQuery = 1					-- Always forced by this procedure to be 1
	
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
	declare @jobNotAvailableErrorCode int = 53000

	If @infoOnly > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Starting; make sure this is a valid processor'

	---------------------------------------------------
	-- Make sure this is a valid processor (and capitalize it according to T_Local_Processors)
	---------------------------------------------------
	--
	declare @machine varchar(64)
	declare @availableCPUs smallint
	declare @availableMemoryMB int
	declare @ProcessorState char
	declare @ProcessorID int
	declare @Enabled smallint
	declare @ProcessToolGroup varchar(128)
	--
	declare @processorDoesGP int
	set @processorDoesGP = -1
	--
	SELECT 
		@processorDoesGP = 1,		-- Prior to May 2015 used: @processorDoesGP = GP_Groups
		@machine = Machine,
		@processorName = Processor_Name,
		@ProcessorState = State,
		@ProcessorID = ID
	FROM	T_Local_Processors
	WHERE	Processor_Name = @processorName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for processor in T_Local_Processors'
		goto Done
	end

	-- Check if no processor found?
	if @myRowCount = 0
	begin
		set @message = 'Processor not defined in T_Local_Processors: ' + @processorName
		set @myError = @jobNotAvailableErrorCode
		
		INSERT INTO T_SP_Usage( Posted_By,
								ProcessorID,
								Calling_User )
		VALUES('RequestStepTaskXML', null, SUSER_SNAME() + ' Invalid processor: ' + @processorName)


		goto Done
	end
	
	---------------------------------------------------
	-- Update processor's request timestamp
	-- (to show when the processor was most recently active)
	---------------------------------------------------
	--
	If @infoOnly = 0
	begin
		UPDATE T_Local_Processors
		SET Latest_Request = GETDATE(),
			Manager_Version = @analysisManagerVersion
		WHERE Processor_Name = @processorName
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error updating latest processor request time'
			goto Done
		end
		
		if IsNull(@logSPUsage, 0) <> 0
			INSERT INTO T_SP_Usage ( 
			                Posted_By,
							ProcessorID,
							Calling_User )
			VALUES('RequestStepTaskXML', @ProcessorID, SUSER_SNAME())

	end

	---------------------------------------------------
	-- Abort if not enabled in T_Local_Processors
	---------------------------------------------------
	If @ProcessorState <> 'E'
	Begin
		set @message = 'Processor is not enabled in T_Local_Processors: ' + @processorName
		set @myError = @jobNotAvailableErrorCode
		goto Done
	End

	---------------------------------------------------
	-- Make sure this processor's machine is in T_Machines
	---------------------------------------------------
	If Not Exists (SELECT * FROM T_Machines Where Machine = @machine)
	Begin
		set @message = 'Machine "' + @machine + '" is not present in T_Machines (but is defined in T_Local_Processors for processor "' + @processorName + '")'
		set @myError = @jobNotAvailableErrorCode
		goto Done
	End
	
	---------------------------------------------------
	-- Lookup the number of CPUs available and amount of memory available for this processor's machine
	-- In addition, make sure this machine is a member of an enabled group
	---------------------------------------------------
	Set @availableCPUs = 0
	set @availableMemoryMB = 0
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
	if @myError <> 0
	begin
		set @message = 'Error querying T_Machines and T_Processor_Tool_Groups'
		goto Done
	end	
	
	If @Enabled <= 0
	Begin
		set @message = 'Machine "' + @machine + '" is in a disabled tool group; no tasks will be assigned for processor ' + @processorName
		set @myError = @jobNotAvailableErrorCode
		goto Done
	End
		
	If @infoOnly <> 0
	Begin -- <PreviewProcessorTools>
				
		---------------------------------------------------
		-- Get list of step tools currently assigned to processor
		---------------------------------------------------
		--
		declare @availableProcessorTools TABLE (
			Processor_Tool_Group varchar(128),
			Tool_Name varchar(64),
			CPU_Load smallint,
			Memory_Usage_MB int,
			Tool_Priority tinyint,
			GP int,					-- 1 when tool is designated as a "Generic Processing" tool, meaning it ignores processor groups
			Exceeds_Available_CPU_Load tinyint NOT NULL,
			Exceeds_Available_Memory tinyint NOT NULL
		)
		--
		INSERT INTO @availableProcessorTools (Processor_Tool_Group, Tool_Name, CPU_Load, Memory_Usage_MB, Tool_Priority, GP, Exceeds_Available_CPU_Load, Exceeds_Available_Memory)
		SELECT PTG.Group_Name,
		       PTGD.Tool_Name,
		       ST.CPU_Load,
		       ST.Memory_Usage_MB,
		       PTGD.Priority,
		       1 AS GP,			-- Prior to May 2015 used: CASE WHEN ST.Available_For_General_Processing = 'N' THEN 0 ELSE 1 END AS GP,
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
		if @myError <> 0
		begin
			set @message = 'Error getting processor tools'
			goto Done
		end
	
		-- Preview the tools for this processor (as defined in @availableProcessorTools, which we just populated)
		SELECT PT.Processor_Tool_Group,
		       PT.Tool_Name,
		       PT.CPU_Load,
		       PT.Memory_Usage_MB,
		       PT.Tool_Priority,
		       PT.GP AS GP_StepTool,
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
		Declare @remoteInfoID int = 0
		Declare @stepsRunningRemotely int = 0
		
		Exec @remoteInfoID = GetRemoteInfoID @remoteInfo
		
		If @remoteInfoID > 0
		Begin
			
			SELECT @stepsRunningRemotely = COUNT(*)
			FROM T_Job_Steps
			WHERE State IN (4,9) AND Remote_Info_ID = @remoteInfoID
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
				       JS.StateName,
				       JS.State,
				       JS.Start,
				       JS.Finish
				FROM T_Remote_Info RemoteInfo
				     INNER JOIN V_Job_Steps JS
				       ON RemoteInfo.Remote_Info_ID = JS.Remote_Info_ID
				WHERE (RemoteInfo.Remote_Info_ID = 3) AND
				      (JS.State IN (4, 9))
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
		Step_Number int,
		State int,
		Job_Priority int,
		Step_Tool varchar(64),
		Tool_Priority int,
		Memory_Usage_MB int,
		Association_Type tinyint NOT NULL,				-- Valid types are: 1=Exclusive Association, 2=Specific Association, 3=Non-associated, 4=Non-Associated Generic, etc.
		Machine varchar(64),
		Alternate_Specific_Processor varchar(128),		-- This field is only used if @infoOnly is non-zero and if jobs exist with Association_Type 103
		Storage_Server varchar(128)
	)

	If @infoOnly > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Populate #Tmp_CandidateJobSteps'

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

		INSERT INTO #Tmp_CandidateJobSteps (
			Job,
			Step_Number,
			State,
			Job_Priority,
			Step_Tool,
			Tool_Priority,
			Memory_Usage_MB,
			Storage_Server,
			Machine,
			Association_Type
		)
		SELECT TOP (@CandidateJobStepsToRetrieve)
			JS.Job, 
			JS.Step_Number,
			JS.State,
			TJ.Priority AS Job_Priority,
			JS.Step_Tool,
			1 As Tool_Priority,
			JS.Memory_Usage_MB,
			TJ.Storage_Server,
			TP.Machine,
			CASE
				-- transfer tool steps for jobs that are in the midst of an archive operation
				WHEN (TJ.Archive_Busy = 1) 
					THEN 102
				-- Results_Transfer step for job without a specific storage server
				WHEN TJ.Storage_Server Is Null
					THEN 6
				WHEN JS.State = 2 AND @runningRemoteLimitReached > 0
					THEN 107
				-- Results_Transfer step to be run on the job-specific storage server
				ELSE 5
			END AS Association_Type
		FROM ( SELECT TJ.Job,
		              TJ.Priority,		-- Job_Priority
		              TJ.Archive_Busy,
		              TJ.Storage_Server
		       FROM T_Jobs TJ
		       WHERE TJ.State <> 8
		     ) TJ
		     INNER JOIN T_Job_Steps JS
		       ON TJ.Job = JS.Job
		     INNER JOIN ( SELECT LP.Processor_Name,
		                         M.Machine
		                  FROM T_Machines M
		                       INNER JOIN T_Local_Processors LP
		                         ON M.Machine = LP.Machine
		                  WHERE LP.Processor_Name = @processorName
		     ) TP
		       ON JS.Step_Tool = 'Results_Transfer' AND 
		          TP.Machine = IsNull(TJ.Storage_Server, TP.Machine)		-- Must use IsNull here to handle jobs where the storage server is not defined in T_Jobs
		WHERE GETDATE() > JS.Next_Try AND JS.State = 2
		ORDER BY 
			Association_Type,
			TJ.Priority,		-- Job_Priority
			Job, 
			Step_Number
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0 And @infoOnly <> 0
		Begin
			-- Look for results transfer tasks that need to be handled by another storage server
			--
			INSERT INTO #Tmp_CandidateJobSteps (
				Job,
				Step_Number,
				State,
				Job_Priority,
				Step_Tool,
				Tool_Priority,
				Memory_Usage_MB,
				Storage_Server,
				Machine,
				Association_Type
			)
			SELECT TOP (@CandidateJobStepsToRetrieve)
				JS.Job, 
				JS.Step_Number,
				JS.State,
				TJ.Priority AS Job_Priority,
				JS.Step_Tool,
				1 As Tool_Priority,
				JS.Memory_Usage_MB,
				TJ.Storage_Server,
				TP.Machine,
				CASE
					-- transfer tool steps for jobs that are in the midst of an archive operation
					WHEN (TJ.Archive_Busy = 1) 
						THEN 102
					-- Results_Transfer step to be run on the job-specific storage server
					ELSE 106
				END AS Association_Type
			FROM ( SELECT TJ.Job,
						TJ.Priority,		-- Job_Priority
						TJ.Archive_Busy,
						TJ.Storage_Server
				    FROM T_Jobs TJ
				    WHERE TJ.State <> 8
				  ) TJ
				  INNER JOIN T_Job_Steps JS
				    ON TJ.Job = JS.Job
				  INNER JOIN ( SELECT LP.Processor_Name,
									M.Machine
							FROM T_Machines M
								INNER JOIN T_Local_Processors LP
									ON M.Machine = LP.Machine
							WHERE LP.Processor_Name = @processorName
				) TP
				ON JS.Step_Tool = 'Results_Transfer' AND 
					TP.Machine <> TJ.Storage_Server
			WHERE GETDATE() > JS.Next_Try AND JS.State = 2
			ORDER BY 
				Association_Type,
				TJ.Priority,		-- Job_Priority
				Job, 
				Step_Number
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
		-- and Sql Server gets confused about which indices to use (more likely on Sql Server 2005)
		--
		-- This can lead to huge "lock request/sec" rates, particularly when there are 
		-- thouands of jobs in T_Jobs with state <> 8 and steps with state IN (2, 9)
		-- *********************************************************************************
		--
		INSERT INTO #Tmp_CandidateJobSteps (
			Job,
			Step_Number,
			State,
			Job_Priority,
			Step_Tool,
			Tool_Priority,
			Memory_Usage_MB,
			Storage_Server,
			Machine,
			Association_Type
		)
		SELECT TOP (@CandidateJobStepsToRetrieve)
			JS.Job, 
			JS.Step_Number,
			JS.State,
			TJ.Priority AS Job_Priority,
			JS.Step_Tool,
			TP.Tool_Priority,
			JS.Memory_Usage_MB,
			TJ.Storage_Server,
			TP.Machine,
			CASE
				WHEN (TP.CPUs_Available < CASE WHEN JS.State = 9 THEN 1 ELSE TP.CPU_Load END) 
					-- No processing load available on machine
					THEN 101
				WHEN (Step_Tool = 'Results_Transfer' AND TJ.Archive_Busy = 1) 
					-- Transfer tool steps for jobs that are in the midst of an archive operation
					THEN 102
				WHEN (TP.Memory_Available < JS.Memory_Usage_MB) 
					-- Not enough memory available on machine
					THEN 105
				WHEN JS.State = 2 AND @runningRemoteLimitReached > 0
					THEN 107
				WHEN (JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name))
					-- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
					THEN 2
				WHEN (NOT JS.Job IN (SELECT Job FROM T_Local_Job_Processors)) 
					-- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
					THEN 4
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
			END AS Association_Type
		FROM ( SELECT TJ.Job,
		  TJ.Priority,		-- Job_Priority
		              TJ.Archive_Busy,
		              TJ.Storage_Server
		       FROM T_Jobs TJ
		       WHERE TJ.State <> 8 
		     ) TJ
		     INNER JOIN T_Job_Steps JS
		       ON TJ.Job = JS.Job
		     INNER JOIN (	-- Viable processors/step tool combinations (with CPU loading, memory usage,and processor group information)
		                  SELECT LP.Processor_Name,
		                         LP.ID AS Processor_ID,
		                         PTGD.Tool_Name,
		                         PTGD.Priority AS Tool_Priority,
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
		                         M.Machine,
		                         M.MonitorRunningRemote
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
		                        PTGD.Tool_Name <> 'Results_Transfer'		-- Candidate Result_Transfer steps were found above
		     ) TP
		       ON TP.Tool_Name = JS.Step_Tool
		WHERE GETDATE() > JS.Next_Try AND
		      (JS.State = 2 OR TP.MonitorRunningRemote > 0 And JS.State = 9) AND
		      NOT EXISTS (SELECT * FROM T_Local_Processor_Job_Step_Exclusion WHERE ID = TP.Processor_ID And Step = JS.Step_Number)
		ORDER BY 
			Association_Type,
			Tool_Priority, 
			TJ.Priority,		-- Job_Priority
			CASE WHEN Step_Tool = 'Results_Transfer' Then 10	-- Give Results_Transfer steps priority so that they run first and are grouped by Job
			     ELSE 0 
			END DESC,			     
			Job, 
			Step_Number
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End -- </UseBigBang>
	Else
	Begin -- <UseMultiStep>
		-- Not using the Big-bang query

		/*	
		declare @ProcessorGP int

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
				Step_Number,
				State,
				Job_Priority,
				Step_Tool,
				Tool_Priority,
				Storage_Server,
				Machine,
				Association_Type
			)
			SELECT TOP (@CandidateJobStepsToRetrieve)
				JS.Job, 
				Step_Number,
				State,
				TJ.Priority AS Job_Priority,
				Step_Tool,
				Tool_Priority,
				TJ.Storage_Server,
				TP.Machine,
				1 AS Association_Type
			FROM ( SELECT TJ.Job,
			              TJ.Priority,		-- Job_Priority
			              TJ.Archive_Busy,
			              TJ.Storage_Server
			       FROM T_Jobs TJ
			   WHERE TJ.State <> 8 ) TJ
			   INNER JOIN T_Job_Steps JS
		           ON TJ.Job = JS.Job
			     INNER JOIN (	-- Viable processors/step tools combinations (with CPU loading and processor group information)
			                  SELECT LP.Processor_Name,
			                         LP.ID AS Processor_ID,
			                         PTGD.Tool_Name,
			                         PTGD.Priority AS Tool_Priority,
			                         LP.GP_Groups AS Processor_GP,
			                         ST.Available_For_General_Processing AS Tool_GP,
			                         M.CPUs_Available,
			                         ST.CPU_Load,
			                         M.Memory_Available,
			                         M.Machine,
			                         M.MonitorRunningRemote
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
			    PTGD.Tool_Name <> 'Results_Transfer'		-- Candidate Result_Transfer steps were found above
			                ) TP
			       ON TP.Tool_Name = JS.Step_Tool
			WHERE (TP.CPUs_Available >= CASE WHEN JS.State = 9 THEN 1 ELSE TP.CPU_Load END) AND
			      GETDATE() > JS.Next_Try AND
			      (JS.State = 2 OR TP.MonitorRunningRemote > 0 And JS.State = 9) AND
			      TP.Memory_Available >= JS.Memory_Usage_MB AND
			      NOT (Step_Tool = 'Results_Transfer' AND TJ.Archive_Busy = 1) AND
			      NOT EXISTS (SELECT * FROM T_Local_Processor_Job_Step_Exclusion WHERE ID = TP.Processor_ID And Step = JS.Step_Number) AND
			      -- Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
			      -- (Processor_GP = 0 AND Tool_GP = 'N' AND JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name AND General_Processing = 0))			      
			ORDER BY 
				Association_Type,
				Tool_Priority, 
				TJ.Priority,	-- Job_Priority
				CASE WHEN Step_Tool = 'Results_Transfer' Then 10	-- Give Results_Transfer steps priority so that they run first and are grouped by Job
					ELSE 0 
				END DESC,			    
				Job, 
				Step_Number
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

		End -- </LimitedProcessingMachine>
		Else
		Begin -- <GeneralProcessingMachine>
		*/

			-- Processor does do general processing
			INSERT INTO #Tmp_CandidateJobSteps (
				Job,
				Step_Number,
				State,
				Job_Priority,
				Step_Tool,
				Tool_Priority,
				Storage_Server,
				Machine,
				Association_Type
			)
			SELECT TOP (@CandidateJobStepsToRetrieve)
				JS.Job, 
				Step_Number,
				State,
				TJ.Priority AS Job_Priority,
				Step_Tool,
				Tool_Priority,
				TJ.Storage_Server,
				TP.Machine,
				CASE
					WHEN JS.State = 2 AND @runningRemoteLimitReached > 0
						THEN 107
					WHEN (JS.Job IN (SELECT Job FROM T_Local_Job_Processors WHERE Processor = Processor_Name))
						-- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
						THEN 2
					WHEN (Not JS.Job IN (SELECT Job FROM T_Local_Job_Processors)) 
						-- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
						THEN 4
					WHEN (JS.Job IN (SELECT Job FROM T_Local_Job_Processors)) 
						-- Job associated with an alternate, specific processor
						THEN 99
					ELSE 100	-- not recognized assignment ('<Not recognized>')
				END AS Association_Type				
			FROM ( SELECT TJ.Job,
			              TJ.Priority,		-- Job_Priority
			              TJ.Archive_Busy,
			              TJ.Storage_Server
			       FROM T_Jobs TJ
			       WHERE TJ.State <> 8 ) TJ
			     INNER JOIN T_Job_Steps JS
			       ON TJ.Job = JS.Job
			     INNER JOIN (	-- Viable processors/step tools combinations (with CPU loading and processor group information)
			                  SELECT LP.Processor_Name,
			                         LP.ID as Processor_ID,
			                         PTGD.Tool_Name,
			                         PTGD.Priority AS Tool_Priority,
			                         /*
									 ---------------------------------------------------
									 -- Deprecated in May 2015: 
									 --
			                         ST.Available_For_General_Processing AS Tool_GP,
			                         */
			                         M.CPUs_Available,
			                         ST.CPU_Load,
		                             M.Memory_Available,
			                         M.Machine,
			                         M.MonitorRunningRemote
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
			                        PTGD.Tool_Name <> 'Results_Transfer'			-- Candidate Result_Transfer steps were found above
			                ) TP
			       ON TP.Tool_Name = JS.Step_Tool
			WHERE (TP.CPUs_Available >= CASE WHEN JS.State = 9 THEN 1 ELSE TP.CPU_Load END) AND
			      GETDATE() > JS.Next_Try AND
			      (JS.State = 2 OR TP.MonitorRunningRemote > 0 And JS.State = 9) AND
			      TP.Memory_Available >= JS.Memory_Usage_MB AND
			      NOT (Step_Tool = 'Results_Transfer' AND TJ.Archive_Busy = 1) AND
			      NOT EXISTS (SELECT * FROM T_Local_Processor_Job_Step_Exclusion WHERE ID = TP.Processor_ID And Step = JS.Step_Number)
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
				TJ.Priority,		-- Job_Priority
				CASE WHEN Step_Tool = 'Results_Transfer' Then 10	-- Give Results_Transfer steps priority so that they run first and are grouped by Job
					ELSE 0 
				END DESC,			     
				Job, 
				Step_Number
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

		-- Comment this end statement out due to deprecating processor groups
		-- End	 -- </GeneralProcessingMachine>
	
	End -- </UseMultiStep>

	---------------------------------------------------
	-- Check for jobs with Association_Type 101
	---------------------------------------------------
	--
	If @infoOnly > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Check for jobs with Association_Type 101'

	declare @cpuLoadExceeded int = 0
	
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
			Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Check for servers that need to be throttled'

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
						FROM ( -- Look for running steps that started within the last @HoldoffWindow minutes
								-- Group by storage server
								-- Only examine steps <= @maxStepNumToThrottle
								SELECT T_Jobs.Storage_Server,
										COUNT(*) AS Running_Steps_Recently_Started
								FROM T_Job_Steps JS
									INNER JOIN T_Jobs
										ON JS.Job = T_Jobs.Job
								WHERE (JS.Start >= DATEADD(MINUTE, -@HoldoffWindowMinutes, GETDATE())) AND
									  (JS.Step_Number <= @maxStepNumToThrottle) AND
									  (JS.State = 4)
								GROUP BY T_Jobs.Storage_Server 
							) LookupQ
						WHERE (Running_Steps_Recently_Started >= @MaxSimultaneousJobCount)
						) ServerQ
			ON ServerQ.Storage_Server = CJS.Storage_Server
		WHERE CJS.Step_Number <= @maxStepNumToThrottle AND
		      (NOT Step_Tool IN ('Sequest', 'Results_Transfer') OR @throttleAllStepTools > 0)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
	End

	---------------------------------------------------
	-- If @infoOnly = 0, then remove candidates with non-viable association types
	-- otherwise keep everything
	---------------------------------------------------
	--
	Declare @AssociationTypeIgnoreThreshold int = 10
	
	If @infoOnly = 0
	Begin
		DELETE FROM #Tmp_CandidateJobSteps
		WHERE Association_Type > @AssociationTypeIgnoreThreshold
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error'
			goto Done
		end
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
	-- if no tools available, bail
	---------------------------------------------------
	--
	If Not Exists (SELECT * FROM #Tmp_CandidateJobSteps)
	begin
		set @message = 'No candidates presently available'
		set @myError = @jobNotAvailableErrorCode
		goto Done
	end

	If @infoOnly > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Start transaction'

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
	declare @transName varchar(32) = 'RequestStepTask'
		
	-- Start transaction
	begin transaction @transName
	
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
	Declare @jobIsRunningRemote tinyint = 0
	--
	SELECT TOP 1
		@jobNumber =  JS.Job,
		@stepNumber = JS.Step_Number,
		@machine = CJS.Machine,
		@jobIsRunningRemote = CASE WHEN JS.State = 9 THEN 1 ELSE 0 END
	FROM   
		T_Job_Steps JS WITH (HOLDLOCK) INNER JOIN 
		#Tmp_CandidateJobSteps CJS ON CJS.Job = JS.Job AND CJS.Step_Number = JS.Step_Number
	WHERE JS.State IN (2, 9) And CJS.Association_Type <= @AssociationTypeIgnoreThreshold
	ORDER BY Seq
  	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error searching for job step'
		goto Done
	end

	if @myRowCount > 0
		set @jobAssigned = 1
	
	---------------------------------------------------
	-- If a job step was found (@jobNumber <> 0) and if @infoOnly = 0, 
	--  then update the step state to Running
	---------------------------------------------------
	--
	If @jobAssigned = 1 AND @infoOnly = 0
	begin --<e>
		UPDATE T_Job_Steps
		SET
			State = 4, 
			Processor = @processorName,
			Start = GetDate(),
			Finish = Null,
			Actual_CPU_Load = CPU_Load
		WHERE Job = @jobNumber AND
		      Step_Number = @stepNumber
  		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error updating job step'
			goto Done
		end

	end --<e>
      
	-- update was successful
	commit transaction @transName

	If @infoOnly > 1
		Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Transaction committed'

	If @jobAssigned = 1 AND @infoOnly = 0
	begin --<f>
		---------------------------------------------------
		-- Update CPU loading for this processor's machine
		---------------------------------------------------
		--
		UPDATE T_Machines
		SET CPUs_Available = Total_CPUs - CPUQ.CPUs_Busy
		FROM T_Machines Target
		     INNER JOIN ( SELECT LP.Machine,
		                         SUM(	CASE WHEN @jobIsRunningRemote > 0 AND JS.Step_Number = @stepNumber 
		                                       THEN 1
		                                     WHEN Tools.Uses_All_Cores > 0 AND JS.Actual_CPU_Load = JS.CPU_Load
											   THEN IsNull(M.Total_CPUs, JS.CPU_Load)
											 ELSE JS.Actual_CPU_Load
										END ) AS CPUs_Busy
		                  FROM T_Job_Steps JS
		                       INNER JOIN T_Local_Processors LP
		                         ON JS.Processor = LP.Processor_Name
		                       INNER JOIN T_Step_Tools Tools
		                         ON Tools.Name = JS.Step_Tool
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
    end --<f>

	if @jobAssigned = 1
	begin

		if @infoOnly = 0 And IsNull(@jobIsRunningRemote, 0) = 0
		begin
			---------------------------------------------------
			-- Add entry to T_Job_Step_Processing_Log
			-- However, skip this step if checking the status of a remote job
			---------------------------------------------------
			
			INSERT INTO T_Job_Step_Processing_Log (Job, Step, Processor)
			VALUES (@jobNumber, @stepNumber, @processorName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end

		If @infoOnly > 1
			Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Call GetJobStepParamsXML'
		
		---------------------------------------------------
		-- Job was assigned; return parameters in XML
		---------------------------------------------------
		--
		exec @myError = GetJobStepParamsXML
								@jobNumber,
								@stepNumber,
								@parameters output,
								@message output,
								@jobIsRunningRemote=@jobIsRunningRemote,
								@DebugMode=@infoOnly

		if @infoOnly <> 0 And Len(@message) = 0
			Set @message = 'Job ' + Convert(varchar(12), @jobNumber) + ', Step ' + Convert(varchar(12), @stepNumber) + ' would be assigned to ' + @processorName
    end
	else
	begin
		---------------------------------------------------
		-- No job step found; update @myError and @message
		---------------------------------------------------
		--
		set @myError = @jobNotAvailableErrorCode
		set @message = 'No available jobs'
		
		If @cpuLoadExceeded > 0
			set @message = @message + ' (note: one or more step tools would exceed the available CPU load)'
	end
	
	---------------------------------------------------
	-- dump candidate list if in infoOnly mode
	---------------------------------------------------
	--
	If @infoOnly <> 0
	Begin
		If @infoOnly > 1
			Print Convert(varchar(32), GetDate(), 21) + ', ' + 'RequestStepTaskXML: Preview results'

		-- Preview the next @jobCountToPreview available jobs

		SELECT TOP ( @jobCountToPreview ) 
		       CJS.Seq,
		       CASE CJS.Association_Type
		           WHEN 1 THEN 'Exclusive Association'
		           WHEN 2 THEN 'Specific Association'
		           WHEN 3 THEN 'Non-associated'
		           WHEN 4 THEN 'Non-associated Generic'
		           WHEN 5 THEN 'Results_Transfer task (specific to this processor''s server)'
		           WHEN 6 THEN 'Results_Transfer task (null storage_server)'
		           WHEN 99 THEN  'Logic error: this should have been updated to 103'
		           WHEN 100 THEN 'Invalid: Not recognized'
		           WHEN 101 THEN 'Invalid: CPUs all busy'
		           WHEN 102 THEN 'Invalid: Archive in progress'
		           WHEN 103 THEN 'Invalid: Job associated with ' + Alternate_Specific_Processor
		           WHEN 104 THEN 'Invalid: Storage Server has had ' + Convert(varchar(12), @MaxSimultaneousJobCount) + ' job steps start within the last ' + Convert(varchar(12), @HoldoffWindowMinutes)  + ' minutes'
		           WHEN 105 THEN 'Invalid: Not enough memory available (' + Convert(varchar(12), CJS.Memory_Usage_MB) + ' > ' + Convert(varchar(12), @availableMemoryMB) + ', see T_Job_Steps.Memory_Usage_MB)'
		           WHEN 106 THEN 'Invalid: Results_transfer task must run on ' + CJS.Storage_Server
		           WHEN 107 THEN 'Invalid: Remote server already running ' + Cast(@maxSimultaneousRunningRemoteSteps as varchar(9)) + ' job steps; limit reached'
		           ELSE 'Warning: Unknown association type'
		       END AS Association_Type,
		       CJS.Tool_Priority,
		       CJS.Job_Priority,
		       CJS.Job,
		       CJS.Step_Number As Step,
		       CJS.State,
		       CJS.Step_Tool,
		       J.Dataset,
		       @processorName AS Processor
		FROM #Tmp_CandidateJobSteps CJS
		     INNER JOIN T_Jobs J
		 ON CJS.Job = J.Job
		ORDER BY Seq
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	--
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RequestStepTaskXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestStepTaskXML] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestStepTaskXML] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestStepTaskXML] TO [svc-dms] AS [dbo]
GO
