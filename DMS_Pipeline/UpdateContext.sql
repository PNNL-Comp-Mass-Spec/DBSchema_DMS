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
**			05/30/2008 -- initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			01/09/2009 mem - Added parameter @infoOnly (http://prismtrac.pnl.gov/trac/ticket/713)
**			01/17/2009 mem - Now calling SyncJobInfo (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**			02/19/2009 grk - added call to RemoveDMSDeletedJobs (Ticket #723)
**			06/02/2009 mem - Added parameter @MaxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**			06/03/2009 mem - Added parameters @LogIntervalThreshold, @LoggingEnabled, and @LoopingUpdateInterval
**			06/04/2009 mem - Added Try/Catch error handling
**						   - Now using T_Process_Step_Control to determine whether or not to Update states in DMS
**			06/05/2009 mem - Added expanded support for T_Process_Step_Control
**			03/21/2011 mem - Added parameter @DebugMode; now passing @infoOnly to AddNewJobs
**			01/12/2012 mem - Now passing @infoOnly to UpdateJobState
**			05/02/2015 mem - Now calling AutoFixFailedJobs
**			05/28/2015 mem - No longer calling ImportJobProcessors
**			11/20/2015 mem - Now calling UpdateActualCPULoading
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,				-- 0->normal mode; will lookup the bypass mode in T_Process_Step_Control; 1->test mode - state of DMS is not affected
	@MaxJobsToProcess int = 0,
	@LogIntervalThreshold int = 15,		-- If this procedure runs longer than this threshold, then status messages will be posted to the log
	@LoggingEnabled tinyint = 0,		-- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @LogIntervalThreshold seconds elapse
	@LoopingUpdateInterval int = 5,		-- Seconds between detailed logging while looping sets of jobs or steps to process
	@infoOnly tinyint = 0,				-- 1 to preview changes that would be made; 2 to add new jobs but do not create job steps
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
	
	-- Part A: Validate inputs, Remove Deleted Jobs, Add New Jobs, Hold/Resume/Reset jobs
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
		
		-- Step 1: Remove jobs deleted from DMS
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'RemoveDMSDeletedJobs')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'
		
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' RemoveDMSDeletedJobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call RemoveDMSDeletedJobs'
		if @result <> 0
			exec RemoveDMSDeletedJobs @bypassDMS, @message output, @MaxJobsToProcess = @MaxJobsToProcess


		-- Step 2: Add new jobs, hold/resume/reset existing jobs
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'AddNewJobs')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' AddNewJobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call AddNewJobs'
		if @result <> 0
			exec AddNewJobs @bypassDMS, 
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
	
	-- Part B: Import Processors, Import Job Processors, Sync Job Info
	Begin Try

		-- Step 3
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'ImportProcessors')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' ImportProcessors'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call ImportProcessors'
		if @result <> 0
			exec ImportProcessors @bypassDMS, @message output


		/*
		---------------------------------------------------
		-- Deprecated in May 2015: 
		-- Step 4
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'ImportJobProcessors')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' ImportJobProcessors'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call ImportJobProcessors'
		if @result <> 0
			exec ImportJobProcessors @bypassDMS, @message output
		*/

		-- Step 5
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'SyncJobInfo')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'

		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' SyncJobInfo'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call SyncJobInfo'
		if @result <> 0
			exec SyncJobInfo @bypassDMS, @message output

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output		
	End Catch
	
	-- Part C: Create Job Steps
	Begin Try
	
		-- Step 6
		--
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

		-- Step 6
		--
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
			exec UpdateStepStates @message output, 
			                      @infoOnly=@infoOnly, 
			                      @MaxJobsToProcess = @MaxJobsToProcess, 
			                      @LoopingUpdateInterval=@LoopingUpdateInterval

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch
	
	-- Part E: Update Job States
	Begin Try

		-- Step 7
		--
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
			exec UpdateJobState @bypassDMS, 
			                    @message output,
			                    @MaxJobsToProcess = @MaxJobsToProcess, 
			                    @LoopingUpdateInterval= @LoopingUpdateInterval,
			                    @infoOnly = @infoOnly

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch
	
	-- Part F: Update CPU Loading and Memory Usage
	Begin Try		

		-- Step 8
		--
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
		If @result <> 0
		Begin
			-- First update Actual_CPU_Load in T_Job_Steps
			exec UpdateActualCPULoading @infoOnly = 0
			
			-- Now update CPUs_Available in T_Machines
			exec UpdateCPULoading @message output
		End

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch

	-- Part G: AutoFixFailedJobs
	Begin Try		

		-- Step 9
		--
		Set @result = 1
		SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'AutoFixFailedJobs')
		If @result = 0
			set @Action = 'Skipping'
		Else
			set @Action = 'Calling'
	
		If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
		Begin
			Set @LoggingEnabled = 1
			Set @StatusMessage = @Action + ' AutoFixFailedJobs'
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
		End
		
		Set @CurrentLocation = 'Call AutoFixFailedJobs'
		if @result <> 0
			exec AutoFixFailedJobs @message = @message output, @infoonly = @infoOnly

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateContext')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
	End Catch


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
GRANT VIEW DEFINITION ON [dbo].[UpdateContext] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateContext] TO [PNL\D3M578] AS [dbo]
GO
