/****** Object:  StoredProcedure [dbo].[DeleteAuxInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteAuxInfo]
/****************************************************
**
**  Desc:
**      Deletes existing auxiliary information in database
**      for given target type and identity
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   04/08/2002
**          06/16/2022 mem - Auto change @targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new aux info table and column names
**
*****************************************************/
(
    @targetName varchar(128) = '',
    @targetEntityName varchar(128) = '',
    @message varchar(512) = '' output
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @targetName = Ltrim(Rtrim(Coalesce(@targetName, '')))
    Set @targetEntityName = Ltrim(Rtrim(Coalesce(@targetEntityName, '')))

    If @targetName = 'Cell Culture' And Exists (Select * From T_Aux_Info_Target Where Target_Type_Name = 'Biomaterial')
    Begin
        Set @targetName = 'Biomaterial'
    End

    ---------------------------------------------------
    -- Resolve target name to target table criteria
    ---------------------------------------------------

    Declare @tgtTableName varchar(128)
    Declare @tgtTableNameCol varchar(128)
    Declare @tgtTableIDCol varchar(128)

    SELECT
        @tgtTableName = Target_Table,
        @tgtTableIDCol = Target_ID_Col,
        @tgtTableNameCol = Target_Name_Col
    FROM T_Aux_Info_Target
    WHERE (Target_Type_Name = @targetName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or @myRowCount <> 1
    begin
        set @message = 'Could not look up table criteria for target: "' + @targetName + '"'
        return 51000
    end

    If @tgtTableName = 'T_Cell_Culture'
    Begin
        -- Auto-switch the target table to t_biomaterial if T_Cell_Culture does not exist but t_biomaterial does
        If Not Exists (Select * From information_schema.tables Where table_name = 'T_Cell_Culture' and table_type = 'BASE TABLE')
            And Exists (Select * From information_schema.tables Where table_name = 't_biomaterial'  and table_type = 'BASE TABLE')
        Begin
            Set @tgtTableName = 't_biomaterial'
            Set @tgtTableIDCol = 'biomaterial_id'
            Set @tgtTableNameCol = 'biomaterial_name'
        End
    End
    ---------------------------------------------------
    -- Resolve target name and entity name to entity ID
    ---------------------------------------------------

    Declare @targetID int
    set @targetID = 0

    Declare @sql nvarchar(1024)

    set @sql = N''
    set @sql = @sql + 'SELECT @targetID = ' + @tgtTableIDCol
    set @sql = @sql + ' FROM ' + @tgtTableName
    set @sql = @sql + ' WHERE ' + @tgtTableNameCol
    set @sql = @sql + ' = ''' + @targetEntityName + ''''

    exec sp_executesql @sql, N'@targetID int output', @targetID = @targetID output

    if @targetID = 0
    begin
        set @message = 'Error resolving ID for ' + @targetName + ' "' + @targetEntityName + '"'
        return 51000
    end


    ---------------------------------------------------
    -- Delete all entries from auxiliary value table
    -- for the given target type and identity
    ---------------------------------------------------

    DELETE FROM T_Aux_Info_Value
    WHERE (Target_ID = @targetID) AND
    (
        Aux_Description_ID IN
        (
            SELECT Item_ID
            FROM V_Aux_Info_Definition_with_ID
            WHERE (Target = @targetName)
        )
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error deleting auxiliary info for ' + @targetName + ' "' + @targetEntityName + '"'
        return 51000
    end

    return 0


GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAuxInfo] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAuxInfo] TO [Limited_Table_Write] AS [dbo]
GO
