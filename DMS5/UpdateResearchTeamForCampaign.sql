/****** Object:  StoredProcedure [dbo].[UpdateResearchTeamForCampaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateResearchTeamForCampaign]
/****************************************************
**
**	Desc:
**    Updates membership of research team for given
**    campaign
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	02/05/2010
**			02/07/2010 mem - Added code to try to auto-resolve cases where a team member's name was entered instead of a username (PRN)
**                         - Since a Like clause is used, % characters in the name will be treated as wildcards
**                         - However, "anderson, gordon" will be split into two entries: "anderson" and "gordon" when MakeTableFromList is called
**                         - Thus, use "anderson%gordon" to match the "anderson, gordon" entry in T_Users
**			09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@campaignNum varchar(64), 
	@progmgrPRN varchar(64), 
	@piPRN varchar(64), 
	@TechnicalLead varchar(256),
	@SamplePreparationStaff varchar(256),
	@DatasetAcquisitionStaff varchar(256),
	@InformaticsStaff varchar(256),
	@Collaborators varchar(256),
	@researchTeamID int output,
	@message varchar(512) output
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	Declare @EntryID int
	Declare @continue tinyint
	
	Declare @MatchCount int
	Declare @UnknownPRN varchar(64)
	Declare @NewPRN varchar(64)
	Declare @NewUserID int
	
	---------------------------------------------------
	-- update research team if ID is given,
	-- make new one if not
	---------------------------------------------------

	-- update existing research team
	IF @researchTeamID <> 0 
	BEGIN
		UPDATE dbo.T_Research_Team
			SET Collaborators = @Collaborators
		WHERE
			ID = @researchTeamID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error updating research team fields'
			GOTO Done
		end
	END

	-- make new research team
	IF @researchTeamID = 0 
	BEGIN
		INSERT INTO T_Research_Team (
			Team,
			Description,
			Collaborators
		) VALUES (
			@campaignNum,
			'Research team for campaign ' + @campaignNum,
			@Collaborators
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error creating new research team'
			GOTO Done
		end
		--
		SET @researchTeamID = IDENT_CURRENT('T_Research_Team')
	END

	IF @researchTeamID = 0 
	begin
		set @message = 'Research team ID was not valid'
		GOTO Done
	end

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
	INSERT  INTO #Tmp_TeamMembers ( User_PRN, [Role] )
	SELECT Item AS User_PRN, 'Project Mgr' AS [Role]
	FROM dbo.MakeTableFromList(@progmgrPRN) AS member
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary membership table for Project Mgr'
		GOTO Done
	end
	--
	INSERT  INTO #Tmp_TeamMembers ( User_PRN, [Role] )
	SELECT Item AS User_PRN, 'PI' AS [Role]
	FROM dbo.MakeTableFromList(@piPRN) AS member
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary membership table for PI'
		GOTO Done
	end
	--
	INSERT  INTO #Tmp_TeamMembers ( User_PRN, [Role] )
	SELECT Item AS User_PRN, 'Technical Lead' AS [Role]
	FROM dbo.MakeTableFromList(@TechnicalLead) AS member
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary membership table for Technical Lead'
		GOTO Done
	end
	--
	INSERT  INTO #Tmp_TeamMembers ( User_PRN, [Role] )
	SELECT Item AS User_PRN, 'Sample Preparation' AS [Role]
	FROM dbo.MakeTableFromList(@SamplePreparationStaff) AS member
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary membership table for Sample Preparation'
		GOTO Done
	end
	--
	INSERT  INTO #Tmp_TeamMembers ( User_PRN, [Role] )
	SELECT Item AS User_PRN, 'Dataset Acquisition' AS [Role]
	FROM dbo.MakeTableFromList(@DatasetAcquisitionStaff) AS member
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary membership table for Dataset Acquisition'
		GOTO Done
	end
	--
	INSERT  INTO #Tmp_TeamMembers ( User_PRN, [Role] )
	SELECT Item AS User_PRN, 'Informatics' AS [Role]
	FROM dbo.MakeTableFromList(@InformaticsStaff) AS member
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary membership table for Informatics'
		GOTO Done
	end
	--
	---------------------------------------------------
	-- resolve user PRN and role to respective IDs
	---------------------------------------------------
	--
	UPDATE #Tmp_TeamMembers
	SET
		[User_ID] = dbo.T_Users.ID
	FROM
		#Tmp_TeamMembers
		INNER JOIN dbo.T_Users ON #Tmp_TeamMembers.User_PRN = dbo.T_Users.U_PRN
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving user ID'
		GOTO Done
	end

	UPDATE #Tmp_TeamMembers
	SET
		Role_ID = T_Research_Team_Roles.ID
	FROM
		#Tmp_TeamMembers
		INNER JOIN dbo.T_Research_Team_Roles ON T_Research_Team_Roles.Role = #Tmp_TeamMembers.Role
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving role ID'
		GOTO Done
	end

	---------------------------------------------------
	-- Look for entries in #Tmp_TeamMembers where User_PRN did not resolve to a User_ID
	-- In case a name was entered (instead of a PRN), try-to auto-resolve using the U_Name column in T_Users
	---------------------------------------------------
	
	Set @EntryID = 0
	Set @continue = 1
	
	While @Continue = 1
	Begin
		SELECT TOP 1 @EntryID = EntryID,
		             @UnknownPRN = User_PRN
		FROM #Tmp_TeamMembers
		WHERE EntryID > @EntryID AND [USER_ID] IS NULL
		ORDER BY EntryID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
			Set @Continue = 0
		Else
		Begin
			Set @MatchCount = 0
			
			exec AutoResolveNameToPRN @UnknownPRN, @MatchCount output, @NewPRN output, @NewUserID output
						
			If @MatchCount = 1
			Begin
				-- Single match was found; update User_PRN in #Tmp_TeamMembers
				UPDATE #Tmp_TeamMembers
				SET User_PRN = @NewPRN,
					[User_ID] = @NewUserID
				WHERE EntryID = @EntryID

			End
		End
		
	End
	
	---------------------------------------------------
	-- error if any PRN or role did not resolve to ID
	---------------------------------------------------
	--
	DECLARE @list VARCHAR(512)
	SET @list = ''
	--
	SELECT
		@list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + User_PRN 
	FROM
		#Tmp_TeamMembers
	WHERE
		[USER_ID] IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking for unresolved user ID'
		GOTO Done
	end
	--
	IF @list <> ''
	begin
		set @message = 'Could not resolve following payroll numbers to ID: ' + @list
		set @myError = 51000
		GOTO Done
	end



	SET @list = ''
	--
	SELECT
		@list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + [Role] 
	FROM ( SELECT DISTINCT [Role]
	       FROM #Tmp_TeamMembers
	       WHERE Role_ID IS NULL 
	     ) LookupQ
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking for unresolved role ID'
		GOTO Done
	end
	--
	IF @list <> ''
	begin
		set @message = 'Unknown role names: ' + @list
		set @myError = 51001
		GOTO Done
	end
	
 
	---------------------------------------------------
	-- clean out any existing membership
	---------------------------------------------------
	--
	DELETE FROM
		T_Research_Team_Membership
	WHERE
		Team_ID = @researchTeamID
		AND Role_ID BETWEEN 1 AND 6 -- restrict to roles that are editable via campaign
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error removing existing team membershipe'
		GOTO Done
	end

 	---------------------------------------------------
	-- replace with new membership
	---------------------------------------------------
	--
	INSERT INTO T_Research_Team_Membership
		(Team_ID, Role_ID, User_ID)
	SELECT 
		@researchTeamID, Role_ID, USER_ID 
	FROM 
		#Tmp_TeamMembers
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error adding new membership'
		return @myError
	end

Done:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512) = ''
	Set @UsageMessage = 'Campaign: ' + @campaignNum
	Exec PostUsageLogEntry 'UpdateResearchTeamForCampaign', @UsageMessage

	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[UpdateResearchTeamForCampaign] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateResearchTeamForCampaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateResearchTeamForCampaign] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateResearchTeamForCampaign] TO [PNL\D3M578] AS [dbo]
GO
