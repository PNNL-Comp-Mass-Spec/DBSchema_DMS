/****** Object:  StoredProcedure [dbo].[CleanHealthLog] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure CleanHealthLog
/****************************************************
**
**	Desc: Deletes entries from the health log that
**        are older then given by @intervalHrs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
	@intervalHrs int = 24
)
As
	set nocount on
	declare @cutoffDateTime datetime
	
	set @cutoffDateTime = dateadd(hour, -1 * @intervalHrs, getdate())

	set nocount off

	-- remove entries from health log
	--
	DELETE FROM T_Health_Entries
	WHERE posting_time < @cutoffDateTime
	--
	if @@error <> 0
	begin
		RAISERROR ('Delete was unsuccessful for T_Health_Entries table',
			10, 1)
		return 51125
	end
	
	return 0
GO
