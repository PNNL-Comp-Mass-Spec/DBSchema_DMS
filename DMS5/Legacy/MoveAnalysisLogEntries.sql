/****** Object:  StoredProcedure [dbo].[MoveAnalysisLogEntries] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[MoveAnalysisLogEntries]
/****************************************************
**
**	Desc: Move log entries from analysis log into the 
**        historic log (insert and then delete)
**        that are older then given by @intervalHrs
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	06/14/2001
**			03/10/2009 mem - Now removing non-noteworthy entries from T_Analysis_Log before moving old entries to DMSHistoricLog1
**			10/04/2011 mem - Removed @DBName parameter
**			07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**    
*****************************************************/
(
	@intervalHrs int = 120
)
As
	set nocount on
	declare @cutoffDateTime datetime
	
	-- Require that @intervalHrs be at least 12
	If IsNull(@intervalHrs, 0) < 12
		Set @intervalHrs = 12
		
	set @cutoffDateTime = dateadd(hour, -1 * @intervalHrs, getdate())

	Declare @DBName varchar(64)
	set @DBName = DB_NAME()

	set nocount off
	
	-- Start transaction
	--
	declare @transName varchar(64)
	set @transName = 'TRAN_MoveAnalysisLogEntries'
	begin transaction @transName

	-- Delete log entries that we do not want to move to the DMS Historic Log DB
	DELETE FROM dbo.T_Analysis_Log
	WHERE posting_time < @cutoffDateTime AND 
	      message = 'Analysis complete for all available jobs'
	--
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Error removing unwanted log entries from T_Analysis_Log', 10, 1)
		return 51179
	end
	
	-- put entries into historic log
	--
	INSERT INTO DMSHistoricLog.dbo.T_Historic_Log_Entries
		(Entry_ID, posted_by, posting_time, type, message, DBName) 
	SELECT 
		 Entry_ID, posted_by, posting_time, type, message, @DBName
	FROM T_Analysis_Log
	WHERE posting_time < @cutoffDateTime
	
	--
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Insert was unsuccessful for historic log entry table from T_Analysis_Log',
			10, 1)
		return 51185
	end

	-- remove entries from main log
	--
	DELETE FROM T_Analysis_Log
	WHERE posting_time < @cutoffDateTime
	--
	if @@error <> 0
	begin
		rollback transaction @transName
		RAISERROR ('Delete was unsuccessful for T_Analysis_Log',
			10, 1)
		return 51186
	end
	
	commit transaction @transName
	
	return 0

GO

GRANT ALTER ON [dbo].[MoveAnalysisLogEntries] TO [D3L243] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[MoveAnalysisLogEntries] TO [D3L243] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[MoveAnalysisLogEntries] TO [D3L243] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[MoveAnalysisLogEntries] TO [Limited_Table_Write] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[MoveAnalysisLogEntries] TO [PNL\D3M578] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[MoveAnalysisLogEntries] TO [PNL\D3M580] AS [dbo]
GO

