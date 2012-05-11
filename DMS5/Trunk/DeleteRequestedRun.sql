/****** Object:  StoredProcedure [dbo].[DeleteRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DeleteRequestedRun
/****************************************************
**
**	Desc: 
**	Remove a requested run (and all its dependencies)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	02/23/2006
**			10/29/2009 mem - Made @message an optional output parameter
**          02/26/2010 grk - delete factors
**			12/12/2011 mem - Added parameter @callingUser, which is passed to AlterEventLogEntryUser
**    
*****************************************************/
(
	@requestID int = 0,
	@message varchar(512)='' output,
	@callingUser varchar(128) = ''
)
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
	-- We are done if there is no associated request
	---------------------------------------------------
	--
	if @requestID = 0
	begin
		goto Done
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'DeleteRequestedRun'
	begin transaction @transName
	
	---------------------------------------------------
	-- delete associated factors
	---------------------------------------------------
	--
	DELETE FROM
		T_Factor
	WHERE
		TargetID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to delete factors for request'
		goto Done
	end		

	---------------------------------------------------
	-- delete EUS users associated with request
	---------------------------------------------------
	--
	DELETE FROM dbo.T_Requested_Run_EUS_Users
	WHERE Request_ID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to delete EUS users for request'
		goto Done
	end		

	---------------------------------------------------
	-- delete associated auto-created request
	---------------------------------------------------
	--
	DELETE FROM dbo.T_Requested_Run
	WHERE ID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to delete request'
		goto Done
	end		

	-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
	If Len(@callingUser) > 0
	Begin
		Declare @stateID int
		Set @stateID = 0
		
		Exec AlterEventLogEntryUser 11, @requestID, @stateID, @callingUser
	End

	commit transaction @transName
		
	---------------------------------------------------
	-- Complete
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[DeleteRequestedRun] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteRequestedRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteRequestedRun] TO [PNL\D3M580] AS [dbo]
GO
