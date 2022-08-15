/****** Object:  StoredProcedure [dbo].[CopyAuxInfoMultiID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CopyAuxInfoMultiID]
/****************************************************
**
**  Desc:   Copies aux info from a source item to multiple targets
**
**  Auth:   grk
**  Date:   01/27/2003
**          09/27/2007 mem - Extended CopyAuxInfo to accept a comma separated list of entity IDs to process, rather than a single entity name (Ticket #538)
**          06/16/2022 mem - Auto change @targetName from 'Cell Culture' to 'Biomaterial' if T_AuxInfo_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column names
**
*****************************************************/
(
    @targetName varchar(128),                -- 'Experiment', 'Biomaterial' (previously 'Cell Culture'), 'Dataset', or 'SamplePrepRequest'; see See T_Aux_Info_Target
    @targetEntityIDList varchar(8000),        -- Comma separated list of entity IDs; must all be of the same type
    @categoryName varchar(128),                -- 'Lysis Method', 'Denaturing Conditions', etc.; see T_AuxInfo_Category; Note: Ignored if @mode = 'copyAll'
    @subCategoryName varchar(128),            -- 'Procedure', 'Reagents', etc.; see T_AuxInfo_Subcategory; Note: Ignored if @mode = 'copyAll'
    @sourceEntityID int,                    -- ID of the source to copy information from
    @mode varchar(24),                        -- 'copyCategory', 'copySubcategory', 'copyAll'
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @msg varchar(256)
    Declare @sql nvarchar(2048)
    Declare @MatchVal int

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    if @mode <> 'copyCategory' and @mode <> 'copySubcategory' and @mode <> 'copyAll'
    begin
        set @msg = 'Mode must be copyCategory, copySubcategory, or copyAll'
        RAISERROR (@msg, 10, 1)
        return 51007
    end

    If @targetName = 'Cell Culture' And Exists (Select * From T_AuxInfo_Target Where Name = 'Biomaterial')
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
    FROM T_AuxInfo_Target
    WHERE (Name = @targetName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or @myRowCount <> 1
    begin
        set @msg = 'Could not look up table criteria for target: "' + @targetName + '"'
        RAISERROR (@msg, 10, 1)
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
    -- Validate that the source entity ID is present in @tgtTableName
    ---------------------------------------------------

    Set @MatchVal = Null

    set @sql = N''
    set @sql = @sql + ' SELECT @MatchVal = ' + @tgtTableIDCol
    set @sql = @sql + ' FROM ' + @tgtTableName
    set @sql = @sql + ' WHERE ' + @tgtTableIDCol + ' = ' + Convert(varchar(12), @sourceEntityID)

    exec sp_executesql @sql, N'@MatchVal int output', @MatchVal = @MatchVal output
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myRowCount <> 1 Or @MatchVal Is Null
    Begin
        set @msg = 'Source ID ' + Convert(varchar(12), @sourceEntityID) + ' not found in ' + @tgtTableName
        RAISERROR (@msg, 10, 1)
        return 51002
    End


    ---------------------------------------------------
    -- Populate a temporary table with the IDs in @targetEntityIDList
    ---------------------------------------------------

    CREATE TABLE #Tmp_TargetEntities (
        EntityID int,
        Valid tinyint Default 0
    )

    INSERT INTO #Tmp_TargetEntities( EntityID,
                                     Valid )
    SELECT DISTINCT Convert(int, Item),
                    0 AS Valid
    FROM dbo.MakeTableFromList ( @targetEntityIDList )
    WHERE (Len(IsNull(Item, '')) > 0)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Look for unknown IDs in #Tmp_TargetEntities
    ---------------------------------------------------

    Set @sql = ''
    Set @sql = @sql + ' UPDATE #Tmp_TargetEntities'
    Set @sql = @sql + ' SET Valid = 1'
    Set @sql = @sql + ' FROM #Tmp_TargetEntities TE INNER JOIN '
    Set @sql = @sql + @tgtTableName + ' T ON TE.EntityID = T.' + @tgtTableIDCol

    Exec (@sql)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    -- Create a list of Entitites that have Valid = 0 in #Tmp_TargetEntities
    Declare @IDList varchar(400)
    Declare @IDListMaxLength int
    Set @IDListMaxLength = 200

    Set @IDList = ''
    SELECT @IDList = @IDList + CASE WHEN Len(@IDList) < @IDListMaxLength
                               THEN Convert(varchar(12), EntityID) + ', '
                               ELSE '.' END
    FROM #Tmp_TargetEntities
    WHERE Valid = 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        -- Unknown entries found; inform the caller

        -- Remove the trailing comma
        Set @IDList = Left(@IDList, Len(@IDList)-1)

        -- Make sure the list is no longer than @IDListMaxLength+15 characters
        If Len(@IDList) > @IDListMaxLength+15
            Set @IDList = Left(@IDList, @IDListMaxLength+15)

        If @myRowCount = 1
            Set @msg = 'Error: Target ID ' + @IDList + ' is not defined in ' + @tgtTableName + '; unable to continue'
        Else
            Set @msg = 'Error: found ' + Convert(varchar(12), @myRowCount) + ' invalid target IDs not defined in ' + @tgtTableName + ': ' + @IDList

        RAISERROR (@msg, 10, 1)
        return 51003
    End

    ---------------------------------------------------
    -- Generate a list of the IDs in #Tmp_TargetEntities
    ---------------------------------------------------

    Set @IDList = ''
    SELECT @IDList = @IDList + CASE WHEN Len(@IDList) < @IDListMaxLength
                               THEN Convert(varchar(12), EntityID) + ', '
                               ELSE '.' END
    FROM #Tmp_TargetEntities
    ORDER BY EntityID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        -- Remove the trailing comma
        Set @IDList = Left(@IDList, Len(@IDList)-1)

        -- Make sure the list is no longer than @IDListMaxLength+15 characters
        If Len(@IDList) > @IDListMaxLength+15
            Set @IDList = Left(@IDList, @IDListMaxLength+15)
    End
    Else
    Begin
        -- No entries found
        Set @msg = 'Error: Target ID list was empty (or invalid); unable to continue'

        RAISERROR (@msg, 10, 1)
        return 51004
    End


    ---------------------------------------------------
    -- copy existing values in aux info table
    -- for given target name and category
    -- from given source target entity
    -- to given destination entities
    ---------------------------------------------------

    Declare @transName varchar(32)

    if @mode = 'copyCategory'
    begin
        -- Start transaction
        --
        set @transName = 'CopyAuxInfo-copyCategory'
        begin transaction @transName

        -- delete any existing values
        --
        DELETE FROM T_AuxInfo_Value
        WHERE (Target_ID IN ( SELECT EntityID
                              FROM #Tmp_TargetEntities )) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = @targetName) AND
                                             (Category = @categoryName) ))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Delete failed for copy into target IDs: "' + @IDList + '"'
            RAISERROR (@msg, 10, 1)
            rollback transaction
            return 51001
        end

        -- insert new values
        --
        INSERT INTO T_AuxInfo_Value( Target_ID,
                                     Aux_Description_ID,
                                     Value )
        SELECT TE.EntityID AS Target_ID,
               AI.Aux_Description_ID,
               AI.Value
        FROM T_AuxInfo_Value AI
             CROSS JOIN #Tmp_TargetEntities TE
        WHERE (AI.Target_ID = @sourceEntityID) AND
              (AI.Aux_Description_ID IN ( SELECT Item_ID
                                          FROM V_Aux_Info_Definition
                                          WHERE (Target = @targetName) AND
                                                (Category = @categoryName) ))

        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Insert failed for copy into target IDs: "' + @IDList + '"'
            RAISERROR (@msg, 10, 1)
            rollback transaction
            return 51000
        end
        commit transaction @transName
    end

    ---------------------------------------------------
    -- copy existing values in aux info table
    -- for given target name and category and subcategory
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    if @mode = 'copySubcategory'
    begin
        -- Start transaction
        --
        set @transName = 'CopyAuxInfo-copySubcategory'
        begin transaction @transName

        -- delete any existing values
        --
        DELETE FROM T_AuxInfo_Value
        WHERE (Target_ID IN ( SELECT EntityID
                              FROM #Tmp_TargetEntities )) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = @targetName) AND
                                             (Category = @categoryName) AND
                                             (Subcategory = @subCategoryName) ))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Delete failed for copy into target IDs: "' + @IDList + '"'
            RAISERROR (@msg, 10, 1)
            rollback transaction
            return 51001
        end

        -- insert new values
        --
        INSERT INTO T_AuxInfo_Value( Target_ID,
                                     Aux_Description_ID,
                                     Value )
        SELECT TE.EntityID AS Target_ID,
               AI.Aux_Description_ID,
               AI.Value
        FROM T_AuxInfo_Value AI
             CROSS JOIN #Tmp_TargetEntities TE
        WHERE (AI.Target_ID = @sourceEntityID) AND
              (AI.Aux_Description_ID IN ( SELECT Item_ID
                                          FROM V_Aux_Info_Definition
                                          WHERE (Target = @targetName) AND
                                                (Category = @categoryName) AND
                                                (Subcategory = @subCategoryName) ))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Insert failed for copy into target IDs: "' + @IDList + '"'
            RAISERROR (@msg, 10, 1)
            rollback transaction
            return 51000
        end
        commit transaction @transName
    end

    ---------------------------------------------------
    -- copy existing values in aux info table
    -- for given target name
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    if @mode = 'copyAll'
    begin
        -- Start transaction
        --
        set @transName = 'CopyAuxInfo-copyAll'
        begin transaction @transName

        -- delete any existing values
        --
        DELETE FROM T_AuxInfo_Value
        WHERE (Target_ID IN ( SELECT EntityID
                              FROM #Tmp_TargetEntities )) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = @targetName) ))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Delete failed for copy into target IDs: "' + @IDList + '"'
            RAISERROR (@msg, 10, 1)
            rollback transaction
            return 51001
        end

        --
        INSERT INTO T_AuxInfo_Value( Target_ID,
                                     Aux_Description_ID,
                                     Value )
        SELECT TE.EntityID AS Target_ID,
               AI.Aux_Description_ID,
               AI.Value
        FROM T_AuxInfo_Value AI
             CROSS JOIN #Tmp_TargetEntities TE
        WHERE (AI.Target_ID = @sourceEntityID) AND
              (AI.Aux_Description_ID IN ( SELECT Item_ID
                                          FROM V_Aux_Info_Definition
                                          WHERE (Target = @targetName) ))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Insert failed for copy into target IDs: "' + @IDList + '"'
            RAISERROR (@msg, 10, 1)
            rollback transaction
            return 51000
        end
        commit transaction @transName
    end


    ---------------------------------------------------
    -- Exit the procedure
    ---------------------------------------------------
Done:
    return 0


GO
GRANT VIEW DEFINITION ON [dbo].[CopyAuxInfoMultiID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[CopyAuxInfoMultiID] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyAuxInfoMultiID] TO [Limited_Table_Write] AS [dbo]
GO
