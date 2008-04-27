/****** Object:  StoredProcedure [dbo].[AddUpdateCellCulture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateCellCulture
/****************************************************
**
**	Desc: Adds new or updates existing cell culture in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	03/12/2002
**			01/12/2007 grk - added verification mode
**			03/11/2008 grk - Added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter @callingUser
**			03/25/2008 mem - Now calling AlterEventLogEntryUser if @callingUser is not blank (Ticket #644)
**    
*****************************************************/
(
	@cellCultureName varchar(64), 
	@sourceName varchar(64), 
	@ownerPRN varchar(64), 
	@piPRN varchar(32), 
	@cultureType varchar(32), 
	@reason varchar(500),
	@comment varchar(500),
	@campaignNum varchar(64), 
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@container varchar(128) = 'na', 
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

	Set @callingUser = IsNull(@callingUser, '')

	set @myError = 0
	if LEN(@campaignNum) < 1
	begin
		set @myError = 51000
		RAISERROR ('campaign Number was blank',
			10, 1)
	end
	--
	if LEN(@ownerPRN) < 1
	begin
		set @myError = 51002
		RAISERROR ('Owner PRN was blank', 10, 1)
	end
	--
	if LEN(@piPRN) < 1
	begin
		set @myError = 51003
		RAISERROR ('Principle Investigator PRN was blank', 10, 1)
	end
	--
	if LEN(@cellCultureName) < 1
	begin
		set @myError = 51001
		RAISERROR ('Cell Culture Name was blank', 10, 1)
	end
	--
	if LEN(@sourceName) < 1
	begin
		set @myError = 51001
		RAISERROR ('Source Name was blank', 10, 1)
	end
	--
	if LEN(@cultureType) < 1
	begin
		set @myError = 51001
		RAISERROR ('Culture Type was blank', 10, 1)
	end
	--
	if LEN(@reason) < 1
	begin
		set @myError = 51001
		RAISERROR ('Reason was blank', 10, 1)
	end
	--
	if LEN(@campaignNum) < 1
	begin
		set @myError = 51001
		RAISERROR ('Campaign Num was blank', 10, 1)
	end
	--
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @cellCultureID int
	set @cellCultureID = 0
	--
	declare @curContainerID int
	set @curContainerID = 0
	--
	SELECT 
		@cellCultureID = CC_ID, 
		@curContainerID = CC_Container_ID
	FROM T_Cell_Culture 
	WHERE (CC_Name = @cellCultureName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to resolve cell culture ID'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	-- cannot create an entry that already exists
	--
	if @cellCultureID <> 0 and (@mode = 'add' or @mode = 'check_add')
	begin
		set @msg = 'Cannot add: Cell Culture "' + @cellCultureName + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @cellCultureID = 0 and (@mode = 'update' or @mode = 'check_update')
	begin
		set @msg = 'Cannot update: Cell Culture "' + @cellCultureName + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- Resolve campaign number to ID
	---------------------------------------------------

	declare @campaignID int
	set @campaignID = 0
	--
	execute @campaignID = GetCampaignID @campaignNum
	--
	if @campaignID = 0
	begin
		set @msg = 'Could not resolve campaign num "' + @campaignNum + '" to ID"'
		RAISERROR (@msg, 10, 1)
		return 51004
	end
	
	---------------------------------------------------
	-- Resolve type name to ID
	---------------------------------------------------

	declare @typeID int
	set @typeID = 0
	--
	SELECT @typeID = ID
	FROM T_Cell_Culture_Type_Name
	WHERE (Name = @cultureType)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not resove type name "' + @cultureType + '" to ID'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

	---------------------------------------------------
	-- Resolve container name to ID
	---------------------------------------------------

	declare @contID int
	set @contID = 0
	--
	SELECT @contID = ID
	FROM         T_Material_Containers
	WHERE     (Tag = @container)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not resove container name "' + @container + '" to ID'
		RAISERROR (@msg, 10, 1)
		return 510019
	end

	---------------------------------------------------
	-- Resolve current container id to name
	---------------------------------------------------
	declare @curContainerName varchar(125)
	set @curContainerName = ''
	--
	SELECT @curContainerName = Tag 
	FROM T_Material_Containers 
	WHERE ID = @curContainerID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error resolving name of current container'
		RAISERROR (@msg, 10, 1)
		return 510027
	end

	---------------------------------------------------
	-- Resolve DPRNs to user number
	---------------------------------------------------

	-- verify that Owner PRN  is valid 
	-- and get its id number
	--
	declare @userID int
/*
	execute @userID = GetUserID @ownerPRN
	if @userID = 0
	begin
		set @msg = 'Could not find entry in database for program mgr. PRN "' + @ownerPRN + '"'
		RAISERROR (@msg, 10, 1)
		return 51005
	end
*/
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
		INSERT INTO T_Cell_Culture (
			CC_Name, 
			CC_Source_Name, 
			CC_Owner_PRN, 
			CC_PI_PRN, 
			CC_Type, 
			CC_Reason, 
			CC_Comment, 
			CC_Campaign_ID,
			CC_Created,
			CC_Container_ID
		) VALUES (
			@cellCultureName,
			@sourceName,
			@ownerPRN,
			@piPRN,
			@typeID,
			@reason,
			@comment,
			@campaignID,
			GETDATE(),
			@contID
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @cellCultureName + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end

		set @cellCultureID = IDENT_CURRENT('T_Cell_Culture')
		
		declare @StateID int
		set @StateID = 1
		
		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 2, @cellCultureID, @StateID, @callingUser

		-- material movement logging
		-- 		
		if @curContainerID != @contID
		begin
			exec PostMaterialLogEntry
				'Biomaterial Move',
				@cellCultureName,
				'na',
				@container,
				@callingUser,
				'Biomaterial (Cell Culture) added'
		end

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Cell_Culture
		SET 
			CC_Source_Name = @sourceName, 
			CC_Owner_PRN = @ownerPRN, 
			CC_PI_PRN = @piPRN, 
			CC_Type = @typeID, 
			CC_Reason = @reason, 
			CC_Comment = @comment, 
			CC_Campaign_ID = @campaignID,
			CC_Container_ID = @contID
		WHERE (CC_Name = @cellCultureName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update operation failed: "' + @cellCultureName + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end

		-- material movement logging
		-- 		
		if @curContainerID != @contID
		begin
			exec PostMaterialLogEntry
				'Biomaterial Move',
				@cellCultureName,
				@curContainerName,
				@container,
				@callingUser,
				'Biomaterial (Cell Culture) updated'
		end

	end -- update mode


	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateCellCulture] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[AddUpdateCellCulture] TO [DMS2_SP_User]
GO
