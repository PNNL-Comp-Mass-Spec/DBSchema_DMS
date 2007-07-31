/****** Object:  StoredProcedure [dbo].[DeleteRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Procedure DeleteRequestedRun
/****************************************************
**
**	Desc: 
**	Remove a requested run (and all its dependencies)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 2/23/2006
**    
*****************************************************/
	@requestID int = 0,
	@message varchar(512) output
As
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	declare @msg varchar(256)

	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteRequestedRun'
	begin transaction @transName

	---------------------------------------------------
	-- 
	---------------------------------------------------

	DELETE FROM T_Requested_Run_EUS_Users
	WHERE     (Request_ID = @requestID)

	---------------------------------------------------
	-- 
	---------------------------------------------------

	DELETE FROM T_Requested_Run
	WHERE (ID = @requestID)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	--rollback transaction @transName

	commit transaction @transName
	return 0

GO
GRANT EXECUTE ON [dbo].[DeleteRequestedRun] TO [DMS_Ops_Admin]
GO
GRANT EXECUTE ON [dbo].[DeleteRequestedRun] TO [Limited_Table_Write]
GO
