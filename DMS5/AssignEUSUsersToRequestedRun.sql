/****** Object:  StoredProcedure [dbo].[AssignEUSUsersToRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AssignEUSUsersToRequestedRun
/****************************************************
**
**	Desc:
**    Associates the given list of EUS users with given
**    requested run
**
**    No validation is performed.  Caller should call
**    ValidateEUSUsage before calling this procedure
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	02/21/2006
**			11/09/2006 grk - Added numeric test for eus user ID (Ticket #318)
**			07/11/2007 grk - factored out EUS proposal validation (Ticket #499)
**			11/16/2016 mem - Use udfParseDelimitedIntegerList to parse @eusUsersList
**
*****************************************************/
	@request int,
	@eusProposalID varchar(10) = '',
	@eusUsersList varchar(1024) = '',			-- Comma separated list of EUS user IDs (integers)
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
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
	-- Populate a temporary table with the user IDs in @eusUsersList
	---------------------------------------------------
	--
	DECLARE @tmpUserIDs TABLE (ID int)
	
	INSERT INTO @tmpUserIDs (ID)
	SELECT Value
	FROM dbo.udfParseDelimitedIntegerList(@eusUsersList, ',')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		
	---------------------------------------------------
	-- add associations between request and users 
	-- who are in list, but not in association table
	---------------------------------------------------
	--
	INSERT INTO T_Requested_Run_EUS_Users( EUS_Person_ID,
	                                       Request_ID )
	SELECT ID AS EUS_Person_ID,
	       @request AS Request_ID
	FROM @tmpUserIDs
	WHERE ID NOT IN ( SELECT EUS_Person_ID
	                  FROM T_Requested_Run_EUS_Users
	                  WHERE Request_ID = @request )

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
	DELETE FROM T_Requested_Run_EUS_Users
	WHERE Request_ID = @request AND
	      EUS_Person_ID NOT IN ( SELECT ID
	                             FROM @tmpUserIDs )
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
GRANT VIEW DEFINITION ON [dbo].[AssignEUSUsersToRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AssignEUSUsersToRequestedRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AssignEUSUsersToRequestedRun] TO [PNL\D3M580] AS [dbo]
GO
