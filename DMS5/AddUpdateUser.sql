/****** Object:  StoredProcedure [dbo].[AddUpdateUser] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[AddUpdateUser]
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
**          01/23/2008 grk - Added @UserUpdate
**          10/14/2010 mem - Added @Comment
**          06/01/2012 mem - Added Try/Catch block
**          06/05/2013 mem - Now calling AddUpdateUserOperations
**          06/11/2013 mem - Renamed the first two parameters (previously @UserPRN and @Username)
**          02/23/2016 mem - Add Set XACT_ABORT on
**          08/23/2016 mem - Auto-add 'H' when @mode is 'add' and @HanfordIDNum starts with a number
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          07/11/2017 mem - Require @HanfordIDNum to be at least 2 characters long
**          08/01/2017 mem - Use THROW if not authorized
**          08/16/2018 mem - Remove any text before a backslash in @username (e.g., change from PNL\D3L243 to D3L243)
**
*****************************************************/
(
    @Username varchar(50),              -- Network login for the user (was traditionally D+Payroll number, but switched to last name plus 3 digits around 2011)
    @HanfordIDNum varchar(50),          -- Hanford ID number for user; cannot be blank
    @LastNameFirstName varchar(128),    -- Cannot be blank (though this field is auto-updated by UpdateUsersFromWarehouse)
    @Payroll varchar(32),               -- Can be blank; will be auto-updated by UpdateUsersFromWarehouse
    @Email varchar(64),                 -- Can be blank; will be auto-updated by UpdateUsersFromWarehouse
    @UserStatus varchar(24),            -- Active or Inactive (whether or not user is Active in DMS)
    @UserUpdate varchar(1),             -- Y or N  (whether or not to auto-update using UpdateUsersFromWarehouse)
    @OperationsList varchar(1024),      -- List of access permissions for user
    @Comment varchar(512) = '',
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
As
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
    Exec @authorized = VerifySPAuthorized 'AddUpdateUser', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        Set @Username = Ltrim(RTrim(@Username))
        Set @LastNameFirstName = Ltrim(RTrim(@LastNameFirstName))
        Set @HanfordIDNum = Ltrim(RTrim(@HanfordIDNum))
        Set @UserStatus = Ltrim(RTrim(@UserStatus))

        Set @myError = 0
        If LEN(@Username) < 1
        Begin
            Set @myError = 51000
            RAISERROR ('Username was blank',
                11, 1)
        End
        Else
        Begin
            Set @charIndex = CharIndex('\', @Username)
            If @charIndex > 0
            Begin
                Set @Username = Substring(@Username, @charIndex + 1, Len(@Username))
            End
        End

        If LEN(@LastNameFirstName) < 1
        Begin
            Set @myError = 51001
            RAISERROR ('Last Name, First Name was blank',
                11, 1)
        End
        --
        If LEN(@HanfordIDNum) <= 1
        Begin
            Set @myError = 51002
            RAISERROR ('Hanford ID number cannot be blank or a single character',
                11, 1)
        End
        --
        If LEN(@UserStatus) < 1
        Begin
            Set @myError = 51004
            RAISERROR ('User status was blank',
                11, 1)
        End
        --
        If @myError <> 0
            Return @myError

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        Declare @UserID int = 0
        --
        execute @UserID = GetUserID @Username

        -- cannot create an entry that already exists
        --
        If @UserID <> 0 and @mode = 'add'
        Begin
            Set @msg = 'Cannot add: User "' + @Username + '" already in database '
            RAISERROR (@msg, 11, 1)
            Return 51004
        End

        -- cannot update a non-existent entry
        --
        If @UserID = 0 and @mode = 'update'
        Begin
            Set @msg = 'Cannot update: User "' + @Username + '" is not in database '
            RAISERROR (@msg, 11, 1)
            Return 51004
        End

        Set @logErrors = 1

        ---------------------------------------------------
        -- action for add mode
        ---------------------------------------------------

        If @Mode = 'add'
        Begin
            -- Add an H to @HanfordIDNum if it starts with a number
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
            Set @UserID = SCOPE_IDENTITY()

            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @msg = 'Insert operation failed: "' + @Username + '"'
                RAISERROR (@msg, 11, 1)
                Return 51007
            End
        End -- add mode


        ---------------------------------------------------
        -- action for update mode
        ---------------------------------------------------
        --
        If @Mode = 'update'
        Begin
            If @UserStatus = 'Inactive'
            Begin
                Set @myError = 0
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
                If @myError <> 0
                Begin
                    Set @msg = 'Update operation failed: "' + @Username + '"'
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
                If @myError <> 0
                Begin
                    Set @msg = 'Update operation failed: "' + @Username + '"'
                    RAISERROR (@msg, 11, 1)
                    Return 51004
                End
            End
        End -- update mode

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

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateUser] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateUser] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateUser] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateUser] TO [Limited_Table_Write] AS [dbo]
GO
