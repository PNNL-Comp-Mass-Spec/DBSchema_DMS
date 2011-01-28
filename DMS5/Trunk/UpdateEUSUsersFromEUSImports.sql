/****** Object:  StoredProcedure [dbo].[UpdateEUSUsersFromEUSImports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure UpdateEUSUsersFromEUSImports
/****************************************************
**
**	Desc: 
**  Updates associated EUS user associations for
**  proposals that are currently active in DMS
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/1/2006
**    
*****************************************************/
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

	---------------------------------------------------
	-- Add any EUS users to DMS EUS users table that
	-- are not already present.  Consider only EUS
	-- proposals that are currently in the active state.
	---------------------------------------------------

	INSERT INTO T_EUS_Users
	(PERSON_ID, NAME_FM)
	SELECT DISTINCT
		PERSON_ID, NAME_FM
	FROM EMSL_User.dbo.USERS
	WHERE
		PROPOSAL_ID IN 
		(
			SELECT     PROPOSAL_ID
			FROM         T_EUS_Proposals
			WHERE     (State_ID = 2)
		)
		AND PERSON_ID NOT IN
		(
			SELECT     PERSON_ID
			FROM         T_EUS_Users
		)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error while trying to add EUS users to DMS'
      return 51007
    end

	---------------------------------------------------
	-- Add any EUS associations to DMS tables that
	-- are not already present.  Mark any such added 
	-- associations as of interest to DMS.  Consider 
	-- only EUS proposals that are currently in the 
	-- active state.
	---------------------------------------------------

	INSERT INTO T_EUS_Proposal_Users
						(Proposal_ID, Person_ID, Of_DMS_Interest)
	SELECT DISTINCT PROPOSAL_ID,PERSON_ID, 'Y'
	FROM EMSL_User.dbo.USERS
	WHERE
		PROPOSAL_ID IN 
		(
			SELECT     PROPOSAL_ID
			FROM         T_EUS_Proposals
			WHERE     (State_ID = 2)
		)
	AND NOT EXISTS
	(
	SELECT Proposal_ID, Person_ID
	FROM         T_EUS_Proposal_Users
	WHERE     
		(T_EUS_Proposal_Users.Proposal_ID = EMSL_User.dbo.USERS.PROPOSAL_ID) AND 
		(T_EUS_Proposal_Users.Person_ID = EMSL_User.dbo.USERS.PERSON_ID)
	)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error while trying to add EUS user-to-proposal associations to DMS'
      return 51008
    end


	---------------------------------------------------
	-- Remove any associations that are present in DMS 
	-- EUS user-to-proposal association table, but no 
	-- longer present in EUS.  Consider only EUS proposals
	--  that are currently in the active state.
	---------------------------------------------------
	
	DELETE
	FROM T_EUS_Proposal_Users
	WHERE
		PROPOSAL_ID IN 
		(
			SELECT     PROPOSAL_ID
			FROM         T_EUS_Proposals
			WHERE     (State_ID = 2)
		)
	AND NOT EXISTS
	(
		SELECT DISTINCT PROPOSAL_ID,PERSON_ID
		FROM EMSL_User.dbo.USERS
		WHERE     
			(T_EUS_Proposal_Users.Proposal_ID = EMSL_User.dbo.USERS.PROPOSAL_ID) AND 
			(T_EUS_Proposal_Users.Person_ID = EMSL_User.dbo.USERS.PERSON_ID)
	)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error while trying to remove EUS user-to-proposal associations in DMS that are no longer in EUS'
      return 51009
    end


	---------------------------------------------------
	-- 
	---------------------------------------------------


	return @myError

GO
GRANT ALTER ON [dbo].[UpdateEUSUsersFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEUSUsersFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsersFromEUSImports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsersFromEUSImports] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEUSUsersFromEUSImports] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsersFromEUSImports] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsersFromEUSImports] TO [PNL\D3M580] AS [dbo]
GO
