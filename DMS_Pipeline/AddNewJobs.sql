/****** Object:  StoredProcedure [dbo].[AddNewJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddNewJobs
/****************************************************
**
**	Desc:
**    Add jobs from DMS that are in “New” state that aren’t
**    already in table.  Choose script for DMS analysis tool.
**
** DMS       Broker           Action by broker
** Job       Job
** State     State
** -----     ------           ---------------------------------------
** New       (job not         Import job:
**            in broker)      - Add it to local job table
**                            - Set local job state to freshly imported 
**                              (CreateJobSteps will set local state to New)
** 
** New       failed           Resume job:
**           holding          - Reset any failed/holding job steps to waiting
**                            - Reset Evaluated and Triggered to 0 in T_Job_Step_Dependencies for the affected steps
**                            - Set local job state to "resuming" 
**                              (UpdateJobState will handle final job state update)
**                              (UpdateDependentSteps will handle final job step state updates)
** 
** New       complete         Reset job:
**                            - Delete entries from job, steps, parameters, and dependencies tables
**                            - Set local job state to freshly imported (see import job above)
** 
** New       holding          Resume job: (see description above)
** 
** holding   (any state)      Suspend Job:
**                            - Set local job state to holding
** 
**
**	Auth:	grk
**			08/25/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			09/25/2008 grk - added filtering to only add new jobs that match currently active scripts
**			12/05/2008 mem - Now populating Transfer_Folder_Path in T_Jobs
**			12/09/2008 grk - Clarified comment description of how DMS state affects broker
**			01/07/2009 mem - Updated job resume logic to match steps with state of 6 or 7 in T_Job_Steps; also updated to match jobs with state of 5 or 8 in T_Jobs
**			01/17/2009 mem - Moved updating of T_Jobs.Archive_Busy to SyncJobInfo (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**			02/12/2009 mem - Updated job resume logic to change step states from 6 or 7 to 1=waiting (instead of 2=enabled) and to reset Evaluated and Triggered to 0 in T_Job_Step_Dependencies for the affected steps
**						   - Added parameter @DebugMode
**			03/02/2009 grk - added code to update job parameters when jobs are resumed (from hold or fail)
**			03/11/2009 mem - Now also resetting jobs if they are running or failed, but do not have any running or completed job steps (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**			06/01/2009 mem - Moved the job resuming updates to occur outside the transaction (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**						   - Added parameter @MaxJobsToProcess
**			06/03/2009 mem - Now updating Transfer_Folder_Path when resuming a job
**			06/04/2009 mem - Added parameters @LogIntervalThreshold, @LoggingEnabled, and @LoopingUpdateInterval
**			07/29/2009 mem - Now populating Comment in T_Jobs
**			03/03/2010 mem - Now populating Storage_Server in T_Jobs
**			03/21/2011 mem - Added parameter @infoOnly and moved position of parameter @DebugMode
**						   - Now calling UpdateInputFolderUsingSourceJobComment if needed when resuming jobs
**			04/04/2011 mem - Now populating Special_Processing in T_Jobs
**						   - Removed call to UpdateInputFolderUsingSourceJobComment
**						   - Now using function GetJobParamTableLocal() to lookup a value in T_Job_Parameters
**			07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**			07/12/2011 mem - Now calling ValidateJobServerInfo
**			01/09/2012 mem - Now populating Owner in T_Jobs
**			01/12/2012 mem - Now only auto-adding jobs for scripts with Backfill_to_DMS = 0
**			01/19/2012 mem - Now populating DataPkgID in T_Jobs
**			04/28/2014 mem - Bumped up @MaxJobsToAddResetOrResume from 1 million to 1 billion
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**			11/07/2014 mem - No longer performing a full job reset for ICR2LS or LTQ_FTPek jobs where the job state is failed but the DMS state is new
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) = '' output,
	@MaxJobsToProcess int = 0,
	@LogIntervalThreshold int = 15,		-- If this procedure runs longer than this threshold, then status messages will be posted to the log
	@LoggingEnabled tinyint = 0,		-- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @LogIntervalThreshold seconds elapse
	@LoopingUpdateInterval int = 5,		-- Seconds between detailed logging while looping through the dependencies
	@infoOnly tinyint = 0,				-- 1 to preview changes that would be made; 2 to add new jobs but do not create job steps
	@DebugMode tinyint = 0				-- 0 for no debugging; 1 to see debug messages
)
As

	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @currJob int
	declare @Dataset varchar(128)
	declare @continue tinyint

	declare @JobsProcessed int
	Declare @JobCountToResume int
	declare @JobCountToReset int

	Declare @ResumeUpdatesRequired tinyint
	Set @ResumeUpdatesRequired = 0
	
	Declare @MaxJobsToAddResetOrResume int

	declare @StartTime datetime
	declare @LastLogTime datetime
	declare @StatusMessage varchar(512)	
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @bypassDMS = IsNull(@bypassDMS, 0)	
	Set @DebugMode = IsNull(@DebugMode, 0)
	Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)
	
	set @message = ''
	if @bypassDMS <> 0
		goto Done

	If @MaxJobsToProcess <= 0
		Set @MaxJobsToAddResetOrResume = 1000000000
	Else
		Set @MaxJobsToAddResetOrResume = @MaxJobsToProcess

	Set @StartTime = GetDate()
	Set @LoggingEnabled = IsNull(@LoggingEnabled, 0)
	Set @LogIntervalThreshold = IsNull(@LogIntervalThreshold, 15)
	Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
	
	If @LogIntervalThreshold = 0
		Set @LoggingEnabled = 1
		
	If @LoopingUpdateInterval < 2
		Set @LoopingUpdateInterval = 2
	
	---------------------------------------------------
	-- table variable to hold jobs from DMS to process
	---------------------------------------------------
	--
	CREATE TABLE #Tmp_DMSJobs (
		Job int,
		Priority int,
		Script varchar(64),
		Dataset varchar(128),
		Dataset_ID int,
		Results_Folder_Name varchar(128),
		State int,
		Transfer_Folder_Path varchar(512),
		Comment varchar(512),
		Special_Processing varchar(512),
		Owner varchar(64)
	)

	CREATE INDEX #IX_Tmp_DMSJobs_Job ON #Tmp_DMSJobs (Job)
	
	-- Additional Table Variables
	CREATE TABLE #Tmp_ResetJobs (
		Job int
	)

	CREATE INDEX #IX_Tmp_ResetJobs_Job ON #Tmp_ResetJobs (Job)

	CREATE TABLE #Tmp_ResumedJobs (
		Job int,
		Dataset varchar(128)
	)

	CREATE INDEX #IX_Tmp_ResumedJobs_Job ON #Tmp_ResumedJobs (Job)

	CREATE TABLE #Tmp_JobDebugMessages (
		Message varchar(256),
		Job int,
		Script varchar(164),
		DMS_State int,
		PipelineState int,
		EntryID int identity(1,1)
	)

	CREATE INDEX #IX_Tmp_JobDebugMessages_Job ON #Tmp_JobDebugMessages (Job)


	---------------------------------------------------
	-- define transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'AddNewJobs'
		
	---------------------------------------------------
	-- get list of new or held jobs from DMS
	---------------------------------------------------
	--
	INSERT INTO #Tmp_DMSJobs
		(Job, Priority, Script, Dataset, Dataset_ID, State, Transfer_Folder_Path, Comment, Special_Processing, Owner)
	SELECT 
		Job, Priority, Tool, Dataset, Dataset_ID, State, Transfer_Folder_Path, Comment, Special_Processing, Owner
	FROM 
		V_DMS_PipelineJobs AS VGP
	WHERE Tool IN (SELECT Script FROM T_Scripts WHERE Enabled = 'Y')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
     --
	if @myError <> 0
	begin
		set @message = 'Error copying new jobs from DMS'
		goto Done
	end

	if @myRowCount = 0
	begin
		-- No new or held jobs were found in DMS
		
		If @DebugMode <> 0
			INSERT INTO #Tmp_JobDebugMessages (Message, Job)
			VALUES ('No New or held jobs found in DMS', 0)

		-- Exit this procedure
		Goto Done
	end
	else
	begin
		-- New or held jobs are available		
		If @DebugMode <> 0
			INSERT INTO #Tmp_JobDebugMessages (Message, Job, Script, DMS_State, PipelineState)
			SELECT 'New or Held Jobs', J.Job, J.Script, J.State, T.State
			FROM #Tmp_DMSJobs J
			     LEFT OUTER JOIN T_Jobs T
			       ON J.Job = T.Job
			ORDER BY Job
	end

	---------------------------------------------------
	-- Find jobs to reset
	---------------------------------------------------
	--
	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @LoggingEnabled = 1
		Set @StatusMessage = 'Finding jobs to reset'
		exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
	End
		
	-- Start transaction #1
	--
	begin transaction @transName

	---------------------------------------------------
	-- Reset job:
	-- delete existing job info from database
	---------------------------------------------------
	--
	-- Find jobs that are complete in the broker, but in state 1=New in DMS
	--
	--
	INSERT INTO #Tmp_ResetJobs (Job)
	SELECT T.Job
	FROM #Tmp_DMSJobs T
	     INNER JOIN T_Jobs
	       ON T.Job = T_Jobs.Job
	WHERE T_Jobs.State = 4 AND                -- Complete in the broker
	      T.State = 1                         -- New in DMS
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
    --
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error finding Reset jobs'
		goto Done
	end
	--
	set @JobCountToReset = @myRowCount
	--
	If @myRowCount > 0
	Begin
		Set @StatusMessage = 'Resetting ' + Convert(varchar(12), @myRowCount) + ' completed job'
		If @myRowCount <> 1
			Set @StatusMessage = @StatusMessage + 's'
		exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
	end
	
	-- Also look for jobs where the DMS state is "New", the broker state is 2, 5, or 8 (In Progress, Failed, or Holding), 
	--  and none of the jobs Steps have completed or are running
	-- It is typically safer to perform a full reset on these jobs (rather than a resume) in case an admin changed the settings file for the job
	-- Exception: LTQ_FTPek and ICR2LS jobs because ICR-2LS runs as the first step and we create checkpoint copies of the .PEK files to allow for a resume
	-- 
	INSERT INTO #Tmp_ResetJobs (Job)
	SELECT T.Job
	FROM #Tmp_DMSJobs T
	     INNER JOIN T_Jobs
	       ON T.Job = T_Jobs.Job
	     LEFT OUTER JOIN ( SELECT J.Job
	                       FROM T_Jobs J
	                            INNER JOIN T_Job_Steps JS
	                              ON J.Job = JS.Job
	                       WHERE (J.State IN (2, 5, 8)) AND   -- Jobs that are running, failed, or holding
	                             (JS.State IN (4, 5))         -- Steps that are running or finished
	                      ) LookupQ
	 ON T_Jobs.Job = LookupQ.Job
	WHERE (T_Jobs.State IN (2, 5, 8)) AND
	      (NOT T.Script IN ('LTQ_FTPek','ICR2LS')) AND
	      (LookupQ.Job IS NULL)                       -- Assure there are no running or finished steps
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
    --
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error finding additional jobs to Reset'
		goto Done
	end
	--
	If @myRowCount > 0
	Begin
		set @JobCountToReset = @JobCountToReset + @myRowCount
	
		Set @StatusMessage = 'Resetting ' + Convert(varchar(12), @myRowCount) + ' job'
		If @myRowCount <> 1
			Set @StatusMessage = @StatusMessage + 's that are In Progress, Failed, or Holding and have no completed or running job steps'
		Else
			Set @StatusMessage = @StatusMessage + ' that is In Progress, Failed, or Holding and has no completed or running job steps'
		
		exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
	end
	
	--
	if @JobCountToReset = 0
	Begin
		If @DebugMode <> 0
			INSERT INTO #Tmp_JobDebugMessages (Message, Job)
			VALUES ('No Jobs to Reset', 0)
	End
	Else
	begin --<Reset>
		
		If @MaxJobsToProcess > 0
		Begin
			-- Limit the number of jobs to reset
			DELETE FROM #Tmp_ResetJobs
			WHERE NOT Job IN ( SELECT TOP ( @MaxJobsToProcess ) Job
							FROM #Tmp_ResetJobs
							ORDER BY Job )
		End

		If @DebugMode <> 0
		Begin
			INSERT INTO #Tmp_JobDebugMessages (Message, Job, Script, DMS_State, PipelineState)
			SELECT 'Jobs to Reset', J.Job, J.Script, J.State, T.State
			FROM #Tmp_ResetJobs R INNER JOIN #Tmp_DMSJobs J ON R.Job = J.Job
			     INNER JOIN T_Jobs T ON J.Job = T.Job
			ORDER BY Job
		End
		Else
		Begin -- <ResetDeletes>

			---------------------------------------------------
 			-- set up and populate temp table and call sproc
 			-- to delete jobs listed in it
			---------------------------------------------------
			--
			CREATE TABLE #SJL (Job INT)
			
			CREATE INDEX #IX_SJL_Job ON #SJL (Job)
			--
			INSERT INTO #SJL (Job)
			SELECT Job FROM #Tmp_ResetJobs
			--
			exec @myError = RemoveSelectedJobs @infoOnly, @message output, @LogDeletions=0
			--
			if @myError <> 0
			begin
				rollback transaction @transName
				goto Done
			end
		End -- </ResetDeletes>
	end --</Reset>


	if @infoOnly = 0 Or @infoOnly = 2
	Begin -- <ImportNewJobs>

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = 'Adding new jobs to T_Jobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
		End

		---------------------------------------------------
		-- Import job:
		-- Copy new jobs from DMS that are not already in table
		-- (only take jobs that have script that is currently active)
		---------------------------------------------------
		--
		INSERT INTO T_Jobs
			(Job, Priority, Script, State, Dataset, Dataset_ID, Transfer_Folder_Path, 
			Comment, Special_Processing, Storage_Server, Owner, DataPkgID)
		SELECT TOP (@MaxJobsToAddResetOrResume)
			DJ.Job, DJ.Priority, DJ.Script, 0 as State, DJ.Dataset, DJ.Dataset_ID, DJ.Transfer_Folder_Path, 
			DJ.Comment, DJ.Special_Processing, dbo.udfExtractServerName(DJ.Transfer_Folder_Path) AS Storage_Server, DJ.Owner, 0 AS DataPkgID
		FROM #Tmp_DMSJobs DJ
		     INNER JOIN T_Scripts S
		       ON DJ.Script = S.Script
		WHERE State = 1 AND
		      Job NOT IN ( SELECT Job FROM T_Jobs ) AND
		      S.Enabled = 'Y' AND
		      S.Backfill_to_DMS = 0
		ORDER BY Job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Adding new jobs to local table'
			goto Done
		end
	End -- </ImportNewJobs>
	

	---------------------------------------------------
	-- Find jobs to Resume
	--
	-- Jobs that are reset in DMS will be in "new" state, but
	-- there will be a entry for the job in the local
	-- table that is in the "failed" or "holding" state.
	-- For all such jobs, set all steps that are in "failed" 
	-- state to the "waiting" state and set the job
	-- state to "resuming".
	---------------------------------------------------
	--
	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @LoggingEnabled = 1
		Set @StatusMessage = 'Finding jobs to Resume'
		exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
	End

	INSERT INTO #Tmp_ResumedJobs (Job, Dataset)
	SELECT TOP (@MaxJobsToAddResetOrResume) J.Job, J.Dataset
	FROM T_Jobs J
	WHERE (J.State IN (5,8)) AND					-- 5=Failed, 8=Holding
		  (J.Job IN (SELECT Job FROM #Tmp_DMSJobs WHERE State = 1))
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
    --
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error finding Resumed jobs'
		goto Done
	end
	Set @JobCountToResume = @myRowCount

	if @JobCountToResume = 0
	Begin
		If @DebugMode <> 0
			INSERT INTO #Tmp_JobDebugMessages (Message, Job)
			VALUES ('No Jobs to Resume', 0)
	End
	Else
	begin --<Resume>
		
		If @DebugMode <> 0
		Begin
			INSERT INTO #Tmp_JobDebugMessages (Message, Job, Script, DMS_State, PipelineState)
			SELECT 'Jobs to Resume', J.Job, J.Script, J.State, T.State
			FROM #Tmp_ResumedJobs R
			     INNER JOIN #Tmp_DMSJobs J
			 ON R.Job = J.Job
			     INNER JOIN T_Jobs T
			       ON J.Job = T.Job
			ORDER BY Job
		End
		Else
		Begin
		
			---------------------------------------------------
			-- Note: 
			--   In order to avoid cross-server distributed transactions, the updates for jobs in #Tmp_ResumedJobs
			--   will occur after the transaction is committed.  This is required because 
			--   UpdateJobParameters calls CreateParametersForJob, which calls GetJobParamTable, and if a transaction
			--   is in progress and GetJobParamTable accesses another server (via V_DMS_PipelineJobParameters), we may get these errors:
			--     OLE DB provider "SQLNCLI10" for linked server "Gigasax" returned message "The transaction manager has disabled its support for remote/network transactions.".
			--     Msg 7391, Level 16, State 2, Procedure CreateParametersForJob, Line 46
			--     The operation could not be performed because OLE DB provider "SQLNCLI10" for linked server "Gigasax" was unable to begin a distributed transaction.
			--
			--   Delaying the updates will also avoid running a potentially long While loop in the middle of a transaction
			--------------------------------------------------- 
			
			Set @ResumeUpdatesRequired = 1

		End
	end -- </Resume>

	If @DebugMode <> 0
	Begin
		INSERT INTO #Tmp_JobDebugMessages (Message, Job, Script, DMS_State, PipelineState)
		SELECT 'Jobs to Suspend', J.Job, J.Script, J.State, T.State
		FROM T_Jobs T
		     INNER JOIN #Tmp_DMSJobs J
		       ON T.Job = J.Job
		WHERE
			(T.State <> 8) AND					-- 8=Holding
			(T.Job IN (SELECT Job FROM #Tmp_DMSJobs WHERE State = 8))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
			INSERT INTO #Tmp_JobDebugMessages (Message, Job)
			VALUES ('No Jobs to Suspend', 0)
	End
	Else
	Begin -- <SuspendUpdates>
			
		---------------------------------------------------
		-- Find jobs to suspend
		---------------------------------------------------

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = 'Finding jobs to Suspend (Hold)'
			exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
		End

		-- Set local job state to holding for jobs
		-- that are in holding state in DMS
		--
		UPDATE T_Jobs
		SET State = 8							-- 8=Holding
		WHERE (T_Jobs.State <> 8) AND
		      (T_Jobs.Job IN ( SELECT Job
		                       FROM #Tmp_DMSJobs
		                       WHERE State = 8 ))
   		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error updating held jobs'
			goto Done
		end

		If @myRowCount > 0
		Begin
			Set @StatusMessage = 'Suspended ' + Convert(varchar(12), @myRowCount) + ' job'
			If @myRowCount <> 1
				Set @StatusMessage = @StatusMessage + 's'
			exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
		End
	End -- </SuspendUpdates>
	
	-- Commit the changes for Transaction #1
	--
	commit transaction @transName

	
	If @ResumeUpdatesRequired <> 0
	Begin -- <ResumeUpdates>

		---------------------------------------------------
		-- Process the jobs that need to be resumed
		---------------------------------------------------
		--
		Set @StatusMessage = 'Resuming ' + Convert(varchar(12), @JobCountToResume) + ' job'
		If @JobCountToResume <> 1
			Set @StatusMessage = @StatusMessage + 's'
		exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = 'Updating parameters for resumed jobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
		End

		-- update parameters for jobs being resumed (jobs in #Tmp_ResumedJobs)
		--
		set @continue = 1
		set @currJob = 0
		set @JobsProcessed = 0
		Set @LastLogTime = GetDate()
		--
		while @continue = 1
		begin

			SELECT TOP 1 @currJob = Job,
			             @Dataset = Dataset
			FROM #Tmp_ResumedJobs
			WHERE Job > @currJob
			ORDER BY Job
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			if @myRowCount = 0
				set @continue = 0
			else
			begin
				exec @myError = UpdateJobParameters @currJob, @infoOnly = @infoOnly, @message = @message Output
				if @myError <> 0
				begin
					set @message = 'Error updating parameters for job ' + Convert(varchar(12), @currJob)
					exec PostLogEntry 'Error', @message, 'AddNewJobs'
					goto Done
				end				
				
				---------------------------------------------------
				-- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
				---------------------------------------------------
				--
				exec ValidateJobServerInfo @currJob, @UseJobParameters=1, @DebugMode = @DebugMode

				Set @JobsProcessed = @JobsProcessed + 1
			end
			
			If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
			Begin
				-- Make sure @LoggingEnabled is 1
				Set @LoggingEnabled = 1
				
				Set @StatusMessage = '... Updating parameters for resumed jobs: ' + Convert(varchar(12), @JobsProcessed) + ' / ' + Convert(varchar(12), @JobCountToResume)
				exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
				Set @LastLogTime = GetDate()
			End
		end

		
		-- Make sure the job Comment and Special_Processing fields are up-to-date in T_Jobs
		UPDATE T_Jobs
		SET Comment = DJ.Comment,
		    Special_Processing = DJ.Special_Processing
		FROM T_Jobs J
		     INNER JOIN #Tmp_DMSJobs DJ
		       ON J.Job = DJ.Job
		     INNER JOIN #Tmp_ResumedJobs RJ
		       ON DJ.Job = RJ.Job
		WHERE IsNull(J.Comment, '') <> IsNull(DJ.Comment,'') OR
		      IsNull(J.Special_Processing, '') <> IsNull(DJ.Special_Processing, '')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount > 0
		Begin
			Set @StatusMessage = '... Updated the job comment or special_processing data in T_Jobs for ' + Convert(varchar(12), @myRowCount) + ' resumed job'
			If @myRowCount > 1
				Set @StatusMessage = @StatusMessage + 's'
				
			exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
		End


		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = 'Updating T_Job_Steps, T_Job_Step_Dependencies, and T_Jobs for resumed jobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
		End
		
		-- Start transaction #2
		--
		begin transaction @transName
		
		---------------------------------------------------
		-- set any failed or holding job steps to waiting
		---------------------------------------------------
		--
		UPDATE T_Job_Steps
		SET State = 1,					-- 1=waiting
			Tool_Version_ID = 1			-- 1=Unknown
		WHERE
			State IN (6,7) AND			-- 6=Failed, 7=Holding
			Job IN (SELECT Job From #Tmp_ResumedJobs)
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error updating Resume job steps'
			goto Done
		end

		---------------------------------------------------
		-- Reset the entries in T_Job_Step_Dependencies for any steps with state 1
		---------------------------------------------------
		--
		UPDATE T_Job_Step_Dependencies
		SET Evaluated = 0,
			Triggered = 0
		FROM T_Job_Step_Dependencies JSD INNER JOIN
			T_Job_Steps JS ON 
			JSD.Job = JS.Job AND 
			JSD.Step_Number = JS.Step_Number
		WHERE
			JS.State = 1 AND			-- 1=Waiting
			JS.Job IN (SELECT Job From #Tmp_ResumedJobs)
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error updating Resume job step depencies'
			goto Done
		end
			
		---------------------------------------------------
		-- set job state to "resuming"
		---------------------------------------------------
		--
		UPDATE T_Jobs
		SET State = 20						-- 20=resuming
		WHERE
			Job IN (SELECT Job From #Tmp_ResumedJobs)
   		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error updating Resume jobs'
			goto Done
		end
		
		---------------------------------------------------
		-- Commit the changes for Transaction #2
		---------------------------------------------------
		--
		commit transaction @transName
		
	End -- </ResumeUpdates>

	If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
	Begin
		Set @LoggingEnabled = 1
		Set @StatusMessage = 'AddNewJobs Complete'
		exec PostLogEntry 'Progress', @StatusMessage, 'AddNewJobs'
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	If @DebugMode <> 0
		SELECT *
		FROM #Tmp_JobDebugMessages
		ORDER BY EntryID

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddNewJobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewJobs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewJobs] TO [PNL\D3M580] AS [dbo]
GO
