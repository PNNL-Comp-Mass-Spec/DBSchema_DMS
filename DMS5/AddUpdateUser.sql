/****** Object:  StoredProcedure [dbo].[AddUpdateUser] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateUser
/****************************************************
**
**	Desc: Adds new or updates existing User in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@UserPRN        D+Payroll number for the User
**		@UserName       User's name 
**		@HanfordIDNum	Hanford ID number for user
**		@AccessList     List of access permissions for user 
**	
**
**	Auth:	grk
**	Date:	01/27/2004
**			11/03/2006 JDS - Added support for U_Status field, removed @AccessList varchar(256)
**			01/23/2008 grk - Added @UserUpdate
**			10/14/2010 mem - Added @Comment
**			06/01/2012 mem - Added Try/Catch block
**			06/05/2013 mem - Now calling AddUpdateUserOperations
**
*****************************************************/
(
	@UserPRN varchar(50), 
	@UserName varchar(50), 
	@HanfordIDNum varchar(50), 
	@UserStatus varchar(24), 
	@UserUpdate varchar(1),
	@OperationsList varchar(1024),
	@Comment varchar(512) = '',
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output
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
		if LEN(@UserPRN) < 1
		begin
			set @myError = 51000
			RAISERROR ('User PRN was blank',
				11, 1)
		end

		if LEN(@UserName) < 1
		begin
			set @myError = 51001
			RAISERROR ('User Name was blank',
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
		execute @UserID = GetUserID @UserPRN

		-- cannot create an entry that already exists
		--
		if @UserID <> 0 and @mode = 'add'
		begin
			set @msg = 'Cannot add: User "' + @UserPRN + '" already in database '
			RAISERROR (@msg, 11, 1)
			return 51004
		end

		-- cannot update a non-existent entry
		--
		if @UserID = 0 and @mode = 'update'
		begin
			set @msg = 'Cannot update: User "' + @UserPRN + '" is not in database '
			RAISERROR (@msg, 11, 1)
			return 51004
		end

		---------------------------------------------------
		-- action for add mode
		---------------------------------------------------
		if @Mode = 'add'
		begin

			INSERT INTO T_Users (
				U_PRN, 
				U_Name, 
				U_HID, 
				U_Status, 
				U_update,
				U_comment
			) VALUES (
				@UserPRN,
				@UserName,
				@HanfordIDNum,
				@UserStatus, 
				@UserUpdate,
				ISNULL(@Comment, '')
			)	
			-- Obtain User ID of newly created User
			--
			set @UserID = IDENT_CURRENT('T_Users')

			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Insert operation failed: "' + @UserPRN + '"'
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
					U_Name = @UserName, 
					U_HID = @HanfordIDNum, 
					U_Status = @UserStatus,
					U_Active = 'N',
					U_update = 'N',
					U_comment = @Comment
				WHERE (U_PRN = @UserPRN)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Update operation failed: "' + @UserPRN + '"'
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
					U_Name = @UserName, 
					U_HID = @HanfordIDNum, 
					U_Status = @UserStatus,
					U_update = @UserUpdate,
					U_comment = @Comment
				WHERE (U_PRN = @UserPRN)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @msg = 'Update operation failed: "' + @UserPRN + '"'
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
	END CATCH
	
	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateUser] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateUser] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateUser] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateUser] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateUser] TO [PNL\D3M580] AS [dbo]
GO
