/****** Object:  StoredProcedure [dbo].[AddUpdateLCCart] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateLCCart]
/****************************************************
**
**  Desc: Adds new or edits existing LC Cart
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/23/2006
**          03/03/2006 grk - Fixed problem with duplicate entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/10/2018 mem - Fix bug checking for duplicate carts when adding a new cart
**          04/11/2022 mem - Check for whitespace in @CartName
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @ID int output,
    @CartName varchar(128),
    @CartDescription varchar(1024),
    @CartState varchar(50),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateLCCart', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @CartName = LTrim(RTrim(IsNull(@CartName, '')))
    Set @CartDescription = LTrim(RTrim(IsNull(@CartDescription, '')))
    Set @CartState = LTrim(RTrim(IsNull(@CartState, '')))
    Set @mode = IsNull(@mode, '')

    If dbo.udfWhitespaceChars(@CartName, 0) > 0
    Begin
        If CharIndex(Char(9), @CartName) > 0
            RAISERROR ('LC Cart name cannot contain tabs', 11, 116)
        Else
            RAISERROR ('LC Cart name cannot contain spaces', 11, 116)
    End

    ---------------------------------------------------
    -- Resolve cart state name to ID
    ---------------------------------------------------
    --
    Declare @CartStateID int = 0
    --
    SELECT @CartStateID = ID
    FROM T_LC_Cart_State_Name
    WHERE  [Name] = @CartState
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to resolve state name to ID'
        RAISERROR (@message, 10, 1)
        return 51007
    End
    --
    If @CartStateID = 0
    Begin
        Set @message = 'Could not resolve state name to ID'
        RAISERROR (@message, 10, 1)
        return 51008
    End

    ---------------------------------------------------
    -- Verify whether entry exists or not
    ---------------------------------------------------

    If @Mode = 'add'
    Begin
        Set @ID = 0

        If Exists (SELECT * FROM T_LC_Cart WHERE Cart_Name = @CartName)
        Begin
            Set @message = 'Cannot Add - Entry already exists for cart "' + @CartName + '"'
            RAISERROR (@message, 10, 1)
            return 51007
        End
    End

    If @Mode = 'update'
    Begin
        If Not Exists (SELECT * FROM T_LC_Cart WHERE ID = @ID)
        Begin
            Set @message = 'Cannot update - cart ID ' + Cast(@ID as varchar(9)) + ' does not exist'
            RAISERROR (@message, 10, 1)
            return 51007
        End

        Declare @currentName varchar(128) = ''

        SELECT @currentName = Cart_Name
        FROM T_LC_Cart
        WHERE ID = @ID

        If @CartName <> @currentName And Exists (SELECT * FROM T_LC_Cart WHERE Cart_Name = @CartName)
        Begin
            Set @message = 'Cannot rename - Entry already exists for cart "' + @CartName + '"'
            RAISERROR (@message, 10, 1)
            return 51007
        End
    End

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @Mode = 'add'
    Begin

        INSERT INTO T_LC_Cart (
            Cart_Name,
            Cart_State_ID,
            Cart_Description
        ) VALUES (
            @CartName,
            @CartStateID,
            @CartDescription
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            return 51007
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

        UPDATE T_LC_Cart
        SET Cart_Name = @CartName,
            Cart_State_ID = @CartStateID,
            Cart_Description = @CartDescription
        WHERE ID = @ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed, Cart ' + @CartName + ', ID "' + Cast(@ID as varchar(9)) + '"'
            RAISERROR (@message, 10, 1)
            return 51004
        End
    End -- update mode

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCart] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCart] TO [DMS_LC_Column_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCart] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCart] TO [Limited_Table_Write] AS [dbo]
GO
