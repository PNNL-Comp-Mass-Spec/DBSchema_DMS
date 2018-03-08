/****** Object:  StoredProcedure [dbo].[MoveHistoricLogEntries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[MoveHistoricLogEntries]
/****************************************************
**
**  Desc:   Move log entries from main log into the 
**          historic log (insert and then delete)
**          that are older than given by @intervalHrs
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/07/2018 mem - Initial version
**    
*****************************************************/
(
    @infoHoldoffWeeks int = 2
)
As
    Set XACT_ABORT, nocount on

    Declare @cutoffDateTime datetime
    
    -- Require that @infoHoldoffWeeks be at least 1
    If IsNull(@infoHoldoffWeeks, 0) < 1
        Set @infoHoldoffWeeks = 1

    Set @cutoffDateTime = DateAdd(week, -1 * @infoHoldoffWeeks, GetDate())

    -- Start transaction
    --
    declare @transName varchar(64) = 'TRAN_MoveHistoricLogEntries'
    begin transaction @transName

    -- Delete log entries that we do not want to move to the DMS Historic Log DB
    DELETE FROM dbo.T_Log_Entries
    WHERE posting_time < @cutoffDateTime AND
         ( type = 'Normal' AND message Like 'Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for % data packages%' OR
           posted_by = 'RebuildFragmentedIndices' AND type = 'Normal' AND message LIKE 'Reindexed % due to Fragmentation%'
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
    INSERT INTO DMSHistoricLog.dbo.T_Log_Entries_Data_Package
        (Entry_ID, posted_by, posting_time, type, message) 
    SELECT 
         Entry_ID, posted_by, posting_time, type, message
    FROM T_Log_Entries
    WHERE posting_time < @cutoffDateTime
    
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
    WHERE posting_time < @cutoffDateTime
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
