/****** Object:  StoredProcedure [dbo].[add_update_wellplate] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_wellplate]
/****************************************************
**
**  Desc:
**      Adds new or edits existing item in T_Wellplates
**
**  Auth:   grk
**  Date:   07/23/2009
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/25/2022 mem - Rename parameter to @wellplateName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @wellplateName varchar(64) output,      -- Wellplate name
    @description varchar(512),
    @mode varchar(12) = 'add', -- or 'update' or 'assure'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_wellplate', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- optionally generate name
    ---------------------------------------------------
    declare @idx int

    If @wellplateName = '(generate name)'
    begin
        --
        SELECT @idx = MAX(ID) + 1
        FROM  T_Wellplates
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to create name'
            RAISERROR (@message, 10, 1)
            return 51000
        end

        If @idx < 1000
        Begin
            set @idx = 1000
        End

        set @wellplateName = 'WP-' + cast(@idx as varchar(12))
    end

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------
    declare @tmp int
    set @tmp = 0
    --
    SELECT @tmp = ID
    FROM  T_Wellplates
    WHERE(WP_Well_Plate_Num = @wellplateName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error lookin for existing entry'
        RAISERROR (@message, 10, 1)
        return 51005
    end

    ---------------------------------------------------
    -- in this mode, add new entry if it doesn't exist
    ---------------------------------------------------
    if @mode = 'assure' and @tmp = 0
    begin
        set @mode = 'add'
    end

    ---------------------------------------------------
    -- cannot update a non-existent entry
    ---------------------------------------------------
    if @mode = 'update' and @tmp = 0
    begin
        set @message = 'No entry could be found in database for update'
        RAISERROR (@message, 10, 1)
        return 51006
    end

    ---------------------------------------------------
    -- cannot add a matching entry
    ---------------------------------------------------
    if @mode = 'add' and @tmp <> 0
    begin
        set @message = 'Cannot add duplicate wellplate name'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

    INSERT INTO T_Wellplates (
        WP_Well_Plate_Num,
        WP_Description
    ) VALUES (
        @wellplateName,
        @description
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Insert operation failed'
        RAISERROR (@message, 10, 1)
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
        UPDATE T_Wellplates
        SET
        WP_Well_Plate_Num = @wellplateName,
        WP_Description = @description
        WHERE(WP_Well_Plate_Num = @wellplateName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Update operation failed: "' + @wellplateName + '"'
            RAISERROR (@message, 10, 1)
            return 51004
        end
    end -- update mode

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_wellplate] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_wellplate] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_wellplate] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_wellplate] TO [Limited_Table_Write] AS [dbo]
GO
