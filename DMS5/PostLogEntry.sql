/****** Object:  StoredProcedure [dbo].[PostLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE Procedure [dbo].[PostLogEntry]
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
**		Auth: grk
**		Date: 1/26/2001
**            6/8/2006 grk - added logic to put data extraction manager stuff in analysis log
**    
*****************************************************/
	@type varchar(50),
	@message varchar(500),
	@postedBy varchar(50)= 'na'
As
	if (@type = 'Health')
		begin
			INSERT INTO T_Health_Entries
			(posted_by, posting_time, type, message) 
			VALUES ( @postedBy, GETDATE(), @type, @message)
			--
			if @@rowcount <> 1
			begin
				RAISERROR ('Update was unsuccessful for T_Health_Entries table',
					10, 1)
				return 51190
			end
		end
	else
	if ( charindex('analysis', lower(@postedBy)) > 0) or (( charindex('results', lower(@postedBy)) > 0)) or (( charindex('extraction', lower(@postedBy)) > 0)) 
		begin
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
		end
	else
		begin
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
		end

		
	return 0


GO
GRANT EXECUTE ON [dbo].[PostLogEntry] TO [DMS_SP_User]
GO
