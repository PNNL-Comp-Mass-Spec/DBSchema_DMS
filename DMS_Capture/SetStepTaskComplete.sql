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
**			01/15/2010 grk - Set step state back to enable if retrying
**			05/05/2011 mem - Now leaving Next_Try unchanged if state = 5 (since @completionCode = 0)
**			02/08/2012 mem - Added support for @evaluationCode = 3 when @completionCode = 0
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
	declare @machine varchar(64) = ''
	declare @retryCount smallint = 0
	declare @HoldoffIntervalMinutes int = 30
	Declare @NextTry datetime = GetDate()
	--
	SELECT	
		@machine = Machine,
		@state = State,
		@processor = Processor,
		@retryCount = Retry_Count,
		@HoldoffIntervalMinutes = Holdoff_Interval_Minutes,
		@NextTry = Next_Try
	FROM T_Job_Steps
	WHERE (Job = @job) AND (Step_Number = @step)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting machine name'
		goto Done
	end
	--
	if @machine = ''
	begin
		set @myError = 66
		set @message = 'Could not find machine name'
		goto Done
	end
	--
	if @state <> 4
	begin
		set @myError = 67
		set @message = 'Job step is not in correct state to be completed'
		goto Done
	end

	---------------------------------------------------
	-- Determine completion state
	---------------------------------------------------
	--
	declare @stepState int = 5

	if @completionCode = 0
		set @stepState = 5 -- success FUTURE: implement evaluation logic
	else
	begin
		If @retryCount > 0 Or @evaluationCode = 3
		begin
			If @state = 4
				Set @stepState = 2

			If @retryCount > 0
				SET @retryCount = @retryCount - 1 -- decrement retry count

			If @evaluationCode = 3
			Begin
				-- The captureTaskManager returns 3 (EVAL_CODE_NETWORK_ERROR_RETRY_CAPTURE) when a network error occurs during capture
				-- Auto-retry the capture again (even if @retryCount = 0)
				Set @NextTry = DATEADD(minute, 15, GETDATE())
			End
			Else
			Begin
				If @stepState <> 5 And @retryCount > 0
					set @NextTry = DATEADD(minute, @HoldoffIntervalMinutes, GETDATE())
			End
				
		end
		else
		begin
			set @stepState = 6 -- fail FUTURE: implement evaluation logic
		end
	end

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'SetStepTaskComplete'
		
	-- Start transaction
	begin transaction @transName

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
		   Next_Try = @NextTry
	WHERE  (Job = @job)
	AND (Step_Number = @step)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating step table'
		goto Done
	end

	-- update was successful
	commit transaction @transName
		
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [svc-dms] AS [dbo]
GO
