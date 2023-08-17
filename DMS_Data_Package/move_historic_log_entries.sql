/****** Object:  StoredProcedure [dbo].[move_historic_log_entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[move_historic_log_entries]
/****************************************************
**
**  Desc:   Move log entries from t_log_entries into into the historic log table (t_log_entries_data_package in DMSHistoricLog)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/07/2018 mem - Initial version
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/15/2023 mem - Update the where clause filter for finding unimporant log entries
**
*****************************************************/
(
    @infoHoldoffWeeks int = 2
)
AS
    Set XACT_ABORT, nocount on

    Declare @cutoffDateTime datetime

    -- Require that @infoHoldoffWeeks be at least 1
    If IsNull(@infoHoldoffWeeks, 0) < 1
        Set @infoHoldoffWeeks = 1

    Set @cutoffDateTime = DateAdd(week, -1 * @infoHoldoffWeeks, GetDate())

    -- Start transaction
    --
    declare @transName varchar(64) = 'TRAN_move_historic_log_entries'
    begin transaction @transName

    -- Delete log entries that we do not want to move to the DMS Historic Log DB
    DELETE FROM dbo.T_Log_Entries
    WHERE Entered < @cutoffDateTime AND
         ( type = 'Normal' AND message Like 'Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for % data package%' OR
           posted_by = 'rebuild_fragmented_indices' AND type = 'Normal' AND message LIKE 'Reindexed % due to Fragmentation%'
           )

    If @@error <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Error removing unwanted log entries from T_Log_Entries', 10, 1)
        return 51179
    End

    -- Copy entries into the historic log database
    INSERT INTO DMSHistoricLog.dbo.T_Log_Entries_Data_Package
        (Entry_ID, posted_by, Entered, type, message)
    SELECT
         Entry_ID, posted_by, Entered, type, message
    FROM T_Log_Entries
    WHERE Entered < @cutoffDateTime

    If @@error <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from T_Log_Entries',
            10, 1)
        return 51180
    End

    -- Remove the old entries from T_Log_Entries
    DELETE FROM T_Log_Entries
    WHERE Entered < @cutoffDateTime

    If @@error <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Delete was unsuccessful for T_Log_Entries',
            10, 1)
        return 51181
    End

    commit transaction @transName

    return 0

GO
