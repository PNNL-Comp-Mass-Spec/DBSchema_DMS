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
**    
*****************************************************/
(
	@Script varchar(64),
	@Description varchar(512),
	@Enabled char(1),
	@ResultsTag varchar(8),
	@Contents text,
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
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @Description = IsNull(@Description, '')
	Set @Enabled = IsNull(@Enabled, 'Y')
	Set @mode = IsNull(@mode, '')
	Set @message = ''
	Set @callingUser = IsNull(@callingUser, '')

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

		INSERT INTO T_Scripts (
			Script, 
			Description, 
			Enabled, 
			Results_Tag, 
			Contents
		) VALUES (
			@Script, 
			@Description, 
			@Enabled, 
			@ResultsTag, 
			@Contents
		)
		/**/
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
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
		  Contents = @Contents
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
		
		-- If @callingUser is defined, then update Entered_By in T_Organisms_Change_History
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
GRANT VIEW DEFINITION ON [dbo].[AddUpdateScripts] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateScripts] TO [DMS_SP_User] AS [dbo]
GO
