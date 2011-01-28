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
**			04/21/2010 grk - try-catch for error handling
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

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@campaignNum) < 1
		RAISERROR ('campaign Number was blank', 11, 1)
	--
	if LEN(@projectNum) < 1
		RAISERROR ('Project Number was blank', 11, 1)
	--
	if LEN(@progmgrPRN) < 1
		RAISERROR ('Program Manager PRN was blank', 11, 2)
	--
	if LEN(@piPRN) < 1
		RAISERROR ('Principle Investigator PRN was blank', 11, 3)

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
		RAISERROR ('Cannot add: Campaign "%s" already in database', 11, 4, @campaignNum)

	-- cannot update a non-existent entry
	--
	if @campaignID = 0 and @mode = 'update'
		RAISERROR ('Cannot update: Campaign "%s" is not in database', 11, 5, @campaignNum)

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
		RAISERROR ('Error resolving data release restriction', 11, 6)
	--
	if @DataReleaseRestrictionsID < 0
		RAISERROR ('Could not resolve data release restriction', 11, 7)

	---------------------------------------------------
	-- transaction name
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'AddUpdateCampaign'

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
				RAISERROR ('Campaign name may not contain spaces', 11, 8)
			Else
				RAISERROR ('Campaign name may not contain the character(s) "%s"', 11, 9, @badCh)
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
			RAISERROR (@message, 11, 11)

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
			RAISERROR ('Insert operation failed: "%s"', 11, 12,@campaignNum )
		
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
			RAISERROR ('Update operation failed: "%s"', 11, 14, @campaignNum)

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
			RAISERROR (@message, 11, 1)

		commit transaction @transName
	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateCampaign] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateCampaign] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCampaign] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCampaign] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCampaign] TO [PNL\D3M580] AS [dbo]
GO
