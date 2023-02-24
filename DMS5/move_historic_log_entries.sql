/****** Object:  StoredProcedure [dbo].[move_historic_log_entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[move_historic_log_entries]
/****************************************************
**
**  Desc:   Move log entries from the main log table into the
**          historic log table (insert and then delete)
**
**  Auth:   grk
**  Date:   06/14/2001
**          03/10/2009 mem - Now removing non-noteworthy entries from T_Log_Entries before moving old entries to DMSHistoricLog1
**          10/04/2011 mem - Removed @DBName parameter
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          10/15/2012 mem - Now excluding routine messages from backup_dms_dbs and rebuild_fragmented_indices
**          10/29/2015 mem - Increase default value from 5 days to 14 days (336 hours)
**          06/09/2022 mem - Rename target table from T_Historic_Log_Entries to T_Log_Entries
**                         - No longer store the database name in the target table
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @intervalHrs int = 336
)
AS
    Set nocount On

    Declare @cutoffDateTime datetime

    -- Require that @intervalHrs be at least 120
    If IsNull(@intervalHrs, 0) < 120
        Set @intervalHrs = 120

    set @cutoffDateTime = dateadd(hour, -1 * @intervalHrs, getdate())

    set nocount off

    -- Start transaction
    --
    Declare @transName varchar(64)
    set @transName = 'TRAN_move_historic_log_entries'
    begin transaction @transName

    -- Delete log entries that we do not want to move to the DMS Historic Log DB
    DELETE FROM dbo.T_Log_Entries
    WHERE Entered < @cutoffDateTime AND
         ( message IN ('Archive or update complete for all available tasks',
                       'Verfication complete for all available tasks',
                       'Capture complete for all available tasks') OR
           message LIKE '%: No Data Files to import.' OR
           message LIKE '%: Completed task'           OR
           posted_by = 'backup_dms_dbs'             AND type = 'Normal' AND message LIKE 'DB Backup Complete (LogBU%' OR
           posted_by = 'rebuild_fragmented_indices' AND type = 'Normal' AND message LIKE 'Reindexed % due to Fragmentation%'
           )
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Error removing unwanted log entries from T_Log_Entries', 10, 1)
        return 51179
    end

    -- Copy entries into the historic log database
    --
    INSERT INTO DMSHistoricLog.dbo.T_Log_Entries (Entry_ID, posted_by, Entered, Type, message)
    SELECT Entry_ID,
           posted_by,
           Entered,
           Type,
           message
    FROM T_Log_Entries
    WHERE Entered < @cutoffDateTime
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from T_Log_Entries',
            10, 1)
        return 51180
    end

    -- Remove the old entries from T_Log_Entries
    --
    DELETE FROM T_Log_Entries
    WHERE Entered < @cutoffDateTime
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete was unsuccessful for T_Log_Entries',
            10, 1)
        return 51181
    end

    commit transaction @transName

    return 0

GO
GRANT ALTER ON [dbo].[move_historic_log_entries] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[move_historic_log_entries] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[move_historic_log_entries] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[move_historic_log_entries] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[move_historic_log_entries] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[move_historic_log_entries] TO [Limited_Table_Write] AS [dbo]
GO
