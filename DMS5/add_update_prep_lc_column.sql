/****** Object:  StoredProcedure [dbo].[add_update_prep_lc_column] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_prep_lc_column]
/****************************************************
**
**  Desc:
**      Adds new or edits existing item in T_Prep_LC_Column
**
**  Auth:   grk
**  Date:   07/29/2009 grk - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          04/11/2022 mem - Check for whitespace in @ColumnName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @columnName varchar(128),
    @mfgName varchar(128),
    @mfgModel varchar(128),
    @mfgSerialNumber varchar(64),
    @packingMfg varchar(64),
    @packingType varchar(64),
    @particlesize varchar(64),
    @particletype varchar(64),
    @columnInnerDia varchar(64),
    @columnOuterDia varchar(64),
    @length varchar(64),
    @state varchar(32),
    @operatorUsername varchar(50),
    @comment varchar(244),
    @mode varchar(12) = 'add', -- or 'update'
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
    Exec @authorized = verify_sp_authorized 'add_update_prep_lc_column', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    Set @ColumnName = IsNull(@ColumnName, '')
    If @ColumnName = ''
    Begin
        Set @myError = 51000
        RAISERROR ('Column name was blank', 11, 1)
    End

    If dbo.has_whitespace_chars(@ColumnName, 0) > 0
    Begin
        If CharIndex(Char(9), @ColumnName) > 0
            RAISERROR ('Column name cannot contain tabs', 11, 116)
        Else
            RAISERROR ('Column name cannot contain spaces', 11, 116)
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    declare @tmp int = 0
    --
    SELECT @tmp = ID
    FROM  T_Prep_LC_Column
    WHERE Column_Name = @ColumnName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking for existing entry'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    if @mode = 'update' and @tmp = 0
    begin
        set @message = 'No entry could be found in database for update'
        RAISERROR (@message, 10, 1)
        return 51008
    end

    if @mode = 'add' and @tmp <> 0
    begin
        set @message = 'Cannot add a duplicate entry'
        RAISERROR (@message, 10, 1)
        return 51008
    end

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin

        INSERT INTO T_Prep_LC_Column (
            Column_Name,
            Mfg_Name,
            Mfg_Model,
            Mfg_Serial_Number,
            Packing_Mfg,
            Packing_Type,
            Particle_size,
            Particle_type,
            Column_Inner_Dia,
            Column_Outer_Dia,
            Length,
            State,
            Operator_PRN,
            Comment
        ) VALUES (
            @ColumnName,
            @MfgName,
            @MfgModel,
            @MfgSerialNumber,
            @PackingMfg,
            @PackingType,
            @Particlesize,
            @Particletype,
            @ColumnInnerDia,
            @ColumnOuterDia,
            @Length,
            @State,
            @operatorUsername,
            @Comment
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            return 51010
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
        UPDATE T_Prep_LC_Column
        SET
            Mfg_Name = @MfgName,
            Mfg_Model = @MfgModel,
            Mfg_Serial_Number = @MfgSerialNumber,
            Packing_Mfg = @PackingMfg,
            Packing_Type = @PackingType,
            Particle_size = @Particlesize,
            Particle_type = @Particletype,
            Column_Inner_Dia = @ColumnInnerDia,
            Column_Outer_Dia = @ColumnOuterDia,
            Length = @Length,
            State = @State,
            Operator_PRN = @operatorUsername,
            Comment = @Comment
        WHERE
            Column_Name = @ColumnName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Update operation failed: "' + @ColumnName + '"'
            RAISERROR (@message, 10, 1)
            return 51011
        end
    end -- update mode

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_prep_lc_column] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_prep_lc_column] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_prep_lc_column] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_prep_lc_column] TO [Limited_Table_Write] AS [dbo]
GO
