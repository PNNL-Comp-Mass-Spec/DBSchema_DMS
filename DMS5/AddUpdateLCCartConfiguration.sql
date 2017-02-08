/****** Object:  StoredProcedure [dbo].[AddUpdateLCCartConfiguration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateLCCartConfiguration
/****************************************************
**
**  Desc: Adds new or edits existing T_LC_Cart_Configuration entry
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth: 	mem
**  Date: 	02/02/2017 mem - Initial release
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@ID int,
	@cartName varchar(128),
	@pumps varchar(256),
	@columns varchar(256),
	@traps varchar(256),
	@mobilePhase varchar(256),
	@injection varchar(64),
	@gradient varchar(512),
	@comment varchar(1024),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set nocount on

	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Set @message = ''

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @ID = IsNull(@ID, 0)
	Set @cartName = IsNull(@cartName, '')

	---------------------------------------------------
	-- Resolve cart name to ID
	---------------------------------------------------
	Declare @cartID int = 0
	--
	SELECT @cartID = ID
	FROM  T_LC_Cart
	WHERE Cart_Name = @cartName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Error trying to resolve cart ID'
		RAISERROR (@message, 10, 1)
		Return 51007
	End

	If @cartID = 0
	Begin
		Set @message = 'Could not find cart ' + @cartName
		RAISERROR (@message, 10, 1)
		Return 51006
	End

	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	If @mode = 'update'
	Begin
		-- cannot update a non-existent entry
		--
		Select * FROM T_LC_Cart_Configuration Where ID = @ID
		
		If Not Exists (Select * FROM T_LC_Cart_Configuration Where ID = @ID)
		Begin
			Set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			Return 51007
		End

	End


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	If @Mode = 'add'
	Begin

		INSERT INTO T_LC_Cart_Configuration (
			Cart_ID,
			Pumps,
			Columns,
			Traps,
			Mobile_Phase,
			Injection,
			Gradient,
			Comment,
			Entered,
			Entered_By			
		) VALUES (
			@cartID,
			@pumps,
			@columns,
			@traps,
			@mobilePhase,
			@injection,
			@gradient,
			@comment,
			GetDate(),
			@callingUser
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			Set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			Return 51007
		End

		-- Return ID of newly created entry
		--
		Set @ID = SCOPE_IDENTITY()

	End -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	If @Mode = 'update' 
	Begin
		Set @myError = 0
		--

		UPDATE T_LC_Cart_Configuration
		SET Pumps = @pumps,
			Columns = @columns,
			Traps = @traps,
			Mobile_Phase = @mobilePhase,
			Injection = @injection,
			Gradient = @gradient,
			Comment = @comment,
			Updated = GetDate(),
			Updated_By = @callingUser
		WHERE Cart_ID = @cartID		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			Set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			Return 51004
		End
		
	End -- update mode

  Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartConfiguration] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartConfiguration] TO [Limited_Table_Write] AS [dbo]
GO
