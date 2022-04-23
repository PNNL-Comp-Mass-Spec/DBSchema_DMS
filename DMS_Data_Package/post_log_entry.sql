/****** Object:  StoredProcedure [dbo].[post_log_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.post_log_entry
/****************************************************
**
**	Desc: Calls PostLogEntry to add a new entry to
**        the main log table
**
**	Auth:	mem
**	Date:	04/17/2022 mem - Initial version
**
*****************************************************/
(
	@type varchar(128),
	@message varchar(4096),
	@postedBy varchar(128)= 'na',
	@duplicateEntryHoldoffHours int = 0,			-- Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
	@callingUser varchar(128) = ''
)
As

	Declare @returnValue int = 0

    Exec @returnValue = PostLogEntry @type, @message, @postedBy, @duplicateEntryHoldoffHours, @callingUser

    return @returnValue


GO
GRANT VIEW DEFINITION ON [dbo].[post_log_entry] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[post_log_entry] TO [DMS_SP_User] AS [dbo]
GO
