/****** Object:  StoredProcedure [dbo].[UpdateContext] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateContext 
/****************************************************
**
**	Desc: 
**    update context under which job steps are assigned 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	Date:	09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/08/2010 grk - Added call to MakeNewArchiveJobsFromDMS
**			05/25/2011 mem - Changed default value for @bypassDMS to 0
**						   - Added call to RetryCaptureForDMSResetJobs
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,				-- 0->normal mode; will lookup the bypass mode in T_Process_Step_Control; 1->test mode - state of DMS is not affected
	@infoOnly tinyint = 0,
	@MaxJobsToProcess int = 0,
	@LogIntervalThreshold int = 15,		-- If this procedure runs longer than this threshold, then status messages will be posted to the log
	@LoggingEnabled tinyint = 0,		-- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @LogIntervalThreshold seconds elapse
	@LoopingUpdateInterval int = 5,		-- Seconds between detailed logging while looping sets of jobs or steps to process
	@DebugMode tinyint = 0
)
AS
	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @StatusMessage varchar(512)	
	declare @message varchar(512)
	set @message = ''

	declare @StartTime datetime
	Set @StartTime = GetDate()

	declare @result int
	declare @Action varchar(24)
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	-- Part A: Validate inputs, Remove Deleted Jobs, Add New Jobs
	Begin Try
	
		---------------------------------------------------
		-- Validate the inputs
		---------------------------------------------------
		--
		Set @bypassDMS = IsNull(@bypassDMS, 0)
		Set @infoOnly = IsNull(@infoOnly, 0)
		Set @DebugMode = IsNull(@DebugMode, 0)
		Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

		Set @LoggingEnabled = IsNull(@LoggingEnabled, 0)
		Set @LogIntervalThreshold = IsNull(@LogIntervalThreshold, 15)
		Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
		
		If @LogIntervalThreshold = 0
			Set @LoggingEnabled = 1

		-- Lookup the log level in T_Process_Step_Control
		Set @result = 0
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'LogLevel')

		-- Set @LoggingEnabled if the LogLevel is 2 or higher
		If IsNull(@result, 0) >= 2
			Set @LoggingEnabled = 1

		-- See if DMS Updating is disabled in T_Process_Step_Control
		If @bypassDMS = 0
		Begin
			Set @result = 1
			SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'UpdateDMS')
			
			If IsNull(@result, 1) = 0
				Set @bypassDMS = 1
		End
		
		---------------------------------------------------
		-- Call the various procedures for performing updates
		---------------------------------------------------
		--

		-- MakeNewAutomaticJobs
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'MakeNewAutomaticJobs')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'
		
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' MakeNewAutomaticJobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call MakeNewAutomaticJobs'
		if @result <> 0
			exec MakeNewAutomaticJobs @bypassDMS, @message output, @MaxJobsToProcess = @MaxJobsToProcess


		-- MakeNewJobsFromAnalysisBroker
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'MakeNewJobsFromAnalysisBroker')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'
		
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' MakeNewJobsFromAnalysisBroker'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call MakeNewJobsFromAnalysisBroker'
		if @result <> 0
			exec MakeNewJobsFromAnalysisBroker @infoOnly, @message output, @LoggingEnabled = @LoggingEnabled
			
			
		-- MakeNewJobsFromDMS
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'MakeNewJobsFromDMS')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' MakeNewJobsFromDMS'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call MakeNewJobsFromDMS'
		if @result <> 0
			exec MakeNewJobsFromDMS @bypassDMS, 
			                        @message output, 
			                        @MaxJobsToProcess = @MaxJobsToProcess, 
			                        @LogIntervalThreshold=@LogIntervalThreshold, 
			                        @LoggingEnabled=@LoggingEnabled, 
			                        @LoopingUpdateInterval=@LoopingUpdateInterval, 
			                        @infoOnly=@infoOnly,
			                        @DebugMode=@DebugMode

		-- MakeNewArchiveJobsFromDMS
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'MakeNewArchiveJobsFromDMS')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' MakeNewArchiveJobsFromDMS'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call MakeNewArchiveJobsFromDMS'
		if @result <> 0
			exec MakeNewArchiveJobsFromDMS @bypassDMS, 
			                               @message output, 
			                               @MaxJobsToProcess = @MaxJobsToProcess, 
			                               @LogIntervalThreshold=@LogIntervalThreshold, 
			                               @LoggingEnabled=@LoggingEnabled, 
			                               @LoopingUpdateInterval=@LoopingUpdateInterval, 
			                               @infoOnly=@infoOnly,
			                               @DebugMode=@DebugMode


	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch


	-- Part C: Create Job Steps
	Begin Try
	
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'CreateJobSteps')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' CreateJobSteps'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call CreateJobSteps'
		if @result <> 0
			exec CreateJobSteps @message output, 
			                    @MaxJobsToProcess = @MaxJobsToProcess, 
			                    @LogIntervalThreshold=@LogIntervalThreshold, 
			                    @LoggingEnabled=@LoggingEnabled, 
			                    @LoopingUpdateInterval=@LoopingUpdateInterval,
			                    @infoOnly=@infoOnly,
			   @DebugMode=@DebugMode

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch
	
	-- Part D: Update Step States
	Begin Try

		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'UpdateStepStates')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'
			
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' UpdateStepStates'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call UpdateStepStates'
		if @result <> 0
			exec UpdateStepStates @message output, @infoOnly=@infoOnly, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch
	
	-- Part E: Update Job States
	Begin Try

		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'UpdateJobState')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'
			
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' UpdateJobState'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call UpdateJobState'
		if @result <> 0
			exec UpdateJobState @bypassDMS, @message output, @MaxJobsToProcess = @MaxJobsToProcess, @LoopingUpdateInterval=@LoopingUpdateInterval, @infoOnly=@infoOnly
	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch

	-- Part F: Retry capture for datasets that failed capture but for which the dataset state in DMS is 1=New
	Begin Try

		if @bypassDMS = 0
		Begin
			Set @result = 1
			set @Action = 'Calling'
		End
		else
		Begin
			Set @result = 0
			set @Action = 'Skipping'
		End
			
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' RetryCaptureForDMSResetJobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call RetryCaptureForDMSResetJobs'
		if @result <> 0
			exec RetryCaptureForDMSResetJobs @message output
	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch

/*	
	-- Part G: Update CPU Loading
	Begin Try		

		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'UpdateCPULoading')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'
	
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' UpdateCPULoading'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call UpdateCPULoading'
		if @result <> 0
			exec UpdateCPULoading @message output

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch
*/
	If @LoggingEnabled = 1
	Begin
		Set @StatusMessage = 'UpdateContext complete: ' + Convert(varchar(12), DateDiff(second, @StartTime, GetDate())) + ' seconds elapsed'
		exec PostLogEntry 'Normal', @StatusMessage, 'UpdateContext'
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateContext] TO [DDL_Viewer] AS [dbo]
GO
