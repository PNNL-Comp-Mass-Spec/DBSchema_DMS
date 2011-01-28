/****** Object:  StoredProcedure [dbo].[MoveHistoricLogEntries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[MoveHistoricLogEntries]
/****************************************************
**
**	Desc: Move log entries from main log into the 
**        historic log (insert and then delete)
**        that are older then given by @intervalHrs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	06/14/2001
**			03/10/2009 mem - Now removing non-noteworthy entries from T_Log_Entries before moving old entries to DMSHistoricLog1
**    
*****************************************************/
(
	@intervalHrs int = 72,
	@DBName varchar(64) = 'DMS'
)
As
	set nocount on
	declare @cutoffDateTime datetime
	
	set @cutoffDateTime = dateadd(hour, -1 * @intervalHrs, getdate())

	set @DBName = DB_NAME()

	set nocount off
	
	-- Start transaction
	--
	declare @transName varchar(64)
	set @transName = 'TRAN_MoveHistoricLogEntries'
	begin transaction @transName

	-- Delete log entries that we do not want to move to the DMS Historic Log DB
	DELETE FROM dbo.T_Log_Entries
	WHERE posting_time < @cutoffDateTime AND
		 ( message IN ('Archive or update complete for all available tasks', 
		               'Verfication complete for all available tasks', 
		               'Capture complete for all available tasks') OR
	       message LIKE '%: No Data Files to import.' OR
	       message LIKE '%: Completed task' )
	--
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Error removing unwanted log entries from T_Log_Entries', 10, 1)
		return 51179
	end
    
	-- Copy entries into the historic log database
	--
	INSERT INTO DMSHistoricLog1..T_Historic_Log_Entries
		(Entry_ID, posted_by, posting_time, type, message, DBName) 
	SELECT 
		 Entry_ID, posted_by, posting_time, type, message, @DBName
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
GRANT ALTER ON [dbo].[MoveHistoricLogEntries] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MoveHistoricLogEntries] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveHistoricLogEntries] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MoveHistoricLogEntries] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveHistoricLogEntries] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveHistoricLogEntries] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveHistoricLogEntries] TO [PNL\D3M580] AS [dbo]
GO
