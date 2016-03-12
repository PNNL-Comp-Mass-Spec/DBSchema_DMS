/****** Object:  StoredProcedure [dbo].[SetStepTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SetStepTaskComplete
/****************************************************
**
**	Desc: 
**    Make entry in step completion table
**    (SetAnalysisJobComplete)
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			09/30/2009 ??? - Made @message an output parameter
**			01/15/2010 grk - Set step state back to enable If retrying
**			05/05/2011 mem - Now leaving Next_Try unchanged If state = 5 (since @completionCode = 0)
**			02/08/2012 mem - Added support for @evaluationCode = 3 when @completionCode = 0
**			09/10/2013 mem - Added support for @evaluationCode being 4, 5, or 6
**			09/11/2013 mem - Now auto-adjusting the holdoff interval for ArchiveVerify job steps
**			09/18/2013 mem - Added support for @evaluationCode = 7
**			09/19/2013 mem - Now skipping ArchiveStatusCheck when skipping ArchiveVerify
**			10/16/2013 mem - Now updating Evaluation_Message when skipping the ArchiveVerify step
**			09/24/2014 mem - No longer looking up machine
**			11/03/2013 mem - Added support for @evaluationCode = 8
**    
*****************************************************/
(
    @job int,
    @step int,
    @completionCode int,
    @completionMessage varchar(256) = '',
    @evaluationCode int = 0,
    @evaluationMessage varchar(256) = '',
    @message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	---------------------------------------------------
	-- get current state of this job step
	---------------------------------------------------
	--
	declare @processor varchar(64) = ''
	declare @state tinyint = 0
	declare @retryCount smallint = 0
	declare @HoldoffIntervalMinutes int = 30
	declare @NextTry datetime = GetDate()
	declare @stepTool varchar(64)
	declare @outputFolderName varchar(255)
	declare @datasetID int
	--
	SELECT @state = JS.State,
	       @processor = JS.Processor,
	       @retryCount = JS.Retry_Count,
	       @HoldoffIntervalMinutes = JS.Holdoff_Interval_Minutes,
	       @NextTry = JS.Next_Try,
	       @stepTool = JS.Step_Tool,
	       @outputFolderName = JS.Output_Folder_Name,
	       @datasetID = J.Dataset_ID
	FROM T_Job_Steps JS
	     INNER JOIN T_Local_Processors LP
	       ON LP.Processor_Name = JS.Processor	
	     INNER JOIN T_Jobs J
	       ON JS.Job = J.Job
	WHERE (JS.Job = @job) AND
	      (JS.Step_Number = @step) 	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		set @message = 'Error getting state of current job'
		goto Done
	End
	--
	If @state <> 4
	Begin
		set @myError = 67
		set @message = 'Job step is not in correct state to be completed; job ' + convert(varchar(12), @job) + ', step ' + convert(varchar(12), @step) + ', actual state ' + convert(varchar(6), @state) 
		goto Done
	End

	---------------------------------------------------
	-- Determine completion state
	---------------------------------------------------
	--
	declare @stepState int = 5

	If @completionCode = 0
		Set @stepState = 5
	Else
	Begin
	
		If @evaluationCode = 8  -- EVAL_CODE_FAILURE_DO_NOT_RETRY
		Begin
			Set @stepState = 6
			Set @retryCount = 0
		End
		
		If @retryCount > 0 Or @evaluationCode = 3
		Begin
			If @state = 4
				Set @stepState = 2

			If @retryCount > 0
			Begin
				Set @retryCount = @retryCount - 1 -- decrement retry count
			End
			
			If @evaluationCode = 3
			Begin
				-- The captureTaskManager returns 3 (EVAL_CODE_NETWORK_ERROR_RETRY_CAPTURE) when a network error occurs during capture
				-- Auto-retry the capture again (even If @retryCount = 0)
				Set @NextTry = DATEADD(minute, 15, GETDATE())
			End
			Else
			Begin
				If @StepTool = 'ArchiveVerify'
				Begin
					SET @HoldoffIntervalMinutes = CASE
					        WHEN @HoldoffIntervalMinutes < 5 THEN 5
					                                  WHEN @HoldoffIntervalMinutes < 10 THEN 10
					                                  WHEN @HoldoffIntervalMinutes < 15 THEN 15
					                                  WHEN @HoldoffIntervalMinutes < 30 THEN 30
					                                  ELSE @HoldoffIntervalMinutes
					                              END
				End
				
				If @stepState <> 5 And @retryCount > 0
					set @NextTry = DATEADD(minute, @HoldoffIntervalMinutes, GETDATE())
			End
				
		End
		Else
		Begin
			set @stepState = 6 -- fail
		End
	End

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'SetStepTaskComplete'
		
	-- Start transaction
	Begin transaction @transName

	---------------------------------------------------
	-- Update job step
	---------------------------------------------------
	--
	UPDATE T_Job_Steps
	SET    State = @stepState,
		   Finish = Getdate(),
		   Completion_Code = @completionCode,
		   Completion_Message = @completionMessage,
		   Evaluation_Code = @evaluationCode,
		   Evaluation_Message = @evaluationMessage,
		   Retry_Count = @retryCount,
		   Holdoff_Interval_Minutes = @HoldoffIntervalMinutes,
		   Next_Try = @NextTry
	WHERE  (Job = @job)
	AND (Step_Number = @step)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		rollback transaction @transName
		set @message = 'Error updating step table'
		goto Done
	End

	If @stepTool In ('ArchiveUpdate', 'ArchiveUpdateTest', 'DatasetArchive') AND @evaluationCode IN (6, 7)
	Begin
		-- If @evaluationCode = 6 then we copied data to Aurora via FTP but did not upload to MyEMSL
		-- If @evaluationCode = 7 then we uploaded data to MyEMSL, but there were no new files to upload, so there is nothing to verify
		-- In either case, skip the ArchiveVerify and ArchiveStatusCheck steps for this job (if they exist)
		
		UPDATE T_Job_Steps
		SET State = 3,
		    Completion_Code = 0,
		    Completion_Message = '',
		    Evaluation_Code = 0,
		    Evaluation_Message = 
		      CASE
		          WHEN @evaluationCode = 6 THEN 'Skipped since MyEMSL upload was skipped'
		          WHEN @evaluationCode = 7 THEN 'Skipped since MyEMSL files were already up-to-date'
		          ELSE 'Skipped for unknown reason'
		      END
		WHERE Job = @job AND
		      Step_Tool IN ('ArchiveVerify', 'ArchiveStatusCheck') AND
		      NOT State IN (4, 5, 7)

	End

	-- update was successful
	commit transaction @transName
	
	---------------------------------------------------
	-- Possibly update MyEMSL State values
	---------------------------------------------------
	--
	If @completionCode = 0
	Begin
		
		-- @evaluationCode = 4 means Submitted to MyEMSL
		-- @evaluationCode = 5 means Verified in MyEMSL
		
		If @stepTool Like '%Archive%' And @evaluationCode IN (4, 5)
		Begin
			-- Update the MyEMSLState values			
			Declare @MyEMSLStateNew tinyint = 0
			
			If @evaluationCode = 4
				Set @MyEMSLStateNew = 1
				
			If @evaluationCode = 5
				Set @MyEMSLStateNew = 2
			
			exec S_UpdateMyEMSLState @datasetID, @outputFolderName, @MyEMSLStateNew
			
		End
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
