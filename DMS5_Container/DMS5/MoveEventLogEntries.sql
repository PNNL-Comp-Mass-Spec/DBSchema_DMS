/****** Object:  StoredProcedure [dbo].[MoveEventLogEntries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.MoveEventLogEntries
/****************************************************
**
**	Desc: Move log entries from event log into the 
**        historic log (insert and then delete)
**        Moves entries older than @intervalDays days
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	07/13/2009
**			10/04/2011 mem - Removed @DBName parameter
**    
*****************************************************/
(
	@intervalDays int = 365
)
As
	set nocount on
	declare @cutoffDateTime datetime

	-- Require that @intervalDays be at least 32
	If IsNull(@intervalDays, 0) < 32
		Set @intervalDays = 32

	set @cutoffDateTime = dateadd(day, -1 * @intervalDays, getdate())

	Declare @DBName varchar(64)
	set @DBName = DB_NAME()

	set nocount off
	
	-- Start transaction
	--
	declare @transName varchar(64)
	set @transName = 'TRAN_MoveEventLogEntries'
	begin transaction @transName

	-- Copy entries into the historic log database
	--	
	INSERT INTO DMSHistoricLog1.dbo.T_Event_Log
	([Index], Target_Type, Target_ID, Target_State, Prev_Target_State, Entered, Entered_By)
	SELECT     [Index], Target_Type, Target_ID, Target_State, Prev_Target_State, Entered, Entered_By
	FROM T_Event_Log
	WHERE Entered < @cutoffDateTime
	ORDER BY [Index]
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
GRANT VIEW DEFINITION ON [dbo].[MoveEventLogEntries] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveEventLogEntries] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveEventLogEntries] TO [PNL\D3M580] AS [dbo]
GO
