/****** Object:  StoredProcedure [dbo].[move_entries_to_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[move_entries_to_history]
/****************************************************
**
**  Desc: Move entries from log tables into
**          historic log DB (insert and then delete)
**        Moves entries older than @intervalDays days
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/12/2011 mem - Initial version
**          10/04/2011 mem - Removed @DBName parameter
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @intervalDays int = 365
)
AS
    set nocount on
    declare @cutoffDateTime datetime

    -- Require that @intervalDays be at least 32
    If IsNull(@intervalDays, 0) < 32
        Set @intervalDays = 32

    set @cutoffDateTime = dateadd(day, -1 * @intervalDays, getdate())

    Declare @DBName varchar(64)
    set @DBName = DB_NAME()

    set nocount off

    declare @transName varchar(64)
    set @transName = 'TRAN_MoveLogEntries'

    ----------------------------------------------------------
    -- Copy Job_Events entries into database DMSHistoricLogPipeline
    ----------------------------------------------------------
    --
    begin transaction @transName

    INSERT INTO DMSHistoricLogPipeline.dbo.T_Job_Events(
                                                        Event_ID,
                                                        Job,
                                                        Target_State,
                                                        Prev_Target_State,
                                                        Entered,
                                                        Entered_By )
    SELECT Event_ID,
           Job,
           Target_State,
           Prev_Target_State,
           Entered,
           Entered_By
    FROM T_Job_Events
    WHERE Entered < @cutoffDateTime
    ORDER BY Event_ID
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from T_Job_Events',
            10, 1)
        return 51180
    end

    -- Remove the old entries
    --
    DELETE FROM T_Job_Events
    WHERE Entered < @cutoffDateTime
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete was unsuccessful for T_Job_Events',
            10, 1)
        return 51181
    end

    commit transaction @transName


    ----------------------------------------------------------
    -- Copy Job_Step_Events entries into database DMSHistoricLogPipeline
    ----------------------------------------------------------
    --
    begin transaction @transName

    INSERT INTO DMSHistoricLogPipeline.dbo.T_Job_Step_Events(
                                                        Event_ID,
                                                        Job,
                                                        Step,
                                                        Target_State,
                                                        Prev_Target_State,
                                                        Entered,
                                                        Entered_By )
    SELECT Event_ID,
           Job,
           Step,
           Target_State,
           Prev_Target_State,
           Entered,
           Entered_By
    FROM T_Job_Step_Events
    WHERE Entered < @cutoffDateTime
    ORDER BY Event_ID
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from T_Job_Step_Events',
            10, 1)
        return 51180
    end

    -- Remove the old entries
    --
    DELETE FROM T_Job_Step_Events
    WHERE Entered < @cutoffDateTime
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete was unsuccessful for T_Job_Step_Events',
            10, 1)
        return 51181
    end

    commit transaction @transName


    ----------------------------------------------------------
    -- Copy Job_Step_Processing_Log entries into database DMSHistoricLogPipeline
    ----------------------------------------------------------
    --
    begin transaction @transName

    INSERT INTO DMSHistoricLogPipeline.dbo.T_Job_Step_Processing_Log(
                                                        Event_ID,
                                                        Job,
                                                        Step,
                                                        Processor,
                                                        Entered,
                                                        Entered_By )
    SELECT Event_ID,
           Job,
           Step,
           Processor,
           Entered,
           Entered_By
    FROM T_Job_Step_Processing_Log
    WHERE Entered < @cutoffDateTime
    ORDER BY Event_ID
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from T_Job_Step_Processing_Log',
            10, 1)
        return 51180
    end

    -- Remove the old entries
    --
    DELETE FROM T_Job_Step_Processing_Log
    WHERE Entered < @cutoffDateTime
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete was unsuccessful for T_Job_Step_Processing_Log',
            10, 1)
        return 51181
    end

    commit transaction @transName


    ----------------------------------------------------------
    -- Copy Log entries into database DMSHistoricLogPipeline
    ----------------------------------------------------------
    --
    begin transaction @transName

    INSERT INTO DMSHistoricLogPipeline.dbo.T_Log_Entries(
                                                         Entry_ID,
                                                         posted_by,
                                                         Entered,
                                                         Type,
                                                         message,
                                                         Entered_By )
    SELECT Entry_ID,
           posted_by,
           Entered,
           Type,
           message,
           Entered_By
    FROM T_Log_Entries
    WHERE Entered < @cutoffDateTime
    ORDER BY Entry_ID
    --
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from T_Log_Entries',
            10, 1)
        return 51180
    end

    -- Remove the old entries
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
GRANT VIEW DEFINITION ON [dbo].[move_entries_to_history] TO [DDL_Viewer] AS [dbo]
GO
