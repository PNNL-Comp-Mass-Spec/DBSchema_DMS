/****** Object:  StoredProcedure [dbo].[RemoveJobFromMainTables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.RemoveJobFromMainTables
/****************************************************
**
**	Desc:
**  Delete specified job
**  from the main tables in the database
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			11/19/2010 mem - Initial version
**
*****************************************************/
(
	@Job int,							-- Job to remove
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
	
	If @Job Is Null
	Begin
		Set @message = 'Job not defined; nothing to do'
		Goto Done
	End
		
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''

			
	---------------------------------------------------
 	-- Insert specified job to #SJL
 	---------------------------------------------------
	--	

	INSERT INTO #SJL
	SELECT Job, State
	FROM T_Jobs
	WHERE Job = @Job
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
		

	---------------------------------------------------
	-- do actual deletion
 	---------------------------------------------------

	declare @transName varchar(64)
	set @transName = 'RemoveOldJobs'
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
GRANT VIEW DEFINITION ON [dbo].[RemoveJobFromMainTables] TO [Limited_Table_Write] AS [dbo]
GO
