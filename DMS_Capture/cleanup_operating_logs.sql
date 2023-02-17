/****** Object:  StoredProcedure [dbo].[CleanupOperatingLogs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CleanupOperatingLogs]
/****************************************************
**
**  Desc:   Delete Info entries from T_Log_Entries if they are
**          more than @InfoHoldoffWeeks weeks old
**
**          Move old log entries and event entries to DMSHistoricLogCapture
**
**  Auth:   mem
**  Date:   10/04/2011 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          08/25/2022 mem - Use new column name in T_Log_Entries
**
*****************************************************/
(
    @InfoHoldoffWeeks int = 2,
    @LogRetentionIntervalDays int = 180
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(256) = ''

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128) = 'Start'

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
        Set @CurrentLocation = 'Delete Info and Warn entries'

        DELETE FROM T_Log_Entries
        WHERE (Entered < DATEADD(week, -@InfoHoldoffWeeks, GETDATE())) AND
              (Type = 'info' OR
              (Type = 'warn' AND message = 'Dataset Quality tool is not presently active') )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error deleting old Info and Warn messages from T_Log_Entries'
            Exec PostLogEntry 'Error', @message, 'CleanupOperatingLogs'
        End

        ----------------------------------------------------
        -- Move old log entries and event entries to DMSHistoricLogCapture
        ----------------------------------------------------
        --
        Set @CurrentLocation = 'Call MoveEntriesToHistory'

        exec @myError = MoveEntriesToHistory @LogRetentionIntervalDays

    End Try
    Begin Catch
        -- Error caught; log the error
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'CleanupOperatingLogs')
        exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
    End Catch

Done:

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[CleanupOperatingLogs] TO [DDL_Viewer] AS [dbo]
GO
