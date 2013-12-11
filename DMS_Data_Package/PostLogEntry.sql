/****** Object:  StoredProcedure [dbo].[PostLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.PostLogEntry
/****************************************************
**
**	Desc: Put new entry into the main log table
**
**	Return values: 0: success, otherwise, error code
*
**	Auth:	grk
**	Date:	10/31/2001
**			02/17/2005 mem - Added parameter @duplicateEntryHoldoffHours
**			05/31/2007 mem - Expanded the size of @type, @message, and @postedBy
**			07/14/2009 mem - Added parameter @callingUser
**    
*****************************************************/
	@type varchar(128),
	@message varchar(4096),
	@postedBy varchar(128)= 'na',
	@duplicateEntryHoldoffHours int = 0,			-- Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
	@callingUser varchar(128) = ''	
As

	Declare @myRowCount int
	Declare @EntryID int
	
	Declare @duplicateRowCount int
	Set @duplicateRowCount = 0
	
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
		SELECT @myRowCount = @@rowCount, @EntryID = SCOPE_IDENTITY()
		--
		if @myRowCount <> 1
		begin
			RAISERROR ('Update was unsuccessful for T_Log_Entries table', 10, 1)
			return 51191
		end

		If @callingUser <> ''
			exec AlterEnteredByUser 'T_Log_Entries', 'Entry_ID', @EntryID, @CallingUser, @EntryDateColumnName = 'posting_time', @EnteredByColumnName = 'Entered_By'

	End
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[PostLogEntry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[PostLogEntry] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[PostLogEntry] TO [svc-dms] AS [dbo]
GO
