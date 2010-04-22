/****** Object:  StoredProcedure [dbo].[AddUpdateCampaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateCampaign
/****************************************************
**
**	Desc: Adds new or updates existing campaign in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@campaignNum  unique name for the new campaign
**		@projectNum   project number of the new campaign 
**		@progmgrPRN	  program manager
**		@piPRN        principal investigator 
**		@comment
**	
**
**	Auth:	grk
**	Date:	01/08/2002
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			01/15/2010 grk - Added new fields (http://prismtrac.pnl.gov/trac/ticket/753)
**			02/05/2010 grk - Split team member field
**			02/07/2010 grk - Added validation for campaign name
**			02/07/2010 mem - No longer validating @progmgrPRN or @piPRN in this procedure since this is now handled by UpdateResearchTeamForCampaign
**			03/17/2010 grk - DataReleaseRestrictions (Ticket http://prismtrac.pnl.gov/trac/ticket/758)
**    
*****************************************************/
(
	@campaignNum varchar(64), 
	@projectNum varchar(64), 
	@progmgrPRN varchar(64), 
	@piPRN varchar(64), 
	@TechnicalLead VARCHAR(256),
	@SamplePreparationStaff varchar(256),
	@DatasetAcquisitionStaff varchar(256),
	@InformaticsStaff varchar(256),
	@Collaborators varchar(256),
	@comment varchar(500),
	@State varchar(24),
	@Description varchar(512),
	@ExternalLinks varchar(512),
	@EPRList varchar(256),
	@EUSProposalList varchar(256),
	@Organisms varchar(256),
	@ExperimentPrefixes varchar(256),
	@DataReleaseRestrictions varchar(128),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
   	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)


	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@campaignNum) < 1
	begin
		set @myError = 51000
		RAISERROR ('campaign Number was blank',
			10, 1)
	end

	if LEN(@projectNum) < 1
	begin
		set @myError = 51001
		RAISERROR ('Project Number was blank',
			10, 1)
	end
	--
	if LEN(@progmgrPRN) < 1
	begin
		set @myError = 51002
		RAISERROR ('Program Manager PRN was blank',
			10, 1)
	end
	--
	if LEN(@piPRN) < 1
	begin
		set @myError = 51003
		RAISERROR ('Principle Investigator PRN was blank',
			10, 1)
	end
	--
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

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

	-- cannot create an entry that already exists
	--
	if @campaignID <> 0 and @mode = 'add'
	begin
		set @msg = 'Cannot add: Campaign "' + @campaignNum + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @campaignID = 0 and @mode = 'update'
	begin
		set @msg = 'Cannot update: Campaign "' + @campaignNum + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end


/*
	---------------------------------------------------
	-- Skip this step since now handled by UpdateResearchTeamForCampaign
	-- Resolve DPRNs to user number
	---------------------------------------------------

	-- verify that program manager PRN  is valid 
	-- and get its id number
	--
	declare @userID int
	execute @userID = GetUserID @progmgrPRN
	if @userID = 0
	begin
		set @msg = 'Could not find entry in database for program mgr. PRN "' + @progmgrPRN + '"'
		RAISERROR (@msg, 10, 1)
		return 51005
	end

	-- verify that principle investigator PRN  is valid 
	-- and get its id number
	--
	execute @userID = GetUserID @piPRN
	if @userID = 0
	begin
		set @msg = 'Could not find entry in database for principle investigator PRN "' + @piPRN + '"'
		RAISERROR (@msg, 10, 1)
		return 51006
	end
*/

	---------------------------------------------------
	-- resolve data release restriction name to ID
	---------------------------------------------------
	--
	DECLARE @DataReleaseRestrictionsID INT
	SET @DataReleaseRestrictionsID = -1
	-- 
	SELECT
		@DataReleaseRestrictionsID = ID
	FROM
		T_Data_Release_Restrictions
	WHERE
		Name = @DataReleaseRestrictions
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error resolving data release restriction'
		RAISERROR (@msg, 10, 1)
		return 51001
	end
	if @DataReleaseRestrictionsID < 0
	begin
		set @msg = 'Could not resolve data release restriction'
		RAISERROR (@msg, 10, 1)
		return 51002
	end

	---------------------------------------------------
	-- transaction name
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'AddUpdateCampaign'

