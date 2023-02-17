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
**          05/30/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Added parameter @infoOnly (http://prismtrac.pnl.gov/trac/ticket/713)
**          01/17/2009 mem - Now calling sync_job_info (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          02/19/2009 grk - added call to remove_dms_deleted_jobs (Ticket #723)
**          06/02/2009 mem - Added parameter @MaxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameters @LogIntervalThreshold, @LoggingEnabled, and @LoopingUpdateInterval
**          06/04/2009 mem - Added Try/Catch error handling
**                         - Now using T_Process_Step_Control to determine whether or not to Update states in DMS
**          06/05/2009 mem - Added expanded support for T_Process_Step_Control
**          03/21/2011 mem - Added parameter @DebugMode; now passing @infoOnly to add_new_jobs
**          01/12/2012 mem - Now passing @infoOnly to update_job_state
**          05/02/2015 mem - Now calling auto_fix_failed_jobs
**          05/28/2015 mem - No longer calling import_job_processors
**          11/20/2015 mem - Now calling update_actual_cpu_loading
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/30/2018 mem - Update comments
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @bypassDMS tinyint = 0,             -- 0: normal mode; will lookup the bypass mode in T_Process_Step_Control; 1: test mode; state of DMS is not affected
    @maxJobsToProcess int = 0,
    @logIntervalThreshold int = 15,     -- If this procedure runs longer than this threshold, status messages will be posted to the log
    @loggingEnabled tinyint = 0,        -- Set to 1 to immediately enable progress logging; if 0, logging will auto-enable if @LogIntervalThreshold seconds elapse
    @loopingUpdateInterval int = 5,     -- Seconds between detailed logging while looping sets of jobs or steps to process
    @infoOnly tinyint = 0,              -- 1 to preview changes that would be made; 2 to add new jobs but do not create job steps
    @debugMode tinyint = 0              -- 0 for no debugging; 1 to see debug messages
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
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'remove_dms_deleted_jobs')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' remove_dms_deleted_jobs'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call remove_dms_deleted_jobs'
        if @result <> 0
            exec remove_dms_deleted_jobs @bypassDMS, @message output, @MaxJobsToProcess = @MaxJobsToProcess


        -- Step 2: Add new jobs, hold/resume/reset existing jobs
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'add_new_jobs')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' add_new_jobs'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call add_new_jobs'
        if @result <> 0
            exec add_new_jobs @bypassDMS,
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
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part B: Import Processors and Sync Job Info
    Begin Try

        -- Step 3: Import Processors
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'import_processors')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' import_processors'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call import_processors'
        if @result <> 0
            exec import_processors @bypassDMS, @message output


        /*
        ---------------------------------------------------
        -- Deprecated in May 2015:
        -- Import Job Processors
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'import_job_processors')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' import_job_processors'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call import_job_processors'
        if @result <> 0
            exec import_job_processors @bypassDMS, @message output
        */

        -- Step 4: Sync Job Info
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'sync_job_info')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' sync_job_info'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call sync_job_info'
        if @result <> 0
            exec sync_job_info @bypassDMS, @message output

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part C
    Begin Try

        -- Step 5: Create job steps
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'create_job_steps')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' create_job_steps'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call create_job_steps'
        if @result <> 0
            exec create_job_steps @message output,
                                @MaxJobsToProcess = @MaxJobsToProcess,
                                @LogIntervalThreshold=@LogIntervalThreshold,
                                @LoggingEnabled=@LoggingEnabled,
                                @LoopingUpdateInterval=@LoopingUpdateInterval,
                                @infoOnly=@infoOnly,
                                @DebugMode=@DebugMode

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part D
    Begin Try

        -- Step 6: Update step states
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'update_step_states')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' update_step_states'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call update_step_states'
        if @result <> 0
            exec update_step_states @message output,
                                  @infoOnly=@infoOnly,
                                  @MaxJobsToProcess = @MaxJobsToProcess,
                                  @LoopingUpdateInterval=@LoopingUpdateInterval

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part E
    Begin Try

        -- Step 7: Update job states
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'update_job_state')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' update_job_state'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call update_job_state'
        if @result <> 0
            exec update_job_state @bypassDMS,
                                @message output,
                                @MaxJobsToProcess = @MaxJobsToProcess,
                                @LoopingUpdateInterval= @LoopingUpdateInterval,
                                @infoOnly = @infoOnly

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part F
    Begin Try

        -- Step 8: Update CPU loading and memory usage
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'update_cpu_loading')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' update_cpu_loading'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call update_cpu_loading'
        If @result <> 0
        Begin
            -- First update Actual_CPU_Load in T_Job_Steps
            exec update_actual_cpu_loading @infoOnly = 0

            -- Now update CPUs_Available in T_Machines
            exec update_cpu_loading @message output
        End

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

    -- Part G
    Begin Try

        -- Step 9: Auto fix failed jobs
        --
        Set @result = 1
        SELECT @result = enabled FROM T_Process_Step_Control WHERE (Processing_Step_Name = 'auto_fix_failed_jobs')
        If @result = 0
            set @Action = 'Skipping'
        Else
            set @Action = 'Calling'

        If @LoggingEnabled = 1 Or DateDiff(second, @StartTime, GetDate()) >= @LogIntervalThreshold
        Begin
            Set @LoggingEnabled = 1
            Set @StatusMessage = @Action + ' auto_fix_failed_jobs'
            exec post_log_entry 'Progress', @StatusMessage, 'update_context'
        End

        Set @CurrentLocation = 'Call auto_fix_failed_jobs'
        if @result <> 0
            exec auto_fix_failed_jobs @message = @message output, @infoonly = @infoOnly

    End Try
    Begin Catch
        -- Error caught; log the error, then continue at the next section
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_context')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch


    If @LoggingEnabled = 1
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
GRANT VIEW DEFINITION ON [dbo].[update_context] TO [Limited_Table_Write] AS [dbo]
GO
