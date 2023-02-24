/****** Object:  StoredProcedure [dbo].[AddUpdateAuxInfoDefinition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateAuxInfoDefinition]
/****************************************************
**
**  Desc:
**    Adds new or updates definition of
**    auxiliary information in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   04/19/2002 grk - Initial release
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/16/2022 mem - Auto change @targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column names
**          11/21/2022 mem - Use new aux info table and column names
**
*****************************************************/
(
    @mode varchar(32) = 'UpdateItem', -- 'AddTarget', 'AddCategory', 'AddSubcategory', 'AddItem', 'AddAllowedValue'
    @targetName varchar(128) = 'Cell Culture',
    @categoryName varchar(128) = 'Prokaryote',
    @subCategoryName varchar(128) = 'Starter Culture Conditions',
    @itemName varchar(128) = 'Date Started',
    @seq int = 1,
    @param1 varchar(128) = '',
    @param2 varchar(128) = '',
    @param3 varchar(128) = '',
    @message varchar(512) output
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @targetTypeID int
    Declare @categoryID int
    Declare @subcategoryID int
    Declare @descriptionID int
    Declare @tmpSeq int
    Declare @tmpID int

    Declare @msg varchar(256)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateAuxInfoDefinition', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    If @mode <> 'AddTarget' And @targetName = 'Cell Culture' And Exists (Select * From T_Aux_Info_Target Where Target_Type_Name = 'Biomaterial')
    Begin
        Set @targetName = 'Biomaterial'
    End

    ---------------------------------------------------
    -- Add Target
    ---------------------------------------------------

    if @mode = 'AddTarget'
    begin
        -- future: verify correctness of
        -- Target_Table, Target_ID_Col, Target_Name_Col

        -- is target already in table?
        --
        set @tmpID = 0
        --
        SELECT @tmpID = Target_Type_ID
        FROM T_Aux_Info_Target
        WHERE Target_Type_Name = @TargetName
           --
        if @tmpID <> 0
        begin
            set @msg = 'Cannot add: target already exists'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- insert new target into table
        --
        INSERT INTO T_Aux_Info_Target
           (Target_Type_Name, Target_Table, Target_ID_Col, Target_Name_Col)
        VALUES (@TargetName, @Param1, @Param2, @Param3)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 or @myRowCount <> 1
        begin
            set @msg = 'Insert target failed'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

    end -- mode 'AddTarget'

    ---------------------------------------------------
    -- Add Category
    ---------------------------------------------------

    if @mode = 'AddCategory'
    begin
        -- resolve parent target type to ID
        --
        set @targetTypeID = 0
        --
        SELECT @targetTypeID = Target_Type_ID
        FROM T_Aux_Info_Target
        WHERE Target_Type_Name = @TargetName
        --
        if @targetTypeID = 0
        begin
            set @msg = 'Could not resolve parent target type'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- is category already in table?
        --
        set @tmpID = 0
        --
        SELECT @tmpID = Aux_Category_ID
        FROM T_Aux_Info_Category
        WHERE (Target_Type_ID = @targetTypeID) AND (Aux_Category = @categoryName)
           --
        if @tmpID <> 0
        begin
            set @msg = 'Cannot add: category already exists for this target'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- calculate new sequence
        --
        set @tmpSeq = 0
        --
        SELECT @tmpSeq = ISNULL(MAX(Sequence), 0)
        FROM T_Aux_Info_Category
        WHERE (Target_Type_ID = @targetTypeID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        -- future: check error?
        --
        set @tmpSeq = @tmpSeq + 1

        -- insert new category for parent target type
        --
        INSERT INTO T_Aux_Info_Category
           (Aux_Category, Target_Type_ID, Sequence)
        VALUES (@categoryName, @targetTypeID, @tmpSeq)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 or @myRowCount <> 1
        begin
            set @msg = 'Insert category failed'
            RAISERROR (@msg, 10, 1)
            return 51000
        end
    end -- mode 'AddCategory'

    ---------------------------------------------------
    -- Add Subcategory
    ---------------------------------------------------

    if @mode = 'AddSubcategory'
    begin
        -- resolve parent category names to ID
        --
        set @categoryID = 0
        --
        SELECT @categoryID = T_Aux_Info_Category.Aux_Category_ID
        FROM T_Aux_Info_Target
             INNER JOIN T_Aux_Info_Category
               ON T_Aux_Info_Target.Target_Type_ID = T_Aux_Info_Category.Target_Type_ID
        WHERE (T_Aux_Info_Target.Target_Type_Name = @targetName) AND
              (T_Aux_Info_Category.Aux_Category = @categoryName)
           --
        if @categoryID = 0
        begin
            set @msg = 'Could not resolve parent category name for given target type'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- is subcategory already in table?
        --
        set @tmpID = 0
        --
        SELECT @tmpID = Aux_Subcategory_ID
        FROM T_Aux_Info_Subcategory
        WHERE (Aux_Category_ID = @categoryID) AND (Aux_Subcategory = @subcategoryName)
        --
        if @tmpID <> 0
        begin
            set @msg = 'Cannot add: subcategory already exists for this target'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- calculate new sequence
        --
        set @tmpSeq = 0
        --
        SELECT @tmpSeq = ISNULL(MAX(Sequence), 0)
        FROM T_Aux_Info_Subcategory
        WHERE (Aux_Category_ID = @categoryID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        -- future: check error?
        --
        set @tmpSeq = @tmpSeq + 1

        -- insert new subcategory for parent category
        --
        INSERT INTO T_Aux_Info_Subcategory
           (Aux_Subcategory, Sequence, Aux_Category_ID)
        VALUES (@subcategoryName, @tmpSeq, @categoryID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 or @myRowCount <> 1
        begin
            set @msg = 'Insert subcategory failed'
            RAISERROR (@msg, 10, 1)
            return 51000
        end
    end -- mode 'AddSubcategory'

    ---------------------------------------------------
    -- Add Item
    ---------------------------------------------------

    if @mode = 'AddItem'
    begin
        -- resolve parent subcategory names to ID
        --
        set @subcategoryID = 0
        --
        SELECT @subcategoryID = T_Aux_Info_Subcategory.Aux_Subcategory_ID
        FROM T_Aux_Info_Target
             INNER JOIN T_Aux_Info_Category
               ON T_Aux_Info_Target.Target_Type_ID = T_Aux_Info_Category.Target_Type_ID
             INNER JOIN T_Aux_Info_Subcategory
               ON T_Aux_Info_Category.Aux_Category_ID = T_Aux_Info_Subcategory.Aux_Category_ID
        WHERE (T_Aux_Info_Target.Target_Type_Name = @targetName) AND
              (T_Aux_Info_Category.Aux_Category = @categoryName) AND
              (T_Aux_Info_Subcategory.Aux_Subcategory = @subcategoryName)
        --
        if @subcategoryID = 0
        begin
            set @msg = 'Could not resolve parent subcategory for given category and target type'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- is item already in table?
        --
        set @tmpID = 0
        --
        SELECT @tmpID = Aux_Description_ID
        FROM T_Aux_Info_Description
        WHERE (Aux_Subcategory_ID = @subcategoryID) AND (Aux_Description = @itemName)
        --
        if @tmpID <> 0
        begin
            set @msg = 'Cannot add: item already exists for this target'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- calculate new sequence
        --
        set @tmpSeq = 0
        --
        SELECT @tmpSeq = ISNULL(MAX(Sequence), 0)
        FROM T_Aux_Info_Description
        WHERE (Aux_Subcategory_ID = @subcategoryID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        -- future: check error?
        --
        set @tmpSeq = @tmpSeq + 1

        -- insert new item for parent subcategory
        --
        INSERT INTO T_Aux_Info_Description
           (Aux_Description, Aux_Subcategory_ID, Sequence, DataSize, HelperAppend)
        VALUES (@itemName, @subcategoryID, @tmpSeq, @Param1, @Param2)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 or @myRowCount <> 1
        begin
            set @msg = 'Insert item failed'
            RAISERROR (@msg, 10, 1)
            return 51000
        end
    end -- mode 'AddItem'


    ---------------------------------------------------
    -- Add Allowed Value
    ---------------------------------------------------

    if @mode = 'AddAllowedValue'
    begin
        -- resolve parent description names to ID
        --
        set @descriptionID = 0
        --
        SELECT @descriptionID = T_Aux_Info_Description.Aux_Description_ID
        FROM T_Aux_Info_Target
             INNER JOIN T_Aux_Info_Category
               ON T_Aux_Info_Target.Target_Type_ID = T_Aux_Info_Category.Target_Type_ID
             INNER JOIN T_Aux_Info_Subcategory
               ON T_Aux_Info_Category.Aux_Category_ID = T_Aux_Info_Subcategory.Aux_Category_ID
             INNER JOIN T_Aux_Info_Description
               ON T_Aux_Info_Subcategory.Aux_Subcategory_ID = T_Aux_Info_Description.Aux_Subcategory_ID
        WHERE (T_Aux_Info_Target.Target_Type_Name = @targetName) AND
              (T_Aux_Info_Category.Aux_Category = @categoryName) AND
              (T_Aux_Info_Subcategory.Aux_Subcategory = @subcategoryName) AND
              (T_Aux_Info_Description.Aux_Description = @itemName)
        --
        if @descriptionID = 0
        begin
            set @msg = 'Could not resolve parent description ID for given subcategory, category, and target type'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- is item already in table?
        --
        set @tmpID = 0
        --
        SELECT @tmpID = Aux_Description_ID
        FROM T_Aux_Info_Allowed_Values
        WHERE (Aux_Description_ID = @descriptionID) AND (Value = @Param1)
        --
        if @tmpID <> 0
        begin
            set @msg = 'Cannot add: allowed value already exists for this target'
            RAISERROR (@msg, 10, 1)
            return 51000
        end


        -- insert new allowed value for parent description ID
        --
        INSERT INTO T_Aux_Info_Allowed_Values
           (Aux_Description_ID, Value)
        VALUES (@descriptionID, @Param1)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 or @myRowCount <> 1
        begin
            set @msg = 'Insert item failed'
            RAISERROR (@msg, 10, 1)
            return 51000
        end
    end -- mode 'AddAllowedValue'


    ---------------------------------------------------
    -- Update Item
    ---------------------------------------------------

    if @mode = 'UpdateItem'
    begin
        -- find item ID
        --
        set @tmpID = 0
        --
        SELECT @tmpID = Item_ID
        FROM V_Aux_Info_Definition
        WHERE (Target = @targetName) AND
              (Category = @categoryName) AND
              (Subcategory = @subcategoryName) AND
              (Item = @itemName)
        --
        if @tmpID = 0
        begin
            set @msg = 'Cannot resolve item name to ID'
            RAISERROR (@msg, 10, 1)
            return 51000
        end

        -- get current values of stuff
        -- so that blank input values can default
        --
        Declare @Sequence tinyInt
        Declare @DataSize int
        Declare @HelperAppend char(1)
        --
        SELECT
            @Sequence = Sequence,
            @DataSize = DataSize,
            @HelperAppend = HelperAppend
        FROM T_Aux_Info_Description
        WHERE (Aux_Description_ID = @tmpID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'could not get current value of item'
            RAISERROR (@msg, 10, 1)
            return 51000
        end
        --
        if @seq <> 0
        begin
            set @Sequence = @seq
        end
        --
        if @Param1 <> ''
        begin
            set @DataSize = @Param1
        end
        --
        if @Param2 <> ''
        begin
            set @HelperAppend = @Param2
        end

        -- update item
        --
        UPDATE T_Aux_Info_Description
        SET
            Sequence = @Sequence,
            DataSize = @DataSize,
            HelperAppend = @HelperAppend
        WHERE (Aux_Description_ID = @tmpID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Update item failed'
            RAISERROR (@msg, 10, 1)
            return 51000
        end
    end -- mode 'UpdateItem'

    return 0


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfoDefinition] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfoDefinition] TO [Limited_Table_Write] AS [dbo]
GO
