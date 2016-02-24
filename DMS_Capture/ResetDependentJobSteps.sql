/****** Object:  StoredProcedure [dbo].[ResetDependentJobSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ResetDependentJobSteps
/****************************************************
**
**	Desc:	Resets entries in T_Job_Steps and T_Job_Step_Dependencies for the given jobs
**			for which the job steps that are complete yet depend a job step that is enabled, 
**			in progress, or completed after the given job step finished
**
**	Auth:	mem
**			05/19/2011 mem - Initial version
**			05/23/2011 mem - Now checking for target steps having state 0 or 1 in addition to 2 or 4
**			03/12/2012 mem - Now updating Tool_Version_ID when resetting job steps
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**			11/18/2014 mem - Add a table alias for T_Job_Step_Dependencies
**			04/24/2015 mem - Now updating State in T_Jobs
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

	declare @JobResetTran varchar(24) = 'DependentJobStepReset'
	
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
		-- Find steps for the given jobs that need to be reset
		-----------------------------------------------------------
		--
		INSERT INTO #Tmp_JobStepsToReset( Job, Step )
		SELECT DISTINCT JS.Job,
		                JS.Step_Number
		FROM T_Job_Steps JS
		     INNER JOIN T_Job_Step_Dependencies JSD
		       ON JS.Job = JSD.Job AND
		          JS.Step_Number = JSD.Step_Number
		     INNER JOIN T_Job_Steps JS_Target
		       ON JSD.Job = JS_Target.Job AND
		          JSD.Target_Step_Number = JS_Target.Step_Number
		WHERE JS.State >= 2 AND
		      JS.State <> 3 AND
		      JS.Job IN ( SELECT Job
		                  FROM #Tmp_Jobs ) AND
		      (JS_Target.State IN (0, 1, 2, 4) OR
		       JS_Target.Start > JS.Finish)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @InfoOnly <> 0
			SELECT JS.*
			FROM V_Job_Steps JS
			     INNER JOIN #Tmp_JobStepsToReset JR
			       ON JS.Job = JR.Job AND
			          JS.Step = JR.Step
			ORDER BY JS.Job, JS.Step
		Else
		Begin
			Begin Tran @JobResetTran

			-- Reset evaluated to 0 for the affected steps
			--
			UPDATE T_Job_Step_Dependencies
			SET Evaluated = 0, Triggered = 0
			FROM T_Job_Step_Dependencies JSD
				INNER JOIN #Tmp_JobStepsToReset JR
				ON JSD.Job = JR.Job AND
					JSD.Step_Number = JR.Step
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		
			-- Update the Job Steps to state Waiting			
			--
			UPDATE T_Job_Steps
			SET State = 1,					-- 1=waiting
				Tool_Version_ID = 1			-- 1=Unknown
			FROM T_Job_Steps JS
			     INNER JOIN #Tmp_JobStepsToReset JR
			       ON JS.Job = JR.Job AND
			          JS.Step_Number = JR.Step
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			-- Update the job state from failed to running
			UPDATE T_Jobs
			SET State = 2
			FROM T_Jobs J
			     INNER JOIN #Tmp_JobStepsToReset JR
			       ON J.Job = JR.Job
			WHERE J.State = 5
			
			Commit Tran @JobResetTran
		End	

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

	return @myError

GO
