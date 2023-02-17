/****** Object:  StoredProcedure [dbo].[AddUpdateManagerType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[AddUpdateManagerType]
/****************************************************
**
**  Desc:
**  Adds or Updates manager type values in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   08/24/2007
**
*****************************************************/
(
    @mTypeID varchar(32) = '',
    @mTypeName varchar(50) = '',
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) = '' output
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
    if LEN(@mTypeName) < 1
    begin
        set @myError = 51000
        RAISERROR ('Manager Type Name was blank', 10, 1)
    end

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------
    declare @TmpTypeID varchar(10)
    set @TmpTypeID = '0'
    --
    SELECT @TmpTypeID = MT_TypeID
    FROM T_MgrTypes
    WHERE (MT_TypeName = @mTypeName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Error trying to look for entry in table'
        RAISERROR (@msg, 10, 1)
        return 51082
    end

    -- cannot create an entry that already exists
    --
    if @TmpTypeID <> '0' and @mode = 'add'
    begin
        set @msg = 'Cannot add: Manager Type "' + @mTypeName + '" is already in the database '
        RAISERROR (@msg, 10, 1)
        return 51004
    end

    -- cannot update a non-existent entry
    --
    if @mTypeID = '0' and @mode = 'update'
    begin
        set @msg = 'Cannot update: Manager Type "' + @mTypeName + '" is not in the database '
        RAISERROR (@msg, 10, 1)
        return 51004
    end

    SELECT @TmpTypeID = MT_TypeID
    FROM T_MgrTypes
    WHERE (MT_TypeName = @mTypeName)
          and MT_TypeID <> @mTypeID

    -- cannot update a non-existent entry
    --
    if @TmpTypeID <> '0' and @mode = 'update'
    begin
        set @msg = 'Cannot update: Manager Type "' + @mTypeName + '" is already taken in the database '
        RAISERROR (@msg, 10, 1)
        return 51004
    end

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

        INSERT INTO T_MgrTypes (
            MT_TypeName
        ) VALUES (
            @mTypeName
        )

        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Insert operation failed: "' + @mTypeName + '"'
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
        UPDATE T_MgrTypes
        SET
            MT_TypeName = @mTypeName
        WHERE (MT_TypeID = @mTypeID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Update operation failed: "' + @mTypeName + '"'
            RAISERROR (@msg, 10, 1)
            return 51004
        end
    end -- update mode


    return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateManagerType] TO [Mgr_Config_Admin] AS [dbo]
GO
