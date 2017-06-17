/****** Object:  StoredProcedure [dbo].[AddUpdateUser] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateUser
/****************************************************
**
**	Desc: Adds new or updates existing User in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@Username                Network login for the User (was traditionally D+Payroll number, but switched to last name plus 3 digits around 2011)
**		@LastNameFirstName       User's Last Name then First Name
**		@HanfordIDNum	         Hanford ID number for user
**		@AccessList              List of access permissions for user 
**	
**
**	Auth:	grk
**	Date:	01/27/2004
**			11/03/2006 JDS - Added support for U_Status field, removed @AccessList varchar(256)
**			01/23/2008 grk - Added @UserUpdate
**			10/14/2010 mem - Added @Comment
**			06/01/2012 mem - Added Try/Catch block
**			06/05/2013 mem - Now calling AddUpdateUserOperations
**			06/11/2013 mem - Renamed the first two parameters (previously @UserPRN and @Username)
**			02/23/2016 mem - Add set XACT_ABORT on
**			08/23/2016 mem - Auto-add 'H' when @mode is 'add' and @HanfordIDNum starts with a number
**			11/18/2016 mem - Log try/catch errors using PostLogEntry
**			12/05/2016 mem - Exclude logging some try/catch errors
**			12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**			06/13/2017 mem - Use SCOPE_IDENTITY()
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**
*****************************************************/
(
	@Username varchar(50), 
	@HanfordIDNum varchar(50), 
	@LastNameFirstName varchar(128),		-- Cannot be blank (though this field is auto-updated by UpdateUsersFromWarehouse)
	@Payroll varchar(32),					-- Can be blank; will be auto-updated by UpdateUsersFromWarehouse
	@Email varchar(64),						-- Can be blank; will be auto-updated by UpdateUsersFromWarehouse
	@UserStatus varchar(24),				-- Active or Inactive (whether or not user is Active in DMS)
	@UserUpdate varchar(1),					-- Y or N  (whether or not to auto-update using UpdateUsersFromWarehouse)
	@OperationsList varchar(1024),
	@Comment varchar(512) = '',
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	Declare @logErrors tinyint = 0

	BEGIN TRY 

		---------------------------------------------------
		-- Verify that the user can execute this procedure from the given client host
		---------------------------------------------------
			
		Declare @authorized tinyint = 0	
		Exec @authorized = VerifySPAuthorized 'AddUpdateUser', @raiseError = 1
		If @authorized = 0
		Begin
			RAISERROR ('Access denied', 11, 3)
		End

		---------------------------------------------------
		-- Validate input fields
		---------------------------------------------------

		set @myError = 0
		if LEN(@Username) < 1
		begin
			set @myError = 51000
			RAISERROR ('Username was blank',
				11, 1)
		end

		if LEN(@LastNameFirstName) < 1
		begin
			set @myError = 51001
			RAISERROR ('Last Name, First Name was blank',
				11, 1)
		end
		--
		if LEN(@HanfordIDNum) < 1
		begin
			set @myError = 51002
			RAISERROR ('Hanford ID number was blank',
				11, 1)
		end
		--
		if LEN(@UserStatus) < 1
		begin
			set @myError = 51004
			RAISERROR ('User status was blank',
				11, 1)
		end
		--
		if @myError <> 0
			return @myError

		---------------------------------------------------
		-- Is entry already in database?
		---------------------------------------------------

		declare @UserID int
		set @UserID = 0
		--
		execute @UserID = GetUserID @Username

		-- cannot create an entry that already exists
		--
		if @UserID <> 0 and @mode = 'add'
		begin
			set @msg = 'Cannot add: User "' + @Username + '" already in database '
			RAISERROR (@msg, 11, 1)
			return 51004
		end

		-- cannot update a non-existent entry
		--
		if @UserID = 0 and @mode = 'update'
		begin
			set @msg = 'Cannot update: User "' + @Username + '" is not in database '
			RAISERROR (@msg, 11, 1)
			return 51004
		end

		Set @logErrors = 1

		---------------------------------------------------
		-- action for add mode
		---------------------------------------------------
		
		if @Mode = 'add'
		begin
			If @HanfordIDNum Like '[0-9]%'
			Begin
				Set @HanfordIDNum = 'H' + @HanfordIDNum
			End
			
			INSERT INTO T_Users (
				U_PRN, 
				U_Name, 
				U_HID, 
				U_Payroll,
				U_Email,
				U_Status, 
				U_update,
				U_comment
			) VALUES (
				@Username,
				@LastNameFirstName,
				@HanfordIDNum,
				@Payroll,
				@Email,
				@UserStatus, 
				@UserUpdate,
				ISNULL(@Comment, '')
			)	
			-- Obtain User ID of newly created User
			--
			set @UserID = SCOPE_IDENTITY()

			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Insert operation failed: "' + @Username + '"'
				RAISERROR (@msg, 11, 1)
				return 51007
			end
		end -- add mode


		---------------------------------------------------
		-- action for update mode
		---------------------------------------------------
		--
		if @Mode = 'update' 
		begin
			if @UserStatus = 'Inactive'
			begin
				set @myError = 0
				--
				UPDATE T_Users
				SET 
					U_Name = @LastNameFirstName, 
					U_HID = @HanfordIDNum, 
					U_Payroll = @Payroll,
					U_Email = @Email,
					U_Status = @UserStatus,
					U_Active = 'N',
					U_update = 'N',
					U_comment = @Comment
				WHERE (U_PRN = @Username)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Update operation failed: "' + @Username + '"'
					RAISERROR (@msg, 11, 1)
					return 51004
				end
			end
			else
			begin
				set @myError = 0
				--
				UPDATE T_Users
				SET 
					U_Name = @LastNameFirstName, 
					U_HID = @HanfordIDNum, 
					U_Payroll = @Payroll,
					U_Email = @Email,
					U_Status = @UserStatus,
					U_update = @UserUpdate,
					U_comment = @Comment
				WHERE (U_PRN = @Username)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Update operation failed: "' + @Username + '"'
					RAISERROR (@msg, 11, 1)
					return 51004
				end
			end
		end -- update mode

		---------------------------------------------------
		-- Add/update operations defined for user
		---------------------------------------------------

		exec @myError = AddUpdateUserOperations @UserID, @OperationsList, @message output

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		If @logErrors > 0
		Begin
			Declare @logMessage varchar(1024) = @message + '; Username ' + @Username		
			exec PostLogEntry 'Error', @logMessage, 'AddUpdateUser'
		End

	END CATCH
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateUser] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateUser] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateUser] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateUser] TO [Limited_Table_Write] AS [dbo]
GO
