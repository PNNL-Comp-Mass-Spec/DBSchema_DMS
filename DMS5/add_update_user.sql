/****** Object:  StoredProcedure [dbo].[add_update_user] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_user]
/****************************************************
**
**  Desc:
**      Adds new or updates existing User in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/27/2004
**          11/03/2006 JDS - Added support for U_Status field, removed @AccessList varchar(256)
**          01/23/2008 grk - Added @userUpdate
**          10/14/2010 mem - Added @comment
**          06/01/2012 mem - Added Try/Catch block
**          06/05/2013 mem - Now calling add_update_user_operations
**          06/11/2013 mem - Renamed the first two parameters (previously @UserPRN and @username)
**          02/23/2016 mem - Add Set XACT_ABORT on
**          08/23/2016 mem - Auto-add 'H' when @mode is 'add' and @hanfordId starts with a number
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/11/2017 mem - Require @hanfordId to be at least 2 characters long
**          08/01/2017 mem - Use THROW if not authorized
**          08/16/2018 mem - Remove any text before a backslash in @username (e.g., change from PNL\D3L243 to D3L243)
**          02/10/2022 mem - Remove obsolete payroll field
**                         - Always add 'H' to @hanfordId if it starts with a number
**          03/16/2022 mem - Replace tab characters with spaces
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**
*****************************************************/
(
    @username varchar(50),              -- Network login for the user (was traditionally D+Payroll number, but switched to last name plus 3 digits around 2011)
    @hanfordId varchar(50),             -- Hanford ID number for user; cannot be blank
    @lastNameFirstName varchar(128),    -- Cannot be blank (though this field is auto-updated by update_users_from_warehouse)
    @email varchar(64),                 -- Can be blank; will be auto-updated by update_users_from_warehouse
    @userStatus varchar(24),            -- Active or Inactive (whether or not user is Active in DMS)
    @userUpdate varchar(1),             -- Y or N  (whether or not to auto-update using update_users_from_warehouse)
    @operationsList varchar(1024),      -- List of access permissions for user
    @comment varchar(512) = '',
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @logErrors tinyint = 0
    Declare @charIndex int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_user', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        Set @username = Ltrim(RTrim(Replace(@username, Char(9), ' ')))
        Set @lastNameFirstName = Ltrim(RTrim(Replace(@lastNameFirstName, Char(9), ' ')))
        Set @hanfordId = Ltrim(RTrim(Replace(@hanfordId, Char(9), ' ')))
        Set @userStatus = Ltrim(RTrim(@userStatus))

        Set @myError = 0
        If LEN(@username) < 1
        Begin
            Set @myError = 51000
            RAISERROR ('Username must be specified', 11, 1)
        End
        Else
        Begin
            Set @charIndex = CharIndex('\', @username)
            If @charIndex > 0
            Begin
                Set @username = Substring(@username, @charIndex + 1, Len(@username))
            End
        End

        If LEN(@lastNameFirstName) < 1
        Begin
            Set @myError = 51001
            RAISERROR ('Last Name, First Name must be specified', 11, 1)
        End
        --
        If LEN(@hanfordId) <= 1
        Begin
            Set @myError = 51002
            RAISERROR ('Hanford ID number cannot be blank or a single character', 11, 1)
        End
        --
        If LEN(@userStatus) < 1
        Begin
            Set @myError = 51004
            RAISERROR ('User status must be specified', 11, 1)
        End
        --
        If @myError <> 0
            Return @myError

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        Declare @userID int = 0
        --
        execute @userID = get_user_id @username

        -- cannot create an entry that already exists
        --
        If @userID <> 0 and @mode = 'add'
        Begin
            Set @msg = 'Cannot add: User "' + @username + '" already in database '
            RAISERROR (@msg, 11, 1)
            Return 51004
        End

        -- cannot update a non-existent entry
        --
        If @userID = 0 and @mode = 'update'
        Begin
            Set @msg = 'Cannot update: User "' + @username + '" is not in database '
            RAISERROR (@msg, 11, 1)
            Return 51004
        End

        ---------------------------------------------------
        -- Add an H to @hanfordId if it starts with a number
        ---------------------------------------------------

        If @hanfordId Like '[0-9]%'
        Begin
            Set @hanfordId = 'H' + @hanfordId
        End

        Set @logErrors = 1

        ---------------------------------------------------
        -- action for add mode
        ---------------------------------------------------

        If @mode = 'add'
        Begin
            INSERT INTO T_Users (
                U_PRN,
                U_Name,
                U_HID,
                U_Email,
                U_Status,
                U_update,
                U_comment
            ) VALUES (
                @username,
                @lastNameFirstName,
                @hanfordId,
                @email,
                @userStatus,
                @userUpdate,
                ISNULL(@comment, '')
            )
            -- Obtain User ID of newly created User
            --
            Set @userID = SCOPE_IDENTITY()

            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @msg = 'Insert operation failed: "' + @username + '"'
                RAISERROR (@msg, 11, 1)
                Return 51007
            End
        End -- add mode


        ---------------------------------------------------
        -- action for update mode
        ---------------------------------------------------
        --
        If @mode = 'update'
        Begin
            If @userStatus = 'Inactive'
            Begin
                Set @myError = 0
                --
                UPDATE T_Users
                SET
                    U_Name = @lastNameFirstName,
                    U_HID = @hanfordId,
                    U_Email = @email,
                    U_Status = @userStatus,
                    U_Active = 'N',
                    U_update = 'N',
                    U_comment = @comment
                WHERE (U_PRN = @username)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    Set @msg = 'Update operation failed: "' + @username + '"'
                    RAISERROR (@msg, 11, 1)
                    Return 51004
                End
            End
            Else
            Begin
                Set @myError = 0
                --
                UPDATE T_Users
                SET
                    U_Name = @lastNameFirstName,
                    U_HID = @hanfordId,
                    U_Email = @email,
                    U_Status = @userStatus,
                    U_update = @userUpdate,
                    U_comment = @comment
                WHERE (U_PRN = @username)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    Set @msg = 'Update operation failed: "' + @username + '"'
                    RAISERROR (@msg, 11, 1)
                    Return 51004
                End
            End
        End -- update mode

        ---------------------------------------------------
        -- Add/update operations defined for user
        ---------------------------------------------------

        exec @myError = add_update_user_operations @userID, @operationsList, @message output

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Username ' + @username
            exec post_log_entry 'Error', @logMessage, 'add_update_user'
        End

    END CATCH

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_user] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_user] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_user] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_user] TO [Limited_Table_Write] AS [dbo]
GO
