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
**			10/27/2011 mem - Added parameter @FractionEMSLFunded
**			12/01/2011 mem - Updated @FractionEMSLFunded to be a required value
**			               - Now calling AlterEventLogEntryUser for updates to CM_Fraction_EMSL_Funded or CM_Data_Release_Restrictions
**			10/23/2012 mem - Now validating that @FractionEMSLFunded is a number between 0 and 1 using a real (since conversion of 100 to Decimal(3, 2) causes an overflow error)
**			06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**			02/23/2016 mem - Add set XACT_ABORT on\
**			02/26/2016 mem - Define a default for @FractionEMSLFunded
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/20/2016 mem - Tweak error messages
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
	@FractionEMSLFunded varchar(24) = '0',
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
   	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	
	declare @StateID int
	declare @PercentEMSLFunded int

	-- Leave this as Null for now
	declare @FractionEMSLFundedValue decimal(3, 2) = 0
	
	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@campaignNum) < 1
		RAISERROR ('campaign name was blank', 11, 1)
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
		RAISERROR ('Could not resolve data release restriction; please select a valid entry from the list', 11, 7)

	---------------------------------------------------
	-- Validate Fraction EMSL Funded
	-- If @FractionEMSLFunded is empty we treat it as a Null value
	---------------------------------------------------
	--
	
	Set @FractionEMSLFunded = IsNull(@FractionEMSLFunded, '')
	If Len(@FractionEMSLFunded) > 0
	Begin
		Set @FractionEMSLFundedValue = Try_Convert(real, @FractionEMSLFunded)
		If @FractionEMSLFundedValue Is Null
		Begin
			RAISERROR ('Fraction EMSL Funded must be a number between 0 and 1', 11, 4)
		End
	
		If @FractionEMSLFundedValue > 1
		Begin
			Set @msg = 'Fraction EMSL Funded must be a number between 0 and 1 (' + @FractionEMSLFunded + ' is greater than 1)'
			RAISERROR (@msg, 11, 4)
		End

		If @FractionEMSLFundedValue < 0
		Begin
			Set @msg = 'Fraction EMSL Funded must be a number between 0 and 1 (' + @FractionEMSLFunded + ' is less than 0)'
			RAISERROR (@msg, 11, 4)
		End
		
		Set @FractionEMSLFundedValue = Convert(decimal(3, 2), @FractionEMSLFunded)

	End
	Else
		RAISERROR ('Fraction EMSL Funded must be a number between 0 and 1', 11, 4)
	
	
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
			CM_Data_Release_Restrictions,
			CM_Fraction_EMSL_Funded
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
			@DataReleaseRestrictionsID,
			@FractionEMSLFundedValue
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed: "%s"', 11, 12, @campaignNum )
		
		-- This method is more accurate than using IDENT_CURRENT
		Set @CampaignID = SCOPE_IDENTITY()		

		-- As a precaution, query T_Campaign using Campaign name to make sure we have the correct Campaign_ID
		Declare @IDConfirm int = 0
		
		SELECT @IDConfirm = Campaign_ID
		FROM T_Campaign
		WHERE Campaign_Num = @campaignNum
		
		If @CampaignID <> IsNull(@IDConfirm, @CampaignID)
		Begin
			Declare @DebugMsg varchar(512)
			Set @DebugMsg = 'Warning: Inconsistent identity values when adding campaign ' + @campaignNum + ': Found ID ' +
			                Cast(@IDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' + 
			                Cast(@CampaignID as varchar(12))
			                
			exec postlogentry 'Error', @DebugMsg, 'AddUpdateCampaign'
			
			Set @CampaignID = @IDConfirm
		End
		

		commit transaction @transName
		
		set @StateID = 1
		set @PercentEMSLFunded = CONVERT(int, @FractionEMSLFundedValue * 100)
		
		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
		Begin
			Exec AlterEventLogEntryUser 1, @CampaignID, @StateID, @callingUser
			Exec AlterEventLogEntryUser 9, @CampaignID, @PercentEMSLFunded, @callingUser
			Exec AlterEventLogEntryUser 10, @CampaignID, @DataReleaseRestrictionsID, @callingUser
		End
			
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
			CM_Data_Release_Restrictions = @DataReleaseRestrictionsID,
			CM_Fraction_EMSL_Funded = @FractionEMSLFundedValue
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
		
		set @PercentEMSLFunded = CONVERT(int, @FractionEMSLFundedValue * 100)
		
		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
		Begin
			Exec AlterEventLogEntryUser 9, @CampaignID, @PercentEMSLFunded, @callingUser
			Exec AlterEventLogEntryUser 10, @CampaignID, @DataReleaseRestrictionsID, @callingUser
		End
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
