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
**			05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @ownerPRN and @piPRN contain a person's real name rather than their username
**			08/19/2010 grk - try-catch for error handling
**			11/15/2012 mem - Renamed parameter @ownerPRN to @contactPRN; renamed column CC_Owner_PRN to CC_Contact_PRN
**						   - Added new fields to support peptide standards
**			06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/20/2016 mem - Fix spelling in error messages
**			11/18/2016 mem - Log try/catch errors using PostLogEntry
**    
*****************************************************/
(
	@cellCultureName varchar(64),	-- Name of biomaterial or peptide sequence if tracking an MRM peptide
	@sourceName varchar(64), 		-- Source that the material came from; can be a person (onsite or offsite) or a company
	@contactPRN varchar(64),	    -- Contact for the Source; typically PNNL staff, but can be offsite person
	@piPRN varchar(32), 			-- Project lead
	@cultureType varchar(32), 
	@reason varchar(500),
	@comment varchar(500),
	@campaignNum varchar(64), 
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@container varchar(128) = 'na', 
	@geneName varchar(128),
	@geneLocation varchar(128),
	@modCount varchar(20)	,		-- Will be converted to a Smallint
	@modifications varchar(500),
	@mass          varchar(30),		-- Will be converted to a float
	@purchaseDate  varchar(30),		-- Will be converted to a date
	@peptidePurity varchar(64),
	@purchaseQuantity varchar(128),
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

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @callingUser = IsNull(@callingUser, '')

	set @myError = 0
	if LEN(@campaignNum) < 1
	begin
		RAISERROR ('Campaign Name was blank', 11, 1)
	end	
	if LEN(@contactPRN) < 1
	begin
		RAISERROR ('Contact Name was blank', 11, 3)
	end
	--
	if LEN(@piPRN) < 1
	begin
		RAISERROR ('Principle Investigator PRN was blank', 11, 3)
	end
	--
	if LEN(@cellCultureName) < 1
	begin
		RAISERROR ('Cell Culture Name was blank', 11, 4)
	end
	--
	if LEN(@sourceName) < 1
	begin
		RAISERROR ('Source Name was blank', 11, 5)
	end
	--
	if LEN(@cultureType) < 1
	begin
		set @myError = 51001
		RAISERROR ('Culture Type was blank', 11, 6)
	end
	--
	if LEN(@reason) < 1
	begin
		RAISERROR ('Reason was blank', 11, 7)
	end
	--
	if LEN(@campaignNum) < 1
	begin
		RAISERROR ('Campaign Name was blank', 11, 8)
	end

	Declare @modCountValue smallint
	Declare @massValue float
	Declare @purchaseDateValue datetime
			
	Set @modCount = ISNULL(@modCount, '')
	If @modCount = ''
		Set @modCountValue = 0
	Else
	Begin
		Set @modCountValue = Try_Convert(smallint, @modCount)
		If @modCountValue Is Null
			RAISERROR ('Error, non-numeric modification count: %s', 11, 9, @modCount)
	End	
	
	Set @mass = ISNULL(@mass, '')
	If @mass = ''
		Set @massValue = 0
	Else
	Begin
		Set @massValue = Try_Convert(smallint, @mass)
		If @modCountValue Is Null
			RAISERROR ('Error, non-numeric mass: %s', 11, 9, @mass)
	End
	
	Set @purchaseDate = ISNULL(@purchaseDate, '')
	If @purchaseDate = ''
		Set @purchaseDateValue = null
	Else
	Begin
		If IsDate(@purchaseDate) = 1
			Set @purchaseDateValue = CONVERT(datetime, @purchaseDate)
		Else
			RAISERROR ('Error, invalid purchase date: %s', 11, 9, @purchaseDate)
	End		
	
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
		RAISERROR (@msg, 11, 10)
	end

	-- cannot create an entry that already exists
	--
	if @cellCultureID <> 0 and (@mode = 'add' or @mode = 'check_add')
	begin
		set @msg = 'Cannot add: Cell Culture "' + @cellCultureName + '" already in database '
		RAISERROR (@msg, 11, 11)
	end

	-- cannot update a non-existent entry
	--
	if @cellCultureID = 0 and (@mode = 'update' or @mode = 'check_update')
	begin
		set @msg = 'Cannot update: Cell Culture "' + @cellCultureName + '" is not in database '
		RAISERROR (@msg, 11, 12)
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
		set @msg = 'Could not resolve campaign name "' + @campaignNum + '" to ID"'
		RAISERROR (@msg, 11, 13)
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
		set @msg = 'Could not resolve type name "' + @cultureType + '" to ID'
		RAISERROR (@msg, 11, 14)
	end

	---------------------------------------------------
	-- Resolve container name to ID
	---------------------------------------------------

	declare @contID int
	set @contID = 0
	--
	If ISNULL(@container, '') = ''
		Set @container = 'na'

	SELECT @contID = ID
	FROM         T_Material_Containers
	WHERE     (Tag = @container)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Could not resolve container name "' + @container + '" to ID'
		RAISERROR (@msg, 11, 15)
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
		RAISERROR (@msg, 11, 16)
	end

	---------------------------------------------------
	-- Resolve DPRNs to user number
	---------------------------------------------------

	-- verify that Owner PRN  is valid 
	-- and get its id number
	--
	declare @userID int

	Declare @MatchCount int
	Declare @NewPRN varchar(64)

	execute @userID = GetUserID @contactPRN
	if @userID = 0
	begin
		-- Could not find entry in database for PRN @contactPRN
		-- Try to auto-resolve the name
		
		exec AutoResolveNameToPRN @contactPRN, @MatchCount output, @NewPRN output, @userID output

		If @MatchCount = 1
		Begin
			-- Single match found; update @contactPRN
			Set @contactPRN = @NewPRN
		End
		
	end

	-- verify that principle investigator PRN is valid 
	-- and get its id number
	--
	execute @userID = GetUserID @piPRN
	if @userID = 0
	begin
		---------------------------------------------------
		-- @piPRN did not resolve to a User_ID
		-- In case a name was entered (instead of a PRN),
		--  try to auto-resolve using the U_Name column in T_Users
		---------------------------------------------------

		exec AutoResolveNameToPRN @piPRN, @MatchCount output, @NewPRN output, @userID output
					
		If @MatchCount = 1
		Begin
			-- Single match was found; update @piPRN
			Set @piPRN = @NewPRN
		End
		Else
		Begin
			set @msg = 'Could not find entry in database for principle investigator PRN "' + @piPRN + '"'
			RAISERROR (@msg, 11, 17)
		End
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		INSERT INTO T_Cell_Culture (
			CC_Name, 
			CC_Source_Name, 
			CC_Contact_PRN, 
			CC_PI_PRN, 
			CC_Type, 
			CC_Reason, 
			CC_Comment, 
			CC_Campaign_ID,
			CC_Container_ID,
			Gene_Name        ,
			Gene_Location    ,
			Mod_Count        ,
			Modifications    ,
			Mass             ,
			Purchase_Date    ,
			Peptide_Purity   ,
			Purchase_Quantity,			
			CC_Created
		) VALUES (
			@cellCultureName,
			@sourceName,
			@contactPRN,
			@piPRN,
			@typeID,
			@reason,
			@comment,
			@campaignID,
			@contID,
			@geneName,
			@geneLocation,
			@modCountValue,
			@modifications,
			@massValue,
			@purchaseDateValue,
			@peptidePurity,
			@purchaseQuantity,			
			GETDATE()			
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @cellCultureName + '"'
			RAISERROR (@msg, 11, 18)
		end

		set @cellCultureID = SCOPE_IDENTITY()
		
		-- As a precaution, query T_Cell_Culture using Cell Culture name to make sure we have the correct CC_ID
		Declare @IDConfirm int = 0
		
		SELECT @IDConfirm = CC_ID
		FROM T_Cell_Culture
		WHERE CC_Name = @cellCultureName
		
		If @cellCultureID <> IsNull(@IDConfirm, @cellCultureID)
		Begin
			Declare @DebugMsg varchar(512)
			Set @DebugMsg = 'Warning: Inconsistent identity values when adding cell culture ' + @cellCultureName + ': Found ID ' +
			                Cast(@IDConfirm as varchar(12)) + ' but SCOPE_IDENTITY reported ' + 
			                Cast(@cellCultureID as varchar(12))
			                
			exec postlogentry 'Error', @DebugMsg, 'AddUpdateCellCulture'
			
			Set @cellCultureID = @IDConfirm
		End		
		
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
			CC_Source_Name    = @sourceName, 
			CC_Contact_PRN    = @contactPRN, 
			CC_PI_PRN         = @piPRN, 
			CC_Type           = @typeID, 
			CC_Reason         = @reason, 
			CC_Comment        = @comment, 
			CC_Campaign_ID    = @campaignID,
			CC_Container_ID   = @contID,
			Gene_Name         = @geneName,
			Gene_Location     = @geneLocation,
			Mod_Count         = @modCountValue,
			Modifications     = @modifications,
			Mass              = @massValue,
			Purchase_Date     = @purchaseDateValue,
			Peptide_Purity    = @peptidePurity,
			Purchase_Quantity = @purchaseQuantity
		WHERE (CC_Name = @cellCultureName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Update operation failed: "' + @cellCultureName + '"'
			RAISERROR (@msg, 11, 19)
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

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		exec PostLogEntry 'Error', @message, 'AddUpdateCellCulture'
	END CATCH
	return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdateCellCulture] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateCellCulture] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCellCulture] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCellCulture] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateCellCulture] TO [PNL\D3M580] AS [dbo]
GO
