/****** Object:  StoredProcedure [dbo].[AssignEUSUsersToRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure AssignEUSUsersToRequestedRun
/****************************************************
**
**	Desc:
**    Associates the given list of EUS users with given
**    requested run
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 2/21/2006
**
*****************************************************/
	@request int,
	@eusProposalID varchar(10) = '',
	@eusUsersList varchar(1024) = '',
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	

	---------------------------------------------------
	-- clear all associations if the user list is blank
	---------------------------------------------------
	
	if @eusUsersList = ''
	begin
		DELETE FROM T_Requested_Run_EUS_Users
		WHERE     (Request_ID = @request)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to clear all user associations for this proposal'
			return 51081
		end
		return 0
	end

	---------------------------------------------------
	-- verify that all users in list have access to
	-- given proposal
	---------------------------------------------------
	declare @n int
	set @n = 0
	
	SELECT 
		@n = count(*)
	FROM 
		MakeTableFromList(@eusUsersList)
	WHERE 
		CAST(Item as int) NOT IN
		(
			SELECT Person_ID
			FROM  T_EUS_Proposal_Users
			WHERE Proposal_ID = @eusProposalID
		)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to verify that all users are associated with proposal'
		return 51082
	end

	if @n <> 0
	begin
		set @message = 'Some assigned users are not associated with the specified proposal'
		return 51301
	end
	
	---------------------------------------------------
	-- add associations between request and users 
	-- who are in list, but not in association table
	---------------------------------------------------
	--
	INSERT INTO T_Requested_Run_EUS_Users
		(EUS_Person_ID, Request_ID)
	SELECT 
		CAST(Item as int) as EUS_Person_ID, @request as Request_ID 
	FROM 
		MakeTableFromList(@eusUsersList)
	WHERE 
		CAST(Item as int) NOT IN
		(
			SELECT EUS_Person_ID
			FROM  T_Requested_Run_EUS_Users 
			WHERE Request_ID = @request
		)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to add associations for new users'
		return 51083
	end

	---------------------------------------------------
	-- remove associations between request and users
	-- who are in association table but not in list
	---------------------------------------------------
	--
	DELETE FROM  T_Requested_Run_EUS_Users
	WHERE 
	Request_ID = @request AND
	EUS_Person_ID NOT IN
	(
	SELECT CAST(Item as int) as eu FROM MakeTableFromList(@eusUsersList)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to remove existing associations for users that are not currently in the list'
		return 51084
	end

	return @myError

GO
