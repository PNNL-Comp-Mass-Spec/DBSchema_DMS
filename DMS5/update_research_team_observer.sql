/****** Object:  StoredProcedure [dbo].[update_research_team_observer] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_research_team_observer]
/****************************************************
**
**  Desc:
**  Sets user registration for notification entities
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/03/2010
**          04/03/2010 grk - initial release
**          04/04/2010 grk - callable as operatons_sproc
**          09/02/2011 mem - Now calling post_usage_log_entry
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/20/2021 mem - Reformat queries
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @campaignName varchar(64),
    @mode varchar(12) = 'add', -- or 'remove'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @observerRoleID int = 10

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_research_team_observer', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- user id
    ---------------------------------------------------
    --
    If @callingUser = ''
    Begin
        Set @myError = 50
        Set @message = 'User ID is missing'
        GOTO Done
    End
    --
    Declare @username varchar(15) = @callingUser

    ---------------------------------------------------
    -- Resolve
    ---------------------------------------------------
    --
    Declare @campaignID Int = 0
    --
    Declare @researchTeamID Int = 0
    --
    SELECT @campaignID = Campaign_ID,
           @researchTeamID = ISNULL(CM_Research_Team, 0)
    FROM T_Campaign
    WHERE Campaign_Num = @campaignName

    --
    If @campaignID = 0
    Begin
        Set @myError = 51
        Set @message = 'Campaign "' + @campaignName + '" is not valid'
        GOTO Done
    End

    ---------------------------------------------------
    -- Resolve
    ---------------------------------------------------
    --
    Declare @userID Int = 0
    --
    SELECT @userID = ID
    FROM T_Users
    WHERE U_PRN = @username
    --
    If @userID = 0
    Begin
        Set @myError = 52
        Set @message = 'User "' + @username + '" is not valid'
        GOTO Done
    End

    ---------------------------------------------------
    -- Is user already an observer?
    ---------------------------------------------------
    --
    Declare @membershipExists tinyint
    --
    SELECT @membershipExists = COUNT(*)
    FROM T_Research_Team_Membership
    WHERE Team_ID = @researchTeamID AND
          Role_ID = @observerRoleID AND
          User_ID = @userID

    ---------------------------------------------------
    -- Add / update the user
    ---------------------------------------------------
    --
    If @membershipExists > 0 AND @mode = 'remove'
    Begin
        DELETE FROM T_Research_Team_Membership
        WHERE Team_ID = @researchTeamID AND
              Role_ID = @observerRoleID AND
              User_ID = @userID
    End

    If @membershipExists = 0 AND @mode = 'add'
    Begin
      INSERT INTO dbo.T_Research_Team_Membership( Team_ID,
                                                  Role_ID,
                                                  User_ID )
      VALUES(@researchTeamID, @observerRoleID, @userID)
    End

Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512) = ''
    Set @UsageMessage = 'Campaign: ' + @campaignName + '; user: ' + @username + '; mode: ' + @mode
    Exec post_usage_log_entry 'update_research_team_observer', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_research_team_observer] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_research_team_observer] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_research_team_observer] TO [Limited_Table_Write] AS [dbo]
GO
