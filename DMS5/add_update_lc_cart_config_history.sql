/****** Object:  StoredProcedure [dbo].[add_update_lc_cart_config_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_lc_cart_config_history]
/****************************************************
**
**  Desc:
**    Adds new or edits existing item in
**    T_LC_Cart_Config_History
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/09/2011
**          03/26/2012 grk - added @PostedBy
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
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

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Declare @entryDate DateTime = Try_cast(@DateOfChange as DateTime)
    If @entryDate Is Null
        Set @entryDate = GETDATE()

    IF @PostedBy IS NULL OR @PostedBy = ''
    BEGIN
        SET @PostedBy = @callingUser
    END

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
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

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
            @PostedBy
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
            RAISERROR ('Insert operation failed', 11, 7)

        -- Return ID of newly created entry
        --
        set @ID = SCOPE_IDENTITY()

    end -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        set @myError = 0
        --
        UPDATE T_LC_Cart_Config_History
        SET Cart = @Cart,
            Date_Of_Change = @entryDate,
            Description = @Description,
            Note = @Note,
            EnteredBy = @PostedBy
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @ID)

    end -- update mode

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
