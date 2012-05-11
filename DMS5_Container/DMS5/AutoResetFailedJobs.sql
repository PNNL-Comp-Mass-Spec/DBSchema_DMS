/****** Object:  StoredProcedure [dbo].[AutoResetFailedJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AutoResetFailedJobs
/****************************************************
**
**	Desc:	Looks for recently failed jobs
**			Examines the reason for the failure and will auto-reset under certain conditions

**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	09/30/2010 mem - Initial Version
**			10/01/2010 mem - Added call to PostLogEntry when changing ManagerErrorCleanupMode for a processor
**			02/16/2012 mem - Fixed major bug that reset the state for all steps of a job to state 2, rather than only resetting the state for the running step
**						   - Fixed bug finding jobs that are running, but started over 60 minutes ago and for which the processor is reporting Stopped_Error in T_Processor_Status
**
*****************************************************/
(
	@WindowHours int = 12,				-- Will look for jobs that failed within @WindowHours hours of the present time
    @infoOnly tinyint = 1,
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @Job int
	declare @StepNumber int
	declare @StepTool varchar(64)
	declare @JobState int
	declare @StepState int
	declare @Processor varchar(128)
	declare @Comment varchar(750)
	
	Declare @NewJobState int
	declare @NewComment varchar(750)
	
	declare @continue tinyint

	declare @RetryJob tinyint
	declare @SetProcessorAutoRecover tinyint
	
	declare @RetryCount int
	Declare @MatchIndex int
	Declare @MatchIndexLast int
	Declare @PoundIndex int
	
	Declare @RetryText varchar(512)
	Declare @RetryCountText varchar(32)	
	
	Declare @ResetReason varchar(64)
	Declare @LogMessage varchar(512)
	
	BEGIN TRY 
	
		---------------------------------------------------
		-- Validate the inputs
		---------------------------------------------------
		-- 
		
		Set @WindowHours = IsNull(@WindowHours, 12)
		If @WindowHours < 2
			Set @WindowHours = 2
			
		Set @infoOnly = IsNull(@infoOnly, 0)
		set @message = ''

		CREATE TABLE #Tmp_FailedJobs (
			Job int NOT NULL,
			Step_Number int NOT NULL,
			Step_Tool varchar(64) NOT NULL,
			Job_State int NOT NULL,
			Step_State int NOT NULL,
			Processor varchar(128) NOT NULL,
			Comment varchar(750) NOT null,
			Job_Finish datetime Null,
			NewJobState int null,
			NewStepState int null,
			NewComment varchar(750) null,
			ResetJob tinyint not null default 0		
		)

		---------------------------------------------------
		-- Populate a temporary table with jobs that failed within the last @WindowHours hours
		---------------------------------------------------
		--
		INSERT INTO #Tmp_FailedJobs (Job, Step_Number, Step_Tool, Job_State, Step_State, Processor, Comment, Job_Finish)
		SELECT J.AJ_jobID AS Job,
		       JS.Step_Number,
		       JS.Step_Tool,
		       J.AJ_StateID AS Job_State,
		       JS.State AS Step_State,
		       IsNull(JS.Processor, '') AS Processor,
		       IsNull(J.AJ_comment, '') AS Comment,
		       J.AJ_finish as Job_Finish
		FROM T_Analysis_Job J
		     INNER JOIN DMS_Pipeline.dbo.T_Job_Steps JS
		       ON J.AJ_jobID = JS.Job
		WHERE J.AJ_StateID = 5 AND
		      J.AJ_finish >= DATEADD(hour, -@WindowHours, GETDATE()) AND
		      JS.State = 6
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		---------------------------------------------------
		-- Next look for job steps that are running, but started over 60 minutes ago and for which
		-- the processor is reporting Stopped_Error in T_Processor_Status
		---------------------------------------------------
		--
		INSERT INTO #Tmp_FailedJobs (Job, Step_Number, Step_Tool, Job_State, Step_State, Processor, Comment, Job_Finish)
		SELECT J.AJ_jobID AS Job,
		       JS.Step_Number,
		       JS.Step_Tool,
		       J.AJ_StateID AS Job_State,
		       JS.State AS Step_State,
		       IsNull(JS.Processor, '') AS Processor,
		       IsNull(J.AJ_comment, '') AS Comment,
		       J.AJ_finish as Job_Finish
		FROM T_Analysis_Job J
		     INNER JOIN DMS_Pipeline.dbo.T_Job_Steps JS
		       ON J.AJ_jobID = JS.Job
		     INNER JOIN DMS_Pipeline.dbo.T_Processor_Status ProcStatus
		       ON JS.Processor = ProcStatus.Processor_Name
		WHERE (J.AJ_StateID = 2) AND
		      (JS.State = 4) AND
		      (ProcStatus.Mgr_Status = 'Stopped Error') AND
		      (JS.Start <= DATEADD(HOUR, - 1, GETDATE())) AND
		      (DATEDIFF(MINUTE, ProcStatus.Status_Date, GETDATE()) < 30)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		IF EXISTS (SELECT * FROM #Tmp_FailedJobs)
		Begin -- <a>
			-- Step through the jobs and reset them if appropriate

			Set @Job = 0
			Set @continue = 1
			
			While @continue = 1
			Begin -- <b>
				
				SELECT TOP 1 @Job = Job, 
				             @StepNumber = Step_Number, 
				             @StepTool = Step_Tool, 
				             @JobState = Job_State, 
				             @StepState = Step_State, 
				             @Processor = Processor,
				             @Comment = Comment
				FROM #Tmp_FailedJobs
				WHERE Job > @Job
				ORDER BY Job
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myRowCount = 0
					Set @continue = 0
				Else
				Begin -- <c>

					Set @RetryJob = 0
					Set @RetryCount = 0
					Set @SetProcessorAutoRecover = 0
					
					-- Examine the comment to determine if we've retried this job before
					-- Need to find the last instance of '(retry'
					
					Set @MatchIndexLast = 0
					Set @MatchIndex = 999
					While @MatchIndex > 0
					Begin
						Set @MatchIndex = CharIndex('(retry', @Comment, @MatchIndexLast+1)
						If @MatchIndex > 0
							Set @MatchIndexLast = @MatchIndex
					End
					Set @MatchIndex = @MatchIndexLast

					If @MatchIndex = 0
					Begin
						-- Comment does not contain '(retry'
						Set @NewComment = @Comment
						
						If @NewComment LIKE '%;%'
						Begin
							-- Comment contains a semicolon
							-- Remove the text after the semicolon
							Set @MatchIndex = CharIndex(';', @NewComment)
							If @MatchIndex > 1
								Set @NewComment = SubString(@NewComment, 1, @MatchIndex-1)
							Else							
								Set @NewComment = ''
						End								
					End
					Else
					Begin
						-- Comment contains '(retry'
						
						If @MatchIndex > 1
							Set @NewComment = SubString(@Comment, 1, @MatchIndex-1)
						Else
							Set @NewComment = ''

						-- Determine the number of times the job has been retried
						Set @RetryCount = 1
						Set @RetryText = SubString(@Comment, @MatchIndex, Len(@Comment))
						
						-- Find the closing parenthesis
						Set @MatchIndex = CharIndex(')', @RetryText)
						If @MatchIndex > 0
						Begin
							Set @PoundIndex = CharIndex('#', @RetryText)
							
							If @PoundIndex > 0
							Begin
								If @MatchIndex - @PoundIndex - 1 > 0
								Begin
									Set @RetryCountText = SubString(@RetryText, @PoundIndex+1, @MatchIndex - @PoundIndex - 1)

									If IsNumeric(@RetryCountText) <> 0
										Set @RetryCount = Convert(int, @RetryCountText)
								End									
							End							
						End
					End
					

					If @StepState = 6
					Begin
						-- Job step is failed and overall job is failed
						
						If @StepTool = 'Decon2LS' And @RetryCount < 2
							Set @RetryJob = 1
							
						If @StepTool In ('DataExtractor', 'MSGF') And @RetryCount < 5
							Set @RetryJob = 1
						
					End
					
					If @StepState = 4
					Begin
						-- Job is still running, but processor has an error (likely a flagfile)
						-- This likely indicates an out-of-memory error
						
						If @StepTool In ('DataExtractor', 'MSGF') And @RetryCount < 5
							Set @RetryJob = 1
						
						If @RetryJob = 1
							Set @SetProcessorAutoRecover = 1
					End
					
					If @RetryJob = 1
					Begin
						Set @NewComment = RTrim(@NewComment)
						
						If Len(@NewComment) > 0
							Set @NewComment = @NewComment + ' '
						
						Set @NewComment = @NewComment + '(retry ' + @StepTool
						
						Set @RetryCount = @RetryCount + 1
						if @RetryCount = 1
							Set @NewComment = @NewComment + ')'
						Else
							Set @NewComment = @NewComment + ' #' + Convert(varchar(2), @RetryCount) + ')'
						
						If @StepState = 6
						Begin
							Set @NewJobState = 1
							
							UPDATE #Tmp_FailedJobs
							SET NewJobState = @NewJobState,
								NewStepState = @StepState,
							    NewComment = @NewComment,
							    ResetJob = 1
							WHERE Job = @Job
							
							Set @ResetReason = 'job step failed in the last ' + convert(varchar(12), @WindowHours) + ' hours'
						End
						
						If @StepState = 4
						Begin
							Set @NewJobState = @JobState
							
							UPDATE #Tmp_FailedJobs
							SET NewJobState = @NewJobState,
								NewStepState = 2,
							    NewComment = @NewComment,
							   ResetJob = 1
							WHERE Job = @Job
							    
							If @infoOnly = 0
							Begin
								-- Reset the step back to state 2=Enabled
								UPDATE DMS_Pipeline.dbo.T_Job_Steps
								SET State = 2
								WHERE Job = @Job And Step_Number = @StepNumber							
							End
							
							Set @ResetReason = 'job step in progress but manager reports "Stopped Error"'
						End
						
						If @infoOnly = 0
						Begin
							-- Update the JobState and Comment in T_Analysis_Job
							UPDATE T_Analysis_Job
							SET AJ_StateID = @NewJobState,
								AJ_Comment = @NewComment
							WHERE AJ_JobID = @Job
							
							Set @LogMessage = 'Auto-reset job ' + Convert(varchar(12), @job) + '; ' + @ResetReason + '; ' + @NewComment
							
							Exec PostLogEntry 'Warning', @LogMessage, 'AutoResetFailedJobs'
						End

						If @SetProcessorAutoRecover = 1
						Begin
							If @infoOnly = 0
							Begin
								Set @LogMessage = @Processor + ' reports "Stopped Error"; setting ManagerErrorCleanupMode to 1 in the Manager_Control DB'
								Exec PostLogEntry 'Warning', @LogMessage, 'AutoResetFailedJobs'

								Exec ProteinSeqs.Manager_Control.dbo.SetManagerErrorCleanupMode @ManagerList = @Processor, @CleanupMode = 1				
							End
							Else
								print 'Exec ProteinSeqs.Manager_Control.dbo.SetManagerErrorCleanupMode @ManagerList = @Processor, @CleanupMode = 1'
						End

					End				
				End -- </c>
				
				
			End -- </b>
		
		
			If @infoOnly <> 0
				SELECT *
				FROM #Tmp_FailedJobs
				ORDER BY Job
			
			
		End -- </a>

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AutoResetFailedJobs] TO [Limited_Table_Write] AS [dbo]
GO
