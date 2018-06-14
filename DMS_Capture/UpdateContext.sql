/****** Object:  StoredProcedure [dbo].[UpdateContext] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateContext] 
/****************************************************
**
**  Desc:   Update context under which job steps are assigned 
**    
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/08/2010 grk - Added call to MakeNewArchiveJobsFromDMS
**          05/25/2011 mem - Changed default value for @bypassDMS to 0
**                         - Added call to RetryCaptureForDMSResetJobs
**          02/23/2016 mem - Add Set XACT_ABORT on
**          06/13/2018 mem - No longer pass @debugMode to MakeNewArchiveJobsFromDMS
**    
*****************************************************/
(
    @bypassDMS tinyint = 0,             -- 0->normal mode; will lookup the bypass mode in T_Process_Step_Control; 1->test mode - state of DMS is not affected
    @infoOnly tinyint = 0,
    @maxJobsToProcess int = 0,
    @logIntervalThreshold int = 15,     -- If this procedure runs longer than this threshold, then status messages will be posted to the log
    @loggingEnabled tinyint = 0,        -- Set to 1 to immediately enable progress logging; if 0, then logging will auto-enable if @logIntervalThreshold seconds elapse
    @loopingUpdateInterval int = 5,     -- Seconds between detailed logging while looping sets of jobs or steps to process
    @debugMode tinyint = 0
)
AS
    Set XACT_ABORT, nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @StatusMessage varchar(512)    
    Declare @message varchar(512) = ''

    Declare @StartTime datetime = GetDate()

    Declare @result int
    Declare @Action varchar(24)
    
    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128) = 'Start'
    
    -- Part A: Validate inputs, Remove Deleted Jobs, Add New Jobs
    Begin Try
    
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------
        --
        Set @bypassDMS = IsNull(@bypassDMS, 0)
        Set @infoOnly = IsNull(@infoOnly, 0)
        Set @debugMode = IsNull(@debugMode, 0)
        Set @maxJobsToProcess = IsNull(@maxJobsToProcess, 0)

        Set @loggingEnabled = IsNull(@loggingEnabled, 0)
        Set @logIntervalThreshold = IsNull(@logIntervalThreshold, 15)
        Set @loopingUpdateInterval = IsNull(@loopingUpdateInterval, 5)
        
        If @logIntervalThreshold = 0
            Set @loggingEnabled = 1

        -- Lookup the log level in T_Process_Step_Control
        Set @result = 0
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'LogLevel')

        -- Set @loggingEnabled if the LogLevel is 2 or higher
        If IsNull(@result, 0) >= 2
            Set @loggingEnabled = 1

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
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'
        
        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' MakeNewAutomaticJobs'
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
        End
        
        Set @CurrentLocation = 'Call MakeNewAutomaticJobs'
        if @result <> 0
            exec MakeNewAutomaticJobs @bypassDMS, @message output, @maxJobsToProcess = @maxJobsToProcess


        -- MakeNewJobsFromAnalysisBroker
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'MakeNewJobsFromAnalysisBroker')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'
        
        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' MakeNewJobsFromAnalysisBroker'
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
        End
        
        Set @CurrentLocation = 'Call MakeNewJobsFromAnalysisBroker'
        if @result <> 0
            exec MakeNewJobsFromAnalysisBroker @infoOnly, @message output, @loggingEnabled = @loggingEnabled
            
            
        -- MakeNewJobsFromDMS
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'MakeNewJobsFromDMS')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' MakeNewJobsFromDMS'
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
        End
        
        Set @CurrentLocation = 'Call MakeNewJobsFromDMS'
        if @result <> 0
            exec MakeNewJobsFromDMS @bypassDMS, 
                                    @message output, 
                                    @maxJobsToProcess = @maxJobsToProcess, 
                                    @logIntervalThreshold = @logIntervalThreshold, 
                                    @loggingEnabled = @loggingEnabled, 
                                    @loopingUpdateInterval = @loopingUpdateInterval, 
                                    @infoOnly = @infoOnly,
                                    @debugMode = @debugMode

        -- MakeNewArchiveJobsFromDMS
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'MakeNewArchiveJobsFromDMS')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' MakeNewArchiveJobsFromDMS'
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
        End
        
        Set @CurrentLocation = 'Call MakeNewArchiveJobsFromDMS'
        if @result <> 0
            exec MakeNewArchiveJobsFromDMS @bypassDMS, 
                                           @message output, 
                                           @maxJobsToProcess = @maxJobsToProcess, 
                                           @logIntervalThreshold = @logIntervalThreshold, 
                                           @loggingEnabled = @loggingEnabled, 
                                           @loopingUpdateInterval = @loopingUpdateInterval, 
                                           @infoOnly = @infoOnly

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
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' CreateJobSteps'
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
        End
        
        Set @CurrentLocation = 'Call CreateJobSteps'
        if @result <> 0
            exec CreateJobSteps @message output, 
                                @maxJobsToProcess = @maxJobsToProcess, 
                                @logIntervalThreshold = @logIntervalThreshold, 
                                @loggingEnabled = @loggingEnabled, 
                                @loopingUpdateInterval = @loopingUpdateInterval,
                                @infoOnly = @infoOnly,
                                @debugMode = @debugMode

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
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'
            
        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' UpdateStepStates'
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
        End
        
        Set @CurrentLocation = 'Call UpdateStepStates'
        if @result <> 0
            exec UpdateStepStates @message output, @infoOnly=@infoOnly, @maxJobsToProcess = @maxJobsToProcess, @loopingUpdateInterval=@loopingUpdateInterval

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
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'
            
        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' UpdateJobState'
            exec PostLogEntry 'Progress', @StatusMessage, 'UpdateContext'
        End
        
        Set @CurrentLocation = 'Call UpdateJobState'
        if @result <> 0
            exec UpdateJobState @bypassDMS, @message output, @maxJobsToProcess = @maxJobsToProcess, @loopingUpdateInterval=@loopingUpdateInterval, @infoOnly=@infoOnly
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
            Set @Action = 'Calling'
        End
        else
        Begin
            Set @result = 0
            Set @Action = 'Skipping'
        End
            
        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
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
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'
    
        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
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
    If @loggingEnabled = 1
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
