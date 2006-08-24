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
**		Auth: grk
**		Date: 1/27/2004
**    
*****************************************************/
(
	@UserPRN varchar(50), 
	@UserName varchar(50), 
	@HanfordIDNum varchar(50), 
	@AccessList varchar(256), 
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

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@UserPRN) < 1
	begin
		set @myError = 51000
		RAISERROR ('User PRN was blank',
			10, 1)
	end

	if LEN(@UserName) < 1
	begin
		set @myError = 51001
		RAISERROR ('User Name was blank',
			10, 1)
	end
	--
	if LEN(@HanfordIDNum) < 1
	begin
		set @myError = 51002
		RAISERROR ('Hanford ID number was blank',
			10, 1)
	end
	--
	if LEN(@AccessList) < 1
	begin
		set @myError = 51003
		RAISERROR ('Access list was blank',
			10, 1)
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
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @UserID = 0 and @mode = 'update'
	begin
		set @msg = 'Cannot update: User "' + @UserPRN + '" is not in database '
		RAISERROR (@msg, 10, 1)
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
			U_Access_Lists
		) VALUES (
			@UserPRN, 
			@UserName, 
			@HanfordIDNum, 
			@AccessList
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed: "' + @UserPRN + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
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
		UPDATE T_Users
		SET 
			U_Name = @UserName, 
			U_HID = @HanfordIDNum, 
			U_Access_Lists = @AccessList
		WHERE (U_PRN = @UserPRN)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @UserPRN + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- update mode


	return 0


GO
