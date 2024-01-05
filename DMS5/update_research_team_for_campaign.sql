/****** Object:  StoredProcedure [dbo].[update_research_team_for_campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_research_team_for_campaign]
/****************************************************
**
**  Desc:   Updates membership of research team for given campaign
**
**  Auth:   grk
**  Date:   02/05/2010 grk - Initial version
**          02/07/2010 mem - Added code to try to auto-resolve cases where a team member's name was entered instead of a username (PRN)
**                         - Since a Like clause is used, % characters in the name will be treated as wildcards
**                         - However, "anderson, gordon" will be split into two entries: "anderson" and "gordon" when make_table_from_list is called
**                         - Thus, use "anderson%gordon" to match the "anderson, gordon" entry in T_Users
**          09/02/2011 mem - Now calling post_usage_log_entry
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/22/2017 mem - Validate @campaignName
**          08/20/2021 mem - Use Select Distinct to avoid duplicates
**          02/17/2022 mem - Update error message and convert tabs to spaces
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          01/04/2024 mem - Remove duplicate update query
**
*****************************************************/
(
    @campaignName varchar(64),               -- Campaign name (required if @researchTeamID is 0)
    @progmgrUsername varchar(64),                -- Project Manager Username (required)
    @piUsername varchar(64),                     -- Principal Investigator Username (required)
    @technicalLead varchar(256),            -- Technical Lead
    @samplePreparationStaff varchar(256),   -- Sample Prep Staff
    @datasetAcquisitionStaff varchar(256),  -- Dataset acquisition staff
    @informaticsStaff varchar(256),         -- Informatics staff
    @collaborators varchar(256),            -- Collaborators
    @researchTeamID int output,
    @message varchar(512) output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @entryID int
    Declare @continue tinyint

    Declare @matchCount int
    Declare @unknownUsername varchar(64)
    Declare @newUsername varchar(64)
    Declare @newUserID int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_research_team_for_campaign', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @campaignName = IsNull(@campaignName, '')

    ---------------------------------------------------
    -- Make new research team if ID is 0
    ---------------------------------------------------

    If @researchTeamID = 0
    Begin
        If @campaignName = ''
        Begin
            Set @myerror = 51002
            Set @message = 'Campaign name was not specified; cannot create a new research team'
            Goto Done
        End

        INSERT INTO T_Research_Team (
            Team,
            Description,
            Collaborators
        ) VALUES (
            @campaignName,
            'Research team for campaign ' + @campaignName,
            @collaborators
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error creating new research team'
            Goto Done
        End
        --
        Set @researchTeamID = SCOPE_IDENTITY()
    End
    Else
    Begin
        -- Update Collaborators

        UPDATE dbo.T_Research_Team
        SET Collaborators = @collaborators
        WHERE ID = @researchTeamID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error updating collaborators'
            Goto Done
        End
    End

    If @researchTeamID = 0
    Begin
        Set @message = 'Research team ID was not valid'
        Goto Done
    End

    ---------------------------------------------------
    -- temp table to hold new membership for team
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_TeamMembers (
        Username VARCHAR(24),
        [Role] VARCHAR(128),
        Role_ID INT null,
        [User_ID] INT null,
        EntryID int Identity(1,1)
    )

    ---------------------------------------------------
    -- populate temp membership table from lists
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_TeamMembers ( Username, [Role] )
    SELECT DISTINCT Item AS Username, 'Project Mgr' AS [Role]
    FROM dbo.make_table_from_list(@progmgrUsername) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary membership table for Project Mgr'
        Goto Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( Username, [Role] )
    SELECT DISTINCT Item AS Username, 'PI' AS [Role]
    FROM dbo.make_table_from_list(@piUsername) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary membership table for PI'
        Goto Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( Username, [Role] )
    SELECT DISTINCT Item AS Username, 'Technical Lead' AS [Role]
    FROM dbo.make_table_from_list(@technicalLead) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary membership table for Technical Lead'
        Goto Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( Username, [Role] )
    SELECT DISTINCT Item AS Username, 'Sample Preparation' AS [Role]
    FROM dbo.make_table_from_list(@samplePreparationStaff) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary membership table for Sample Preparation'
        Goto Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( Username, [Role] )
    SELECT DISTINCT Item AS Username, 'Dataset Acquisition' AS [Role]
    FROM dbo.make_table_from_list(@datasetAcquisitionStaff) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary membership table for Dataset Acquisition'
        Goto Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( Username, [Role] )
    SELECT DISTINCT Item AS Username, 'Informatics' AS [Role]
    FROM dbo.make_table_from_list(@informaticsStaff) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary membership table for Informatics'
        Goto Done
    End

    ---------------------------------------------------
    -- Resolve user username and role to respective IDs
    ---------------------------------------------------

    UPDATE #Tmp_TeamMembers
    SET [User_ID] = dbo.T_Users.ID
    FROM #Tmp_TeamMembers
         INNER JOIN dbo.T_Users
           ON #Tmp_TeamMembers.Username = dbo.T_Users.U_PRN
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error resolving user ID'
        Goto Done
    End

    UPDATE #Tmp_TeamMembers
    SET Role_ID = T_Research_Team_Roles.ID
    FROM #Tmp_TeamMembers
        INNER JOIN dbo.T_Research_Team_Roles
          ON T_Research_Team_Roles.Role = #Tmp_TeamMembers.Role
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error resolving role ID'
        Goto Done
    End

    ---------------------------------------------------
    -- Look for entries in #Tmp_TeamMembers where Username did not resolve to a User_ID
    -- In case a name was entered (instead of a username), try-to auto-resolve using the U_Name column in T_Users
    ---------------------------------------------------

    Set @entryID = 0
    Set @continue = 1

    While @continue = 1
    Begin
        SELECT TOP 1 @entryID = EntryID,
                     @unknownUsername = Username
        FROM #Tmp_TeamMembers
        WHERE EntryID > @entryID AND [User_ID] IS NULL
        ORDER BY EntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin
            Set @matchCount = 0

            exec auto_resolve_name_to_username @unknownUsername, @matchCount output, @newUsername output, @newUserID output

            If @matchCount = 1
            Begin
                -- Single match was found; update Username in #Tmp_TeamMembers
                UPDATE #Tmp_TeamMembers
                SET Username = @newUsername,
                    [User_ID] = @newUserID
                WHERE EntryID = @entryID

            End
        End

    End

    ---------------------------------------------------
    -- Error if any username or role did not resolve to ID
    ---------------------------------------------------
    --
    Declare @list VARCHAR(512) = ''
    --
    SELECT @list = @list + CASE
                               WHEN @list = '' THEN ''
                               ELSE ', '
                           END + Username
    FROM #Tmp_TeamMembers
    WHERE [User_ID] IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error checking for unresolved user ID'
        Goto Done
    End
    --
    If @list <> ''
    Begin
        Set @message = 'Could not resolve following usernames (or last names) to user ID: ' + @list
        Set @myError = 51000
        Goto Done
    End

    Set @list = ''
    --
    SELECT @list = @list + CASE
                               WHEN @list = '' THEN ''
                               ELSE ', '
                           END + [Role]
    FROM ( SELECT DISTINCT [Role]
           FROM #Tmp_TeamMembers
           WHERE Role_ID IS NULL ) LookupQ
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error checking for unresolved role ID'
        Goto Done
    End
    --
    If @list <> ''
    Begin
        Set @message = 'Unknown role names: ' + @list
        Set @myError = 51001
        Goto Done
    End

    ---------------------------------------------------
    -- Clean out any existing membership
    ---------------------------------------------------
    --
    DELETE FROM T_Research_Team_Membership
    WHERE Team_ID = @researchTeamID AND
          Role_ID BETWEEN 1 AND 6 -- restrict to roles that are editable via campaign
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error removing existing team membership'
        Goto Done
    End

     ---------------------------------------------------
    -- Replace with new membership
    ---------------------------------------------------
    --
    INSERT INTO T_Research_Team_Membership( Team_ID,
                                            Role_ID,
                                            [User_ID] )
    SELECT DISTINCT @researchTeamID,
           Role_ID,
           [User_ID]
    FROM #Tmp_TeamMembers
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error adding new membership'
        Return @myError
    End

Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512) = ''
    Set @usageMessage = 'Campaign: ' + @campaignName
    Exec post_usage_log_entry 'update_research_team_for_campaign', @usageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_research_team_for_campaign] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_research_team_for_campaign] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_research_team_for_campaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_research_team_for_campaign] TO [Limited_Table_Write] AS [dbo]
GO
