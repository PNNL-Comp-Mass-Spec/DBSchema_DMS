/****** Object:  StoredProcedure [dbo].[UpdateResearchTeamForCampaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateResearchTeamForCampaign]
/****************************************************
**
**  Desc:   Updates membership of research team for given campaign
**
**  Auth:   grk
**  Date:   02/05/2010 grk - Initial version
**          02/07/2010 mem - Added code to try to auto-resolve cases where a team member's name was entered instead of a username (PRN)
**                         - Since a Like clause is used, % characters in the name will be treated as wildcards
**                         - However, "anderson, gordon" will be split into two entries: "anderson" and "gordon" when MakeTableFromList is called
**                         - Thus, use "anderson%gordon" to match the "anderson, gordon" entry in T_Users
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/22/2017 mem - Validate @campaignNum
**          08/20/2021 mem - Use Select Distinct to avoid duplicates
**          02/17/2022 mem - Update error message and convert tabs to spaces
**
*****************************************************/
(
    @campaignNum varchar(64),               -- Campaign name (required if @researchTeamID is 0)
    @progmgrPRN varchar(64),                -- Project Manager PRN (required)
    @piPRN varchar(64),                     -- Principal Investigator PRN (required)
    @technicalLead varchar(256),            -- Technical Lead
    @samplePreparationStaff varchar(256),   -- Sample Prep Staff
    @datasetAcquisitionStaff varchar(256),  -- Dataset acquisition staff
    @informaticsStaff varchar(256),         -- Informatics staff
    @collaborators varchar(256),            -- Collaborators
    @researchTeamID int output,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    Declare @entryID int
    Declare @continue tinyint

    Declare @matchCount int
    Declare @unknownPRN varchar(64)
    Declare @newPRN varchar(64)
    Declare @newUserID int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateResearchTeamForCampaign', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @campaignNum = IsNull(@campaignNum, '')

    ---------------------------------------------------
    -- Make new research team if ID is 0
    ---------------------------------------------------

    If @researchTeamID = 0
    Begin
        If @campaignNum = ''
        Begin
            Set @myerror = 51002
            set @message = 'Campaign name is blank; cannot create a new research team'
            GOTO Done
        End

        INSERT INTO T_Research_Team (
            Team,
            Description,
            Collaborators
        ) VALUES (
            @campaignNum,
            'Research team for campaign ' + @campaignNum,
            @collaborators
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            set @message = 'Error creating new research team'
            GOTO Done
        End
        --
        SET @researchTeamID = SCOPE_IDENTITY()
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
        if @myError <> 0
        Begin
            set @message = 'Error updating collaborators'
            GOTO Done
        End
    End

    If @researchTeamID = 0
    Begin
        set @message = 'Research team ID was not valid'
        GOTO Done
    End

    ---------------------------------------------------
    -- temp table to hold new membership for team
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_TeamMembers (
        User_PRN VARCHAR(24),
        [Role] VARCHAR(128),
        Role_ID INT null,
        [USER_ID] INT null,
        EntryID int Identity(1,1)
    )

    ---------------------------------------------------
    -- populate temp membership table from lists
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_TeamMembers ( User_PRN, [Role] )
    SELECT DISTINCT Item AS User_PRN, 'Project Mgr' AS [Role]
    FROM dbo.MakeTableFromList(@progmgrPRN) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error populating temporary membership table for Project Mgr'
        GOTO Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( User_PRN, [Role] )
    SELECT DISTINCT Item AS User_PRN, 'PI' AS [Role]
    FROM dbo.MakeTableFromList(@piPRN) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error populating temporary membership table for PI'
        GOTO Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( User_PRN, [Role] )
    SELECT DISTINCT Item AS User_PRN, 'Technical Lead' AS [Role]
    FROM dbo.MakeTableFromList(@technicalLead) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error populating temporary membership table for Technical Lead'
        GOTO Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( User_PRN, [Role] )
    SELECT DISTINCT Item AS User_PRN, 'Sample Preparation' AS [Role]
    FROM dbo.MakeTableFromList(@samplePreparationStaff) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error populating temporary membership table for Sample Preparation'
        GOTO Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( User_PRN, [Role] )
    SELECT DISTINCT Item AS User_PRN, 'Dataset Acquisition' AS [Role]
    FROM dbo.MakeTableFromList(@datasetAcquisitionStaff) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error populating temporary membership table for Dataset Acquisition'
        GOTO Done
    End
    --
    INSERT INTO #Tmp_TeamMembers ( User_PRN, [Role] )
    SELECT DISTINCT Item AS User_PRN, 'Informatics' AS [Role]
    FROM dbo.MakeTableFromList(@informaticsStaff) AS member
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error populating temporary membership table for Informatics'
        GOTO Done
    End

    ---------------------------------------------------
    -- Resolve user PRN and role to respective IDs
    ---------------------------------------------------
    --
    UPDATE #Tmp_TeamMembers
    SET [User_ID] = dbo.T_Users.ID
    FROM #Tmp_TeamMembers
         INNER JOIN dbo.T_Users
           ON #Tmp_TeamMembers.User_PRN = dbo.T_Users.U_PRN
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error resolving user ID'
        GOTO Done
    End

    UPDATE #Tmp_TeamMembers
    SET
        Role_ID = T_Research_Team_Roles.ID
    FROM
        #Tmp_TeamMembers
        INNER JOIN dbo.T_Research_Team_Roles ON T_Research_Team_Roles.Role = #Tmp_TeamMembers.Role
    --
    UPDATE #Tmp_TeamMembers
    SET Role_ID = T_Research_Team_Roles.ID
    FROM #Tmp_TeamMembers
         INNER JOIN dbo.T_Research_Team_Roles
           ON T_Research_Team_Roles.ROLE = #Tmp_TeamMembers.ROLE
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error resolving role ID'
        GOTO Done
    End

    ---------------------------------------------------
    -- Look for entries in #Tmp_TeamMembers where User_PRN did not resolve to a User_ID
    -- In case a name was entered (instead of a PRN), try-to auto-resolve using the U_Name column in T_Users
    ---------------------------------------------------

    Set @entryID = 0
    Set @continue = 1

    While @continue = 1
    Begin
        SELECT TOP 1 @entryID = EntryID,
                     @unknownPRN = User_PRN
        FROM #Tmp_TeamMembers
        WHERE EntryID > @entryID AND [USER_ID] IS NULL
        ORDER BY EntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin
            Set @matchCount = 0

            exec AutoResolveNameToPRN @unknownPRN, @matchCount output, @newPRN output, @newUserID output

            If @matchCount = 1
            Begin
                -- Single match was found; update User_PRN in #Tmp_TeamMembers
                UPDATE #Tmp_TeamMembers
                SET User_PRN = @newPRN,
                    [User_ID] = @newUserID
                WHERE EntryID = @entryID

            End
        End

    End

    ---------------------------------------------------
    -- Error if any PRN or role did not resolve to ID
    ---------------------------------------------------
    --
    DECLARE @list VARCHAR(512) = ''
    --
    SELECT @list = @list + CASE
                               WHEN @list = '' THEN ''
                               ELSE ', '
                           END + User_PRN
    FROM #Tmp_TeamMembers
    WHERE [USER_ID] IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error checking for unresolved user ID'
        GOTO Done
    End
    --
    If @list <> ''
    Begin
        set @message = 'Could not resolve following usernames (or last names) to user ID: ' + @list
        set @myError = 51000
        GOTO Done
    End

    SET @list = ''
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
        set @message = 'Error checking for unresolved role ID'
        GOTO Done
    End
    --
    If @list <> ''
    Begin
        set @message = 'Unknown role names: ' + @list
        set @myError = 51001
        GOTO Done
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
        set @message = 'Error removing existing team membershipe'
        GOTO Done
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
        set @message = 'Error adding new membership'
        return @myError
    End

Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512) = ''
    Set @usageMessage = 'Campaign: ' + @campaignNum
    Exec PostUsageLogEntry 'UpdateResearchTeamForCampaign', @usageMessage

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateResearchTeamForCampaign] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateResearchTeamForCampaign] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateResearchTeamForCampaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateResearchTeamForCampaign] TO [Limited_Table_Write] AS [dbo]
GO
