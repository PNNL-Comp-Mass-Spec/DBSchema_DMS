/****** Object:  StoredProcedure [dbo].[AddUpdateScripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateScripts
/****************************************************
**
**  Desc: Adds new or edits existing T_Scripts
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	09/23/2008 grk - Initial Veresion
**			03/24/2009 mem - Now calling AlterEnteredByUser when @callingUser is defined
**			10/06/2010 grk - Added @Parameters field
**			12/01/2011 mem - Expanded @Description to varchar(2000)
**			01/09/2012 mem - Added parameter @BackfillToDMS
						   - Changed ID field in T_Scripts to a non-identity based int
**			08/13/2013 mem - Added @Fields field  (used by MAC Job Wizard on DMS website)
**    
*****************************************************/
(
	@Script varchar(64),
	@Description varchar(2000),
	@Enabled char(1),
	@ResultsTag varchar(8),
	@BackfillToDMS char(1),
	@Contents TEXT,
	@Parameters TEXT,
	@Fields TEXT,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @ID int
	declare @BackFill tinyint
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @Description = IsNull(@Description, '')
	Set @Enabled = IsNull(@Enabled, 'Y')
	Set @BackfillToDMS = IsNull(@BackfillToDMS, 'Y')
	Set @mode = IsNull(@mode, '')
	Set @message = ''
	Set @callingUser = IsNull(@callingUser, '')

	If @BackfillToDMS = 'Y'
		Set @BackFill = 1
	Else
		Set @BackFill = 0
		
	If @Description = ''
	begin
		set @message = 'Description cannot be blank'
		RAISERROR (@message, 10, 1)
		return 51005
	End

	If @Mode <> 'add' and @mode <> 'update'
	Begin
		set @message = 'Unknown Mode: ' + @mode
		RAISERROR (@message, 10, 1)
		return 51006
	End
			
	---------------------------------------------------
	-- Is entry already in database? 
	---------------------------------------------------
	declare @tmp int
	set @tmp = 0
	--
	SELECT @tmp = ID
	FROM  T_Scripts
	WHERE Script = @Script
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error searching for existing entry'
		RAISERROR (@message, 10, 1)
		return 51007
	end

	-- cannot update a non-existent entry
	--
	if @mode = 'update' and @tmp = 0
	begin
		set @message = 'Could not find "' + @Script + '" in database'
		RAISERROR (@message, 10, 1)
		return 51008
	end

	-- cannot add an existing entry
	--
	if @mode = 'add' and @tmp <> 0
	begin
		set @message = 'Script "' + @Script + '" already exists in database'
		RAISERROR (@message, 10, 1)
		return 51009
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		Declare @ScriptIDNew int = 1

		Declare @TranAddScript varchar(64) = 'AddScript'
		Begin Tran @TranAddScript
		
		SELECT @ScriptIDNew = IsNull(MAX(ID), 0) + 1
		FROM T_Scripts

		INSERT INTO T_Scripts (
			ID,
			Script, 
			Description, 
			Enabled, 
			Results_Tag, 
			Backfill_to_DMS,
			Contents,
			Parameters,
			Fields
		) VALUES (
			@ScriptIDNew,
			@Script, 
			@Description, 
			@Enabled, 
			@ResultsTag, 
			@BackFill,
			@Contents,
			@Parameters,
			@Fields
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		end

		Commit Tran @TranAddScript
		
		-- If @callingUser is defined, then update Entered_By in T_Scripts_History
		If Len(@callingUser) > 0
		Begin
			Set @ID = Null
			SELECT @ID = ID
			FROM T_Scripts
			WHERE Script = @Script
			
			If Not @ID Is Null
				Exec AlterEnteredByUser 'T_Scripts_History', 'ID', @ID, @CallingUser
		End
		
	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--

		UPDATE T_Scripts 
		SET 
		  Description = @Description, 
		  Enabled = @Enabled, 
		  Results_Tag = @ResultsTag, 
		  Backfill_to_DMS = @BackFill,
		  Contents = @Contents,
		  Parameters = @Parameters,
		  Fields = @Fields
		WHERE (Script = @Script)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
		  set @message = 'Update operation failed: "' + @Script + '"'
		  RAISERROR (@message, 10, 1)
		  return 51004
		end
		
		-- If @callingUser is defined, then update Entered_By in T_Scripts_History
		If Len(@callingUser) > 0
		Begin
			Set @ID = Null
			SELECT @ID = ID
			FROM T_Scripts
			WHERE Script = @Script
			
			If Not @ID Is Null
				Exec AlterEnteredByUser 'T_Scripts_History', 'ID', @ID, @CallingUser
		End
		
	end -- update mode

	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateScripts] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateScripts] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateScripts] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateScripts] TO [PNL\D3M580] AS [dbo]
GO
