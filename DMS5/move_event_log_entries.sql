/****** Object:  StoredProcedure [dbo].[move_event_log_entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[move_event_log_entries]
/****************************************************
**
**  Desc:   Move log entries from event log into the historic log (insert and then delete)
**          Moves entries older than @intervalDays days
**
**  Auth:   grk
**  Date:   07/13/2009
**          10/04/2011 mem - Removed @DBName parameter
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          06/08/2022 mem - Rename column Index to Event_ID
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @intervalDays int = 365
)
AS
    Set nocount on

    Declare @cutoffDateTime datetime

    -- Require that @intervalDays be at least 32
    If IsNull(@intervalDays, 0) < 32
        Set @intervalDays = 32

    set @cutoffDateTime = dateadd(day, -1 * @intervalDays, getdate())

    Declare @DBName varchar(64)
    set @DBName = DB_NAME()

    set nocount off

    -- Start transaction
    --
    Declare @transName varchar(64) = 'TRAN_move_event_log_entries'

    begin transaction @transName

    -- Copy entries into the historic log database
    --
    INSERT INTO DMSHistoricLog.dbo.T_Event_Log( Event_ID,
                                                Target_Type,
                                                Target_ID,
                                                Target_State,
                                                Prev_Target_State,
                                                Entered,
                                                Entered_By )
    SELECT Event_ID,
           Target_Type,
           Target_ID,
           Target_State,
           Prev_Target_State,
           Entered,
           Entered_By
    FROM T_Event_Log
    WHERE Entered < @cutoffDateTime
    ORDER BY Event_ID
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from T_Event_Log',
            10, 1)
        return 51180
    end

    -- Remove the old entries from T_Event_Log
    --
    DELETE FROM T_Event_Log
    WHERE Entered < @cutoffDateTime
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete was unsuccessful for T_Event_Log',
            10, 1)
        return 51181
    end

    commit transaction @transName

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[move_event_log_entries] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[move_event_log_entries] TO [Limited_Table_Write] AS [dbo]
GO
