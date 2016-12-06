/****** Object:  StoredProcedure [dbo].[AddUpdateBionetHost] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE AddUpdateBionetHost 
/****************************************************
**
**	Desc: 
**		Adds new or edits existing item in 
**		T_Bionet_Hosts 
**
**	Return values: 0: success, otherwise, error code
**
**	Date: 09/08/2016 mem - Initial version
**    
*****************************************************/
(
	@Host varchar(64),
	@IP varchar(15),
	@Alias varchar(64),
	@Tag varchar(24),
	@Instruments varchar(1024),
	@Active tinyint,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0
	
	Set @message = ''

	Declare @msg varchar(256)

	Begin Try 
	
		---------------------------------------------------
		-- Validate input fields
		---------------------------------------------------
	
		If @mode IS NULL OR Len(@mode) < 1
		Begin
			Set @myError = 51002
			RAISERROR ('@mode cannot be blank',
				11, 1)
		End

		If @Host IS NULL OR Len(@Host) < 1
		Begin
			Set @myError = 51002
			RAISERROR ('@Host cannot be blank',
				11, 1)
		End

		Set @IP = IsNull(@IP, '')
		
		If Len(IsNull(@Alias, '')) = 0 Set @Alias = Null
		If Len(IsNull(@Tag, '')) = 0 Set @Tag = Null
		If Len(IsNull(@Instruments, '')) = 0 Set @Instruments = Null

		Set @Active = IsNull(@Active, 1)
	
		---------------------------------------------------
		-- Is entry already in database?
		---------------------------------------------------
	
		If @mode = 'add' And Exists (SELECT * FROM T_Bionet_Hosts WHERE Host = @Host)
		Begin
			-- Cannot create an entry that already exists
			--
			Set @msg = 'Cannot add: item "' + @Host + '" is already in the database'
			RAISERROR (@msg, 11, 1)
			return 51004
		End
		
		
		If @mode = 'update' And Not Exists (SELECT * FROM T_Bionet_Hosts WHERE Host = @Host)
		Begin
			-- Cannot update a non-existent entry
			Set @msg = 'Cannot update: item "' + @Host + '" is not in the database'
			RAISERROR (@msg, 11, 16)
			return 51005
		End
	
		---------------------------------------------------
		-- Action for add mode
		---------------------------------------------------
		--
		If @Mode = 'add'
		Begin
		
			INSERT INTO T_Bionet_Hosts( Host,
			                            IP,
			                            Alias,
			                            Entered,
			                            Instruments,
			                            Active,
			                            Tag )
			VALUES(@Host, @IP, @Alias, GetDate(), @Instruments, @Active, @Tag)

			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			If @myError <> 0
				RAISERROR ('Insert operation failed: "%s"', 11, 7, @Host)
	
		End -- add mode
	
		---------------------------------------------------
		-- Action for update mode
		---------------------------------------------------
		--
		If @Mode = 'update' 
		Begin

			UPDATE T_Bionet_Hosts
			SET IP = @IP,
			    Alias = @Alias,
			    Instruments = @Instruments,
			    Active = @Active,
			    Tag = @Tag
			WHERE Host = @Host
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			If @myError <> 0
				RAISERROR ('Update operation failed: "%s"', 11, 4, @Host)
	
		End -- update mode
	
	End Try
	Begin Catch 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- Rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	End Catch

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateBionetHost] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateBionetHost] TO [DMS2_SP_User] AS [dbo]
GO
