/****** Object:  StoredProcedure [dbo].[cleanup_operating_logs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[cleanup_operating_logs]
/****************************************************
**
**  Desc:   Deletes Info entries from T_Log_Entries if they are
**          more than @LogRetentionIntervalHours hours old
**
**          Move old log entries and event entries to DMSHistoricLog
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          11/21/2012 mem - Removed call to MoveAnalysisLogEntries
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/09/2022 mem - Update default log retention interval
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @logRetentionIntervalHours int = 336,
    @eventLogRetentionIntervalDays int = 365
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(256) = ''

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128) = 'Start'

    Begin Try

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If IsNull(@LogRetentionIntervalHours, 0) < 120
            Set @LogRetentionIntervalHours = 120

        If IsNull(@EventLogRetentionIntervalDays, 0) < 32
            Set @EventLogRetentionIntervalDays = 32

        ----------------------------------------------------
        -- Move old log entries from T_Log_Entries to DMSHistoricLog
        ----------------------------------------------------
        --
        Set @CurrentLocation = 'Call move_historic_log_entries'

        exec @myError = move_historic_log_entries @LogRetentionIntervalHours

        ----------------------------------------------------
        -- Move old events from T_Event_Log to DMSHistoricLog
        ----------------------------------------------------
        --
        Set @CurrentLocation = 'Call move_event_log_entries'

        exec @myError = move_event_log_entries @EventLogRetentionIntervalDays

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
