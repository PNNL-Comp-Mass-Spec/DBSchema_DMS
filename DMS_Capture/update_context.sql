/****** Object:  StoredProcedure [dbo].[update_context] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_context]
/****************************************************
**
**  Desc:   Update context under which job steps are assigned
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/08/2010 grk - Added call to make_new_archive_jobs_from_dms
**          05/25/2011 mem - Changed default value for @bypassDMS to 0
**                         - Added call to retry_capture_for_dms_reset_jobs
**          02/23/2016 mem - Add Set XACT_ABORT on
**          06/13/2018 mem - No longer pass @debugMode to make_new_archive_jobs_from_dms
**          01/29/2021 mem - No longer pass @maxJobsToProcess to make_new_automatic_jobs
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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

        -- make_new_automatic_jobs
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'make_new_automatic_jobs')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' make_new_automatic_jobs'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call make_new_automatic_jobs'
        if @result <> 0
            exec make_new_automatic_jobs @bypassDMS, @message output


        -- make_new_jobs_from_analysis_broker
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'make_new_jobs_from_analysis_broker')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' make_new_jobs_from_analysis_broker'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call make_new_jobs_from_analysis_broker'
        if @result <> 0
            exec make_new_jobs_from_analysis_broker @infoOnly, @message output, @loggingEnabled = @loggingEnabled


        -- make_new_jobs_from_dms
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'make_new_jobs_from_dms')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' make_new_jobs_from_dms'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call make_new_jobs_from_dms'
        if @result <> 0
            exec make_new_jobs_from_dms @bypassDMS,
                                    @message output,
                                    @maxJobsToProcess = @maxJobsToProcess,
                                    @logIntervalThreshold = @logIntervalThreshold,
                                    @loggingEnabled = @loggingEnabled,
                                    @loopingUpdateInterval = @loopingUpdateInterval,
                                    @infoOnly = @infoOnly,
                                    @debugMode = @debugMode

        -- make_new_archive_jobs_from_dms
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'make_new_archive_jobs_from_dms')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' make_new_archive_jobs_from_dms'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call make_new_archive_jobs_from_dms'
        if @result <> 0
            exec make_new_archive_jobs_from_dms @bypassDMS,
                                           @message output,
                                           @maxJobsToProcess = @maxJobsToProcess,
                                           @logIntervalThreshold = @logIntervalThreshold,
                                           @loggingEnabled = @loggingEnabled,
                                           @loopingUpdateInterval = @loopingUpdateInterval,
                                           @infoOnly = @infoOnly

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch


    -- Part C: Create Job Steps
    Begin Try

        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'create_job_steps')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' create_job_steps'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call create_job_steps'
        if @result <> 0
            exec create_job_steps @message output,
                                @maxJobsToProcess = @maxJobsToProcess,
                                @logIntervalThreshold = @logIntervalThreshold,
                                @loggingEnabled = @loggingEnabled,
                                @loopingUpdateInterval = @loopingUpdateInterval,
                                @infoOnly = @infoOnly,
                                @debugMode = @debugMode

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part D: Update Step States
    Begin Try

        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'update_step_states')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' update_step_states'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call update_step_states'
        if @result <> 0
            exec update_step_states @message output, @infoOnly=@infoOnly, @maxJobsToProcess = @maxJobsToProcess, @loopingUpdateInterval=@loopingUpdateInterval

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part E: Update Job States
    --         This calls update_job_state, which calls update_dms_dataset_state, which calls update_dms_file_info_xml
    Begin Try

        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'update_job_state')
        If @result = 0
            Set @Action = 'Skipping'
        Else
            Set @Action = 'Calling'

        If @loggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @logIntervalThreshold
        Begin
            Set @loggingEnabled = 1
            Set @StatusMessage = @Action + ' update_job_state'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call update_job_state'
        if @result <> 0
            exec update_job_state @bypassDMS, @message output, @maxJobsToProcess = @maxJobsToProcess, @loopingUpdateInterval=@loopingUpdateInterval, @infoOnly=@infoOnly

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
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
            Set @StatusMessage = @Action + ' retry_capture_for_dms_reset_jobs'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call retry_capture_for_dms_reset_jobs'
        if @result <> 0
            exec retry_capture_for_dms_reset_jobs @message output
    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
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
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call UpdateCPULoading'
        if @result <> 0
            exec UpdateCPULoading @message output

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch
*/
    If @loggingEnabled = 1
    Begin
        Set @StatusMessage = 'update_context complete: ' + Convert(varchar(12), DateDiff(second, @StartTime, GetDate())) + ' seconds elapsed'
        exec post_log_entry 'Normal', @StatusMessage, 'update_context'
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_context] TO [DDL_Viewer] AS [dbo]
GO