--SET @message = @campaignNum
--RETURN 0

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		---------------------------------------------------
		-- validate campaign name
		---------------------------------------------------
		--
		declare @badCh varchar(128)
		set @badCh =  dbo.ValidateChars(@campaignNum, '')
		SET @badCh = REPLACE(@badCh, '[space]', '') -- allow spaces?
		if @badCh <> ''
		begin
			If @badCh = '[space]'
				set @msg = 'Campaign name may not contain spaces'
			Else
				set @msg = 'Campaign name may not contain the character(s) "' + @badCh + '"'

			RAISERROR (@msg, 10, 1)
			return 51001
		end


		begin transaction @transName

		---------------------------------------------------
		-- create research team
		---------------------------------------------------
		--
		EXEC @myError = UpdateResearchTeamForCampaign
							@campaignNum, 
							@progmgrPRN , 
							@piPRN, 
							@TechnicalLead,
							@SamplePreparationStaff,
							@DatasetAcquisitionStaff,
							@InformaticsStaff,
							@Collaborators,
							@researchTeamID output,
							@message output
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			RAISERROR (@message, 10, 1)
			return @myError
		end

		---------------------------------------------------
		-- create campaign
		---------------------------------------------------
		--
		INSERT INTO T_Campaign (
			Campaign_Num, 
			CM_Project_Num, 
			CM_comment, 
			CM_State,
			CM_Description,
			CM_External_Links,
			CM_EPR_List,
			CM_EUS_Proposal_List,
			CM_Organisms,
			CM_Experiment_Prefixes,
			CM_created,
			CM_Research_Team,
			CM_Data_Release_Restrictions
		) VALUES (
			@campaignNum, 
			@projectNum, 
			@comment, 
			@State,
			@Description,
			@ExternalLinks,
			@EPRList,
			@EUSProposalList,
			@Organisms,
			@ExperimentPrefixes,
			GETDATE(),
			@researchTeamID,
			@DataReleaseRestrictionsID
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Insert operation failed: "' + @campaignNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		
		set @CampaignID = IDENT_CURRENT('T_Campaign')

		commit transaction @transName
		
		declare @StateID int
		set @StateID = 1
		
		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 1, @CampaignID, @StateID, @callingUser
			
	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		begin transaction @transName
		--
		set @myError = 0
		--
		---------------------------------------------------
		-- update campaign
		---------------------------------------------------
		--
		UPDATE T_Campaign 
		SET 
			CM_Project_Num = @projectNum, 
			CM_comment = @comment,
			CM_State = @State,
			CM_Description = @Description,
			CM_External_Links = @ExternalLinks,
			CM_EPR_List = @EPRList,
			CM_EUS_Proposal_List = @EUSProposalList,
			CM_Organisms = @Organisms,
			CM_Experiment_Prefixes = @ExperimentPrefixes,
			CM_Data_Release_Restrictions = @DataReleaseRestrictionsID
		WHERE (Campaign_Num = @campaignNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Update operation failed: "' + @campaignNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end

		---------------------------------------------------
		-- update research team membershipe
		---------------------------------------------------
		--
		EXEC @myError = UpdateResearchTeamForCampaign
							@campaignNum, 
							@progmgrPRN , 
							@piPRN, 
							@TechnicalLead,
							@SamplePreparationStaff,
							@DatasetAcquisitionStaff,
							@InformaticsStaff,
							@Collaborators,
							@researchTeamID output,
							@message output
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			RAISERROR (@message, 10, 1)
			return @myError
		end

		commit transaction @transName
	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateCampaign] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateCampaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCampaign] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCampaign] TO [PNL\D3M580] AS [dbo]
GO
