/****** Object:  StoredProcedure [dbo].[RemoveOldJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RemoveOldJobs
/****************************************************
**
**	Desc:
**  Delete jobs past their expiration date 
**  from the main tables in the database
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**			09/12/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			06/21/2010 mem - Increased retention to 60 days for successful jobs
**						   - Now removing jobs with state Complete, Inactive, or Ignore
**			03/10/2014 mem - Added call to SynchronizeJobStatsWithJobSteps
**			01/23/2017 mem - Assure that jobs exist in the history before deleting from T_Jobs
**
*****************************************************/
(
	@intervalDaysForSuccess real = 60,	-- successful job must be this old to be deleted (0 -> no deletion)
	@intervalDaysForFail int = 135,		-- failed job must be this old to be deleted (0 -> no deletion)
	@infoOnly tinyint = 0,				-- 1 -> don't actually delete, just dump list of jobs that would have been
	@message varchar(512)='' output,
	@ValidateJobStepSuccess tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @saveTime datetime = getdate()
 
	---------------------------------------------------
 	-- Create table to track the list of affected jobs
 	---------------------------------------------------
	--	
	CREATE TABLE #SJL (
		Job INT,
		State INT
	)

	CREATE TABLE #TmpJobsNotInHistory (
		Job int not null,
		State int,
		JobFinish datetime
	)

	CREATE INDEX #IX_TmpJobsNotInHistory ON #TmpJobsNotInHistory (Job)
	
	---------------------------------------------------
 	-- Validate the inputs
 	---------------------------------------------------
	
	If IsNull(@intervalDaysForSuccess, -1) < 0
		Set @intervalDaysForSuccess = 0
	
	If isNull(@intervalDaysForFail, -1) < 0
		Set @intervalDaysForFail = 0
		
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''

	---------------------------------------------------
	-- Make sure the job Start and Finish values are up-to-date
	---------------------------------------------------
	--
	Exec SynchronizeJobStatsWithJobSteps @infoOnly=0
	
	---------------------------------------------------
 	-- Add old successful jobs to be removed to list
 	---------------------------------------------------
	--	
	if @intervalDaysForSuccess > 0
	begin -- <a>
		declare @cutoffDateTimeForSuccess datetime
		set @cutoffDateTimeForSuccess = dateadd(hour, -1 * @intervalDaysForSuccess * 24, getdate())	

		INSERT INTO #SJL
		SELECT Job, State
		FROM T_Jobs
		WHERE
			(	
				State IN (3, 4, 101)	/* Complete, Inactive, or Ignore */
			) AND
			Finish < @cutoffDateTimeForSuccess
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		 --
		if @myError <> 0
		begin
			set @message = 'Error looking for successful jobs to remove'
			goto Done
		end
		
		if @ValidateJobStepSuccess <> 0
		Begin
			-- Remove any jobs that have failed, in progress, or holding job steps
			DELETE #SJL
			FROM #SJL INNER JOIN
				 T_Job_Steps JS ON #SJL.Job = JS.Job
			WHERE NOT (JS.State IN (4, 6, 7))
 			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount > 0
				Print 'Warning: Removed ' + Convert(varchar(12), @myRowCount) + ' job(s) with one or more steps that was not skipped or complete'
			Else
				Print 'Successful jobs have been confirmed to all have successful (or skipped) steps'			
		End
		
	end -- </a>
 
	---------------------------------------------------
 	-- Add old failed jobs to be removed to list
 	---------------------------------------------------
	--	
	if @intervalDaysForFail > 0
	begin -- <b>
  		declare @cutoffDateTimeForFail datetime
		set @cutoffDateTimeForFail = dateadd(day, -1 * @intervalDaysForFail, getdate())	

 		INSERT INTO #SJL
		SELECT Job, State
		FROM T_Jobs
		WHERE
			State = 5 AND /* "failed" */
			IsNull(Finish, Start) < @cutoffDateTimeForFail
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		 --
		if @myError <> 0
		begin
			set @message = 'Error looking for successful jobs to remove'
			goto Done
		end
	end -- </b>
	
	---------------------------------------------------
	-- Make sure the jobs to be deleted exist 
	-- in T_Jobs_History and T_Job_Steps_History
 	---------------------------------------------------

	INSERT INTO #TmpJobsNotInHistory (Job, State)
	SELECT #SJL.Job,
	       #SJL.State
	FROM #SJL
	     LEFT OUTER JOIN T_Jobs_History JH
	       ON #SJL.Job = JH.Job
	WHERE JH.Job IS NULL
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If Exists (Select * from #TmpJobsNotInHistory)
	Begin
		Declare @JobToAdd int = 0
		Declare @State int
		Declare @SaveTimeOverride datetime
		Declare @continue tinyint = 1
		
		UPDATE #TmpJobsNotInHistory
		SET JobFinish = Coalesce(J.Finish, J.Start, GetDate())
		FROM #TmpJobsNotInHistory Target
		     INNER JOIN T_Jobs J
		       ON Target.Job = J.Job
		
		While @Continue > 0
		Begin
			SELECT TOP 1 @JobToAdd = Job,
			             @State = State,
			             @SaveTimeOverride = JobFinish
			FROM #TmpJobsNotInHistory
			WHERE Job > @JobToAdd
			ORDER BY Job
 			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount = 0
				Set @Continue = 0
			Else
			Begin
				If @infoOnly > 0
					Print 'Call copyJobToHistory for job ' + Cast(@JobToAdd as varchar(9)) + ' with date ' + Cast(@SaveTimeOverride as varchar(32))
				Else
					exec CopyJobToHistory @JobToAdd, @State, @message output, @OverrideSaveTime=1, @SaveTimeOverride=@SaveTimeOverride
			End
		End		
		
	End	
	
	---------------------------------------------------
	-- Do actual deletion
 	---------------------------------------------------

	declare @transName varchar(64) = 'RemoveOldJobs'
	begin transaction @transName

	exec @myError = RemoveSelectedJobs @infoOnly, @message output, @LogDeletions=0

	if @myError = 0
 		commit transaction @transName
 	else
		rollback transaction @transName

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RemoveOldJobs] TO [DDL_Viewer] AS [dbo]
GO
