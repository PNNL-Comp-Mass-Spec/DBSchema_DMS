/****** Object:  StoredProcedure [dbo].[UpdateJobState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateJobState
/****************************************************
**
**	Desc: 
**    Based on step state, look for jobs that have been completed, 
**    or have entered the “in progress” state, 
**    and update state of job locally and dataset in DMS accordingly
**	
**	First step: evaluate state of steps for jobs that are in new or busy state, 
**	or in transient state of being resumed or reset, and determine what new
**	broker job state should be, and accumulate list of jobs whose new state is different than their
**	current state.  Only steps for jobs in New or Busy state are considered.
** 
**	Current             Current                     New          
**	Broker              Job                         Broker       
**	Job                 Steps                       Job          
**	State               States                      State        
**	-----               -------                     ---------    
**	New or Busy         One or more steps failed    Failed
** 
**	New or Busy         All steps complete          Complete
** 
**	New,Busy,Resuming   One or more steps busy      Busy
**
**	Failed              All steps complete          Complete, though only if max Job Step completion time is greater than Finish time in T_Jobs
** 
** 
** 
**	Second step: go through list of jobs from first step whose current state must be changed and
**	take action in broker and DMS as noted.
** 
**	Auth:	grk
**	Date:	12/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/14/2010 grk - Removed path ID fields
**			05/04/2010 grk - Bypass DMS if dataset ID = 0
**			05/08/2010 grk - Update DMS sample prep if dataset ID = 0
**			05/05/2011 mem - Now updating job state from Failed to Complete if all job steps are now complete and at least one of the job steps finished later than the Finish time in T_Jobs
**			11/14/2011 mem - Now using >= instead of > when looking for jobs to change from Failed to Complete because all job steps are now complete or skipped
**			01/16/2012 mem - Added overflow checks when using DateDiff to compute @ProcessingTimeMinutes
**			11/05/2014 mem - Now looking for failed jobs that should be changed to state 2 in T_Jobs
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) output,
	@MaxJobsToProcess int = 0,
	@LoopingUpdateInterval int = 5		-- Seconds between detailed logging while looping through the dependencies
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	declare @job int
	declare @newJobStateInBroker int
	--
	declare @curJob int
	Set @curJob = 0
	--
	declare @resultsFolderName varchar(64)
	Set @resultsFolderName = ''
	--
	
	declare @JobPropagationMode int
	Set @JobPropagationMode = 0

	declare @done tinyint
	declare @JobCountToProcess int
	declare @JobsProcessed int
	declare @script varchar(64)

	
	Declare @StartMin datetime
	Declare @FinishMax datetime
	Declare @ProcessingTimeMinutes real
	Declare @UpdateCode int

	declare @StartTime datetime
	declare @LastLogTime datetime
	declare @StatusMessage varchar(512)	

	---------------------------------------------------
	-- Validate the inputs	
	---------------------------------------------------
	Set @bypassDMS = IsNull(@bypassDMS, 0)
	Set @message = ''
	Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

	Set @StartTime = GetDate()
	Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
	If @LoopingUpdateInterval < 2
		Set @LoopingUpdateInterval = 2

	---------------------------------------------------
	-- FUTURE: may need to look at jobs in the holding
	-- state that have been reset
	---------------------------------------------------

	---------------------------------------------------
	-- table variable to hold state changes
	---------------------------------------------------
	CREATE TABLE #Tmp_ChangedJobs (
		Job int,
		NewState int,
		Results_Folder_Name varchar(128),
		Dataset_Name varchar(128),
		Dataset_ID int,
		Script varchar(64),
		Storage_Server varchar(128)
	)

	CREATE INDEX #IX_Tmp_ChangedJobs_Job ON #Tmp_ChangedJobs (Job)

	---------------------------------------------------
	-- determine what current state of active jobs should be
	-- and get list of the ones that need be changed
	---------------------------------------------------
	--
	INSERT INTO #Tmp_ChangedJobs (
		Job, 
		NewState, 
		Results_Folder_Name,
		Dataset_Name,
		Dataset_ID,
		Script,
		Storage_Server
	)
	SELECT
		Job,
		NewState,
		Results_Folder_Name,
		Dataset,
		Dataset_ID,
		Script,
		Storage_Server
	FROM
	(
		-- look at the state of steps for active or failed jobs
		-- and determine what the new state of each job should be
		SELECT 
		  J.Job,
		  J.Dataset_ID,
		  J.State,
		  J.Results_Folder_Name,
		  J.Storage_Server,
		  CASE 
			WHEN JS_Stats.Failed > 0 THEN 5                     -- Failed
			WHEN JS_Stats.FinishedOrSkipped = Total THEN 3		-- Complete
			WHEN JS_Stats.StartedFinishedOrSkipped > 0 THEN 2	-- In Progress
			Else J.State
		  End AS NewState,
		  J.Dataset,
		  J.Script
		FROM   
		  (
			-- Count the number of steps for each job 
			-- that are in the busy, finished, or failed states
			-- (for jobs that are in new, in progress, or resuming state)
			SELECT   
				JS.Job,
				COUNT(*) AS Total,
				SUM(CASE 
					WHEN JS.State IN (3,4,5) THEN 1
					Else 0
					End) AS StartedFinishedOrSkipped,
				SUM(CASE 
					WHEN JS.State IN (6) THEN 1
					Else 0
					End) AS Failed,
				SUM(CASE 
					WHEN JS.State IN (3,5) THEN 1
					Else 0
					End) AS FinishedOrSkipped
			FROM T_Job_Steps JS
			     INNER JOIN T_Jobs J
			       ON JS.Job = J.Job
			WHERE (J.State IN (1,2,5,20))	-- New, in progress, failed, or resuming state
			GROUP BY JS.Job, J.State
		   ) AS JS_Stats 
		   INNER JOIN T_Jobs AS J
			 ON JS_Stats.Job = J.Job
	) UpdateQ
	WHERE UpdateQ.State <> UpdateQ.NewState
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	Set @JobCountToProcess = @myRowCount

/*
	---------------------------------------------------
	-- See if any failed jobs can now be set to complete
	---------------------------------------------------
	--
	INSERT INTO #Tmp_ChangedJobs (
		Job, 
		NewState, 
		Results_Folder_Name,
		Dataset_Name,
		Dataset_ID,
		Script,
		Storage_Server
	)
	SELECT
		Job,
		NewState,
		Results_Folder_Name,
		Dataset,
		Dataset_ID,
		Script,
		Storage_Server
	FROM
	(
		-- The where clause for this query limits the results to only include
		-- jobs that are failed, but should be finished
		SELECT 
		  TNJ.Job,
		  TCJ.Dataset_ID,
		  TCJ.State,
		  TCJ.Results_Folder_Name,
		  TCJ.Storage_Server,
		  3 AS NewState,
		  TCJ.Dataset,
		  TCJ.Script
		FROM   
		  (
			-- count the number of steps for each job 
			-- that are in the busy, finished, or failed states
			-- (for jobs that are in new, in progress, or resuming state)
			SELECT   
				JS.Job,
				COUNT(*) AS Total,
				SUM(CASE 
					WHEN JS.State IN (3,4,5) THEN 1
					Else 0
					End) AS StartedOrFinished,
				SUM(CASE 
					WHEN JS.State IN (6) THEN 1
					Else 0
					End) AS Failed,
				SUM(CASE 
					WHEN JS.State IN (3,5) THEN 1
					Else 0
					End) AS Finished,
				MAX(JS.Finish) AS MostRecentFinish
			FROM T_Job_Steps JS
			     INNER JOIN T_Jobs J
			       ON JS.Job = J.Job
			WHERE (J.State = 5)
			GROUP BY JS.Job, J.State
		   ) AS TNJ 
		   INNER JOIN T_Jobs AS TCJ
			 ON TNJ.Job = TCJ.Job
		   WHERE TNJ.Failed = 0 AND 
		         TNJ.Finished = Total AND 
		         TNJ.MostRecentFinish >= IsNull(TCJ.Finish, '1/1/2000')
	) TX
	WHERE TX.State <> TX.NewState
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	Set @JobCountToProcess = @JobCountToProcess + @myRowCount
*/

	---------------------------------------------------
	-- Loop through jobs whose state has changed 
	-- and update local state and DMS state
	---------------------------------------------------
	--
	Set @done = 0
	Set @JobsProcessed = 0
	Set @LastLogTime = GetDate()
	SET @script = ''
	DECLARE
		@datasetNum VARCHAR(128),
		@datasetID INT,
		@storageServerName VARCHAR(128)
	--
	While @done = 0
	Begin --<a>
		Set @job = 0
		--
		SELECT TOP 1 
			@job = Job,
			@curJob = Job,
			@newJobStateInBroker = NewState,
			@resultsFolderName = Results_Folder_Name,
			@script = Script,
			@datasetNum = Dataset_Name,
			@datasetID = Dataset_ID,
			@storageServerName = Storage_Server
		FROM   
			#Tmp_ChangedJobs
		WHERE
			Job > @curJob
		ORDER BY Job
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
			
		If @job = 0
			Set @done = 1
		Else
		Begin --<b>

			---------------------------------------------------
			-- Examine the steps for this job to determine actual start/End times
			---------------------------------------------------

			Set @StartMin = Null
			Set @FinishMax = Null
			Set @ProcessingTimeMinutes = 0

			-- Note: You can use the following query to update @StartMin and @FinishMax
			-- However, when a job has some completed steps and some not yet started, this query 
			--  will trigger the warning "Null value is eliminated by an aggregate or other Set operation"
			-- The warning can be safely ignored, but tends to bloat up the Sql Server Agent logs, 
			--  so we are instead populating @StartMin and @FinishMax separately
			/*
			SELECT @StartMin = Min(Start), 
				   @FinishMax = Max(Finish)
			FROM T_Job_Steps
			WHERE (Job = @job)
 			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			*/

			-- Update @StartMin
			-- Note that if no steps have started yet, then @StartMin will be Null
			SELECT @StartMin = Min(Start)	   
			FROM T_Job_Steps
			WHERE (Job = @job) AND Not Start Is Null
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			-- Update @FinishMax
			-- Note that if no steps have finished yet, then @FinishMax will be Null
			SELECT @FinishMax = Max(Finish)
			FROM T_Job_Steps
			WHERE (Job = @job) AND Not Finish Is Null
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount


			---------------------------------------------------
			-- Examine the steps for this job to determine total processing time
			-- Steps with the same Step Tool name are assumed to be steps that can run in parallel;
			--   therefore, we use a Max(ProcessingTime) on steps with the same Step Tool name
			-- We use ABS(DATEDIFF(HOUR, start, xx)) to avoid overflows produced with
			--   DATEDIFF(SECOND, Start, xx) when Start and Finish are widely different
			---------------------------------------------------

			SELECT @ProcessingTimeMinutes = SUM(SecondsElapsedMax) / 60.0
			FROM ( SELECT Step_Tool,
			              MAX(ISNULL(SecondsElapsed1, 0) + ISNULL(SecondsElapsed2, 0)) AS SecondsElapsedMax
			       FROM ( SELECT Step_Tool,
			                     CASE
			                         WHEN ABS(DATEDIFF(HOUR, start, finish)) > 100000 THEN 360000000
			                         ELSE DATEDIFF(SECOND, Start, Finish)
			                     END AS SecondsElapsed1,
			                     CASE
			                         WHEN (NOT Start IS NULL) AND
			                              Finish IS NULL THEN 
											CASE
												WHEN ABS(DATEDIFF(HOUR, start, GETDATE())) > 100000 THEN 360000000
												ELSE DATEDIFF(SECOND, Start, getdate())
											END
			                         ELSE NULL
			                     END AS SecondsElapsed2
			              FROM T_Job_Steps
			              WHERE (Job = @job) 
			              ) StatsQ
			       GROUP BY Step_Tool 
			       ) StepToolQ
 			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			Set @ProcessingTimeMinutes = IsNull(@ProcessingTimeMinutes, 0)
			
			---------------------------------------------------
			-- update local job state and timestamp (If appropriate)
			---------------------------------------------------
			--				
			UPDATE T_Jobs
			Set 
				State = @newJobStateInBroker,
				Start = 
					CASE 
					WHEN @newJobStateInBroker >= 2 THEN IsNull(@StartMin, GetDate())	-- Job state is 2 or higher
					Else Start
					End,
				Finish = 
					CASE 
					WHEN @newJobStateInBroker IN (3, 5) THEN @FinishMax					-- 3=Complete, 5=Failed
					Else Finish
					End
			WHERE Job = @job
 			--
			SELECT @myError = @@error, @myRowCount = @@rowcount


			---------------------------------------------------
			-- make changes to DMS if we are enabled to do so
			---------------------------------------------------
			--
			If @bypassDMS = 0 AND @datasetID <> 0
			Begin --<c>

				Exec @myError = UpdateDMSDatasetState
									@job,
									@datasetNum,
									@datasetID,
									@Script,
									@storageServerName,
									@newJobStateInBroker,
									@message output
				
				If @myError <> 0
					Exec PostLogEntry 'Error', @message, 'UpdateJobState'					
			End --</c>

			If @bypassDMS = 0 AND @datasetID = 0
			Begin --<d>

				Exec @myError = UpdateDMSPrepState
							@job,
							@Script,
							@newJobStateInBroker,
							@message output
				
				If @myError <> 0
					Exec PostLogEntry 'Error', @message, 'UpdateJobState'					
			End --<d>

			---------------------------------------------------
			-- save job history
			---------------------------------------------------
			--
			exec @myError = CopyJobToHistory @job, @newJobStateInBroker, @message output

			Set @JobsProcessed = @JobsProcessed + 1
		End --</b>
		
		If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
		Begin
			Set @StatusMessage = '... Updating job state: ' + Convert(varchar(12), @JobsProcessed) + ' / ' + Convert(varchar(12), @JobCountToProcess)
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateJobState'
			Set @LastLogTime = GetDate()
		End
		
		If @MaxJobsToProcess > 0 And @JobsProcessed >= @MaxJobsToProcess
			Set @done = 1
			
	End --</a>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
