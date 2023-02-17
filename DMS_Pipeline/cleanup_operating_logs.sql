/****** Object:  StoredProcedure [dbo].[cleanup_operating_logs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[cleanup_operating_logs]
/****************************************************
**
**  Desc:   Move old log entries and event entries to DMSHistoricLogPipeline
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @infoHoldoffWeeks int = 4,
    @logRetentionIntervalDays int = 365
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(256)
    Set @message = ''

    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin Try

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If IsNull(@InfoHoldoffWeeks, 0) < 1
            Set @InfoHoldoffWeeks = 1

        If IsNull(@LogRetentionIntervalDays, 0) < 14
            Set @LogRetentionIntervalDays = 14

        ----------------------------------------------------
        -- Delete Info and Warn entries posted more than @InfoHoldoffWeeks weeks ago
        ----------------------------------------------------
        --
        Set @CurrentLocation = 'Delete non-noteworthy log entries'

        DELETE FROM T_Log_Entries
        WHERE (Entered < DATEADD(week, -@InfoHoldoffWeeks, GETDATE())) AND
              (message LIKE 'Resuming [0-9]%job%' OR
               message LIKE 'Deleted job % from T_Jobs')
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error deleting old Info messages from T_Log_Entries'
            Exec post_log_entry 'Error', @message, 'cleanup_operating_logs'
        End

        ----------------------------------------------------
        -- Move old log entries and event entries to DMSHistoricLogPipeline
        ----------------------------------------------------
        --
        Set @CurrentLocation = 'Call move_entries_to_history'

        exec @myError = move_entries_to_history @LogRetentionIntervalDays

    End Try
    Begin Catch
        -- Error caught; log the error
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'cleanup_operating_logs')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[cleanup_operating_logs] TO [DDL_Viewer] AS [dbo]
GO
