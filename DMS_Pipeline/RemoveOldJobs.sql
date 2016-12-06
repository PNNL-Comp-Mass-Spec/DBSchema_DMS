/****** Object:  StoredProcedure [dbo].[RemoveOldJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.RemoveOldJobs
/****************************************************
**
**	Desc:
**  Delete jobs past their expiration date 
**  from the main tables in the database
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**			12/18/2008 grk - initial release
**			12/29/2008 mem - Updated to use Start time if Finish time is null and the Job has failed (State=5)
**			02/19/2009 grk - Added call to RemoveSelectedJobs (Ticket #723)
**			02/26/2009 mem - Now passing @LogDeletions=0 to RemoveSelectedJobs
**			05/31/2009 mem - Updated @intervalDaysForSuccess to support partial days (e.g. 0.5)
**			02/24/2012 mem - Added parameter @MaxJobsToProcess with a default of 25000
**			08/20/2013 mem - Added parameter @LogDeletions
**			03/10/2014 mem - Added call to SynchronizeJobStatsWithJobSteps
**
*****************************************************/
(
	@intervalDaysForSuccess real = 45,	-- successful job must be this old to be deleted (0 -> no deletion)
	@intervalDaysForFail int = 135,		-- failed job must be this old to be deleted (0 -> no deletion)
	@infoOnly tinyint = 0,				-- 1 -> don't actually delete, just dump list of jobs that would have been
	@message varchar(512)='' output,
	@ValidateJobStepSuccess tinyint = 0,
	@JobListOverride varchar(max) = '',		-- Comma separated list of jobs to remove from T_Jobs, T_Job_Steps, and T_Job_Parameters
	@MaxJobsToProcess int = 25000,
	@LogDeletions tinyint = 0			-- When 1, then logs each deleted job number in T_Log_Entries; when 2 then prints a log message (but does not log to T_Log_Entries)
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0
	
	declare @saveTime datetime
	set @saveTime = getdate()
 
	---------------------------------------------------
 	-- Create table to track the list of affected jobs
 	---------------------------------------------------
	--	
	CREATE TABLE #SJL (
		Job INT,
		State INT
	)

	---------------------------------------------------
 	-- Validate the inputs
 	---------------------------------------------------
	
	If IsNull(@intervalDaysForSuccess, -1) < 0
		Set @intervalDaysForSuccess = 0
	
	If isNull(@intervalDaysForFail, -1) < 0
		Set @intervalDaysForFail = 0
		
	Set @JobListOverride = IsNull(@JobListOverride, '')
	
	Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 25000)
	Set @LogDeletions = IsNull(@LogDeletions, 0)

	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''

	---------------------------------------------------
	-- Make sure the job Start and Finish values are up-to-date
	---------------------------------------------------
	--
	Exec SynchronizeJobStatsWithJobSteps @infoOnly=0

	---------------------------------------------------
 	-- add old successful jobs to be removed to list
 	---------------------------------------------------
	--	
	if @intervalDaysForSuccess > 0
	begin -- <a>
		declare @cutoffDateTimeForSuccess datetime
		set @cutoffDateTimeForSuccess = dateadd(hour, -1 * @intervalDaysForSuccess * 24, getdate())	

		INSERT INTO #SJL
		SELECT TOP (@MaxJobsToProcess) Job, State
		FROM T_Jobs
		WHERE
			State = 4 AND /* "Complete"*/
			Finish < @cutoffDateTimeForSuccess
		ORDER BY Finish
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
			WHERE NOT (JS.State IN (3, 5))
 			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount > 0
				Print 'Warning: Removed ' + Convert(varchar(12), @myRowCount) + ' job(s) with one or more steps that was not skipped or complete'
			Else
				Print 'Successful jobs have been confirmed to all have successful (or skipped) steps'			
		End
		
	end -- </a>
 
	---------------------------------------------------
 	-- add old failed jobs to be removed to list
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
	-- Add any jobs defined in @JobListOverride
	---------------------------------------------------
	If @JobListOverride <> ''
	Begin
		INSERT INTO #SJL
		SELECT Job,
		       State
		FROM T_Jobs
		WHERE Job IN ( SELECT DISTINCT VALUE
		               FROM dbo.udfParseDelimitedIntegerList ( @JobListOverride, ',' ) )
			  AND NOT Job IN (SELECT Job FROM #SJL)
		
	End
	 
	---------------------------------------------------
	-- FUTURE: make sure candidates have some history?
 	---------------------------------------------------

	---------------------------------------------------
	-- do actual deletion
 	---------------------------------------------------

	declare @transName varchar(64)
	set @transName = 'RemoveOldJobs'
	begin transaction @transName

	exec @myError = RemoveSelectedJobs @infoOnly, @message output, @LogDeletions=@LogDeletions

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
GRANT VIEW DEFINITION ON [dbo].[RemoveOldJobs] TO [Limited_Table_Write] AS [dbo]
GO
