/****** Object:  StoredProcedure [dbo].[UpdateResearchTeamObserver] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateResearchTeamObserver
/****************************************************
**
**  Desc:
**  Sets user registration for notification entities
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 04/03/2010
**    04/03/2010 grk - initial release
**    04/04/2010 grk - callable as operatons_sproc
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
	@campaignNum varchar(64),
	@mode varchar(12) = 'add', -- or 'remove'
	@message varchar(512) output,
   	@callingUser varchar(128) = ''
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	DECLARE @observerRoleID INT 
	SET @observerRoleID = 10

	---------------------------------------------------
	-- user id 
	---------------------------------------------------
	--
	IF @callingUser = ''
	BEGIN
		SET @myError = 50
		SET @message = 'User ID is missing'
		GOTO Done
	END
	--
	DECLARE @PRN varchar(15)
	SET @PRN = @callingUser
	
	---------------------------------------------------
	-- Resolve 
	---------------------------------------------------
	--
	declare @campaignID int
	set @campaignID = 0
	--
	DECLARE @researchTeamID INT
	SET @researchTeamID = 0
	--
	SELECT
		@campaignID = Campaign_ID, 
		@researchTeamID = ISNULL(CM_Research_Team, 0)
	FROM
		T_Campaign
	WHERE
		Campaign_Num = @campaignNum
	--
	IF @campaignID = 0
	BEGIN
		SET @myError = 51
		SET @message = 'Campaign "' + @campaignNum + '" is not valid'
		GOTO Done
	END

	---------------------------------------------------
	-- Resolve 
	---------------------------------------------------
	--
	DECLARE @userID INT
	SET @userID = 0
	--
	SELECT
		@userID = ID
	FROM
		T_Users
	WHERE
		U_PRN = @PRN
	--
	IF @userID = 0
	BEGIN
		SET @myError = 52
		SET @message = 'User "' + @PRN + '" is not valid'
		GOTO Done
	END

	---------------------------------------------------
	-- is user already an observer?
	---------------------------------------------------
	--
	DECLARE @membershipExists TINYINT
	--
	SELECT
		@membershipExists = COUNT(*)
	FROM
		T_Research_Team_Membership
	WHERE
		Team_ID = @researchTeamID
		AND Role_ID = @observerRoleID
		AND User_ID = @userID
		
	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	IF @membershipExists > 0 AND @mode = 'remove'
	BEGIN
		DELETE FROM
			T_Research_Team_Membership
		WHERE
			Team_ID = @researchTeamID
			AND Role_ID = @observerRoleID
			AND User_ID = @userID
	END 

	IF @membershipExists = 0 AND @mode = 'add'
	BEGIN
	  INSERT  INTO dbo.T_Research_Team_Membership
			  ( Team_ID,
				Role_ID,
				User_ID 
			  )
	  VALUES
			  ( @researchTeamID,
				@observerRoleID,
				@userID
			  )
	END 
	
	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
Done:
	return @myError

GO
