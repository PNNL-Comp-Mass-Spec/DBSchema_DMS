/****** Object:  StoredProcedure [dbo].[RetryMyEMSLUpload] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RetryMyEMSLUpload
/****************************************************
**
**	Desc:	Resets the DatasetArchive and ArchiveUpdate steps in T_Job_Steps for the 
**			specified jobs, but only if the ArchiveVerify step is failed
**
**			Useful for jobs with Completion message error submitting ingest job
**
**	Auth:	mem
**	Date:	11/17/2014 mem - Initial version
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@Jobs varchar(Max),									-- List of jobs whose steps should be reset
	@InfoOnly tinyint = 0,								-- 1 to preview the changes
	@message varchar(512) = '' output
)
As

	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @JobResetTran varchar(24) = 'ResetArchiveOperation'
	
	BEGIN TRY 
	
		-----------------------------------------------------------
		-- Validate the inputs
		-----------------------------------------------------------
		--
		Set @Jobs = IsNull(@Jobs, '')
		Set @InfoOnly = IsNull(@InfoOnly, 0)
		Set @message = ''
		
		If @Jobs = ''
		Begin
			set @message = 'Job number not supplied'
			print @message
			RAISERROR (@message, 11, 17)
		End

		-----------------------------------------------------------
		-- Create the temporary tables
		-----------------------------------------------------------
		--

		CREATE TABLE #Tmp_Jobs (
			Job int
		)
		
		CREATE TABLE #Tmp_JobsToSkip (
			Job int
		)

		CREATE TABLE #Tmp_JobsToReset (
			Job int
		)

		CREATE TABLE #Tmp_JobStepsToReset (
			Job int,
			Step int
		)

		-----------------------------------------------------------
		-- Parse the job list
		-----------------------------------------------------------

		INSERT INTO #Tmp_Jobs (Job)
		SELECT Value
		FROM dbo.udfParseDelimitedIntegerList(@Jobs, ',')
		ORDER BY Value
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		-----------------------------------------------------------
		-- Look for jobs that have a failed ArchiveVerify step
		-----------------------------------------------------------
		--		
		INSERT INTO #Tmp_JobsToReset( Job )
		SELECT JS.Job
		FROM V_Job_Steps JS
		     INNER JOIN #Tmp_Jobs JL
		       ON JS.Job = JL.Job
		WHERE Tool = 'ArchiveVerify' AND
		      State = 6
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		-----------------------------------------------------------
		-- Look for jobs that do not have a failed ArchiveVerify step
		-----------------------------------------------------------
		--
		INSERT INTO #Tmp_JobsToSkip( Job )
		SELECT JL.Job
		FROM #Tmp_Jobs JL
		     LEFT OUTER JOIN #Tmp_JobsToReset JR
		       ON JL.Job = JR.Job
		WHERE JR.Job IS NULL
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If Not Exists (Select * From #Tmp_JobsToReset)
		Begin
			set @message = 'None of the job(s) has a failed ArchiveVerify step'
			print @message
			RAISERROR (@message, 11, 17)
			Goto Done
		End
		
		Declare @SkipCount int = 0

		SELECT @SkipCount = COUNT(*)
		FROM #Tmp_JobsToSkip
		
		If IsNull(@SkipCount, 0) > 0
		Begin
			set @message = 'Skipping ' + Cast(@SkipCount as varchar(6)) + ' job(s) that do not have a failed ArchiveVerify step'
			Print @message
			Select @message as Warning
		End
						
		-- Construct a comma-separated list of jobs
		--
		Declare @JobList varchar(max) = null
		
		SELECT @JobList = Coalesce(@JobList + ',' + Cast(Job as varchar(9)), Cast(Job as varchar(9)))
		FROM #Tmp_JobsToReset
		ORDER BY Job

		-----------------------------------------------------------
		-- Reset the ArchiveUpdate or DatasetArchive step
		-----------------------------------------------------------
		--
		
		If @InfoOnly <> 0
		Begin
			SELECT JS.Job,
			       JS.Step,
			       JS.Tool,
			       'Step would be reset' AS Message,
			       JS.State,
			       JS.Start,
			       JS.Finish
			FROM V_Job_Steps JS
			     INNER JOIN #Tmp_JobsToReset JR
			       ON JS.Job = JR.Job
			WHERE Tool IN ('ArchiveUpdate', 'DatasetArchive')
			
			Declare @execMsg varchar(256) = 'exec ResetDependentJobSteps ' + @JobList
			print @execMsg
			
		End
		Else
		Begin

			Begin Tran @JobResetTran

			-- Reset the archive step
			--
			UPDATE V_Job_Steps
			Set State = 2
			FROM V_Job_Steps JS INNER JOIN #Tmp_JobsToReset JR
		       ON JS.Job = JR.Job
			WHERE Tool IN ('ArchiveUpdate', 'DatasetArchive')
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			-- Reset the state of the dependent steps
			--
			exec ResetDependentJobSteps @JobList, @InfoOnly=0

			-- Reset the retry counts for the ArchiveVerify step
			--
			UPDATE V_Job_Steps
			SET Retry_Count = 75,
			    Next_Try = DateAdd(hour, 1, GetDate())
			FROM V_Job_Steps JS
			     INNER JOIN #Tmp_JobsToReset JR
			       ON JS.Job = JR.Job
			WHERE Tool = 'ArchiveVerify'
			
			Commit Tran @JobResetTran
						
		End	
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RetryMyEMSLUpload] TO [DDL_Viewer] AS [dbo]
GO
