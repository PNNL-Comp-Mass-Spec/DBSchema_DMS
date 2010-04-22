/****** Object:  StoredProcedure [dbo].[PostLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.PostLogEntry
/****************************************************
**
**	Desc: Put new entry into the main log table or the
**        health log table
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	01/26/2001
**			06/08/2006 grk - added logic to put data extraction manager stuff in analysis log
**			03/30/2009 mem - Added parameter @duplicateEntryHoldoffHours
**						   - Expanded the size of @type, @message, and @postedBy
**			07/20/2009 grk - eliminate health log (http://prismtrac.pnl.gov/trac/ticket/742)
**    
*****************************************************/
	@type varchar(128),
	@message varchar(4096),
	@postedBy varchar(128)= 'na',
	@duplicateEntryHoldoffHours int = 0			-- Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
As
	Declare @duplicateRowCount int
	Set @duplicateRowCount = 0
	
		
	If ( charindex('analysis', lower(@postedBy)) > 0) or (( charindex('results', lower(@postedBy)) > 0)) or (( charindex('extraction', lower(@postedBy)) > 0)) 
	Begin
		If IsNull(@duplicateEntryHoldoffHours, 0) > 0
		Begin
			SELECT @duplicateRowCount = COUNT(*)
			FROM T_Analysis_Log
			WHERE Message = @message AND Type = @type AND Posting_Time >= (GetDate() - @duplicateEntryHoldoffHours)
		End

		If @duplicateRowCount = 0
		Begin
			INSERT INTO T_Analysis_Log
			(posted_by, posting_time, type, message) 
			VALUES ( @postedBy, GETDATE(), @type, @message)
			--
			if @@rowcount <> 1
			begin
				RAISERROR ('Update was unsuccessful for T_Analysis_Log table',
					10, 1)
				return 51192
			end
		End
	End
	Else
	Begin
		If IsNull(@duplicateEntryHoldoffHours, 0) > 0
		Begin
			SELECT @duplicateRowCount = COUNT(*)
			FROM T_Log_Entries
			WHERE Message = @message AND Type = @type AND Posting_Time >= (GetDate() - @duplicateEntryHoldoffHours)
		End

		If @duplicateRowCount = 0
		Begin
			INSERT INTO T_Log_Entries
			(posted_by, posting_time, type, message) 
			VALUES ( @postedBy, GETDATE(), @type, @message)
			--
			if @@rowcount <> 1
			begin
				RAISERROR ('Update was unsuccessful for T_Log_Entries table',
					10, 1)
				return 51191
			end
		End
	End
			
	return 0

GO
GRANT EXECUTE ON [dbo].[PostLogEntry] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[PostLogEntry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[PostLogEntry] TO [PNL\D3M580] AS [dbo]
GO
