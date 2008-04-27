/****** Object:  StoredProcedure [dbo].[AddUpdateCampaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateCampaign
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

**    
*****************************************************/
(
	@campaignNum varchar(64), 
	@projectNum varchar(64), 
	@progmgrPRN varchar(64), 
	@piPRN varchar(32), 
	@comment varchar(500),
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
--	else
--	begin
--		exec @myError = ValidateCharacterSet @campaignNum, @msg output, ' '
--		if @myError <> 0
--		begin
--			set @myError = 51010
--			set @msg = 'Campaign number not acceptable: ' + @msg
--			RAISERROR (@msg, 10, 1)
--		end
--	end



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
	execute @campaignID = GetCampaignID @campaignNum

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

	---------------------------------------------------
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

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_Campaign (
			Campaign_Num, 
			CM_Project_Num, 
			CM_Proj_Mgr_PRN, 
			CM_PI_PRN, 
			CM_comment, 
			CM_created
		) VALUES (
			@campaignNum, 
			@projectNum, 
			@progmgrPRN, 
			@piPRN, 
			@comment, 
			GETDATE()
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @campaignNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		
		set @CampaignID = IDENT_CURRENT('T_Campaign')
		
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
		set @myError = 0
		--
		UPDATE T_Campaign 
		SET 
			CM_Project_Num = @projectNum, 
			CM_Proj_Mgr_PRN = @progmgrPRN, 
			CM_PI_PRN = @piPRN, 
			CM_comment = @comment 
		WHERE (Campaign_Num = @campaignNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @campaignNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateCampaign] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[AddUpdateCampaign] TO [DMS2_SP_User]
GO
