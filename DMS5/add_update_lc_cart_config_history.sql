/****** Object:  StoredProcedure [dbo].[add_update_lc_cart_config_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_lc_cart_config_history]
/****************************************************
**
**  Desc:
**    Adds new or edits existing item in T_LC_Cart_Config_History
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/09/2011
**          03/26/2012 grk - added @postedBy
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          11/25/2023 mem - Validate LC cart name
**
*****************************************************/
(
    @id int,
    @cart varchar(128),
    @dateOfChange VARCHAR(32),
    @postedBy VARCHAR(64),
    @description varchar(128),
    @note text,
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @cart = LTrim(RTrim(Coalesce(@cart, '')));

    Declare @entryDate DateTime = Try_cast(@dateOfChange as DateTime)
    If @entryDate Is Null
        Set @entryDate = GETDATE()

    If @postedBy IS NULL OR @postedBy = ''
    Begin
        SET @postedBy = @callingUser
    End

    If Not Exists (SELECT id FROM t_lc_cart WHERE cart_name = @cart)
    Begin
        RAISERROR ('Unrecognized LC cart name: %s', 11, 15, @cart)
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    if @mode = 'update'
    begin
        -- cannot update a non-existent entry
        --
        declare @tmp int
        set @tmp = 0
        --
        SELECT @tmp = ID
        FROM  T_LC_Cart_Config_History
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 OR @tmp = 0
            RAISERROR ('No entry could be found in database for update', 11, 16)
    end

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If @Mode = 'add'
    Begin

        INSERT INTO T_LC_Cart_Config_History (
            Cart,
            Date_Of_Change,
            Description,
            Note,
            EnteredBy
         ) VALUES (
            @Cart,
            @entryDate,
            @Description,
            @Note,
            @postedBy
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
            RAISERROR ('Insert operation failed', 11, 7)

        -- Return ID of newly created entry
        --
        set @ID = SCOPE_IDENTITY()

    End

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If @Mode = 'update'
    Begin
        set @myError = 0
        --
        UPDATE T_LC_Cart_Config_History
        SET Cart = @Cart,
            Date_Of_Change = @entryDate,
            Description = @Description,
            Note = @Note,
            EnteredBy = @postedBy
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'add_update_lc_cart_config_history'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_lc_cart_config_history] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_lc_cart_config_history] TO [DMS2_SP_User] AS [dbo]
GO
