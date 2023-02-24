/****** Object:  StoredProcedure [dbo].[AddUpdateAuxInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateAuxInfo]
/****************************************************
**
**  Adds new or updates existing auxiliary information in database
**
**  Auth:   grk
**  Date:   03/27/2002 grk - Initial release
**          12/18/2007 grk - Improved ability to handle target ID if supplied as target name
**          06/30/2008 jds - Added error message to "Resolve target name and entity name to entity ID" section
**          05/15/2009 jds - Added a return if just performing a check_add or check_update
**          08/21/2010 grk - try-catch for error handling
**          02/20/2012 mem - Now using temporary tables to parse @itemNameList and @itemValueList
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/10/2018 mem - Remove invalid check of @mode against check_add or check_update
**          11/19/2018 mem - Pass 0 to the @maxRows parameter to udfParseDelimitedListOrdered
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/16/2022 mem - Auto change @targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new aux info table and column names
**          11/29/2022 mem - Require that @targetEntityName be an integer when @targetName is SamplePrepRequest
**
*****************************************************/
(
    @targetName varchar(128) = '',          -- Experiment, Biomaterial (previously 'Cell Culture'), Dataset, or SamplePrepRequest
    @targetEntityName varchar(128) = '',    -- Target entity ID or name
    @categoryName varchar(128) = '',
    @subCategoryName varchar(128) = '',
    @itemNameList varchar(4000) = '',       -- AuxInfo names to update; delimiter is !
    @itemValueList varchar(3000) = '',      -- AuxInfo values; delimiter is !
    @mode varchar(12) = 'add',              -- add, update, check_add, check_update, or check_only
    @message varchar(512) = '' output
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int= 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateAuxInfo', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY

    ---------------------------------------------------
    -- What mode are we in
    ---------------------------------------------------

    Set @mode = Coalesce(@mode, 'Undefined_mode')

    If @mode In ('check_update', 'check_add')
    Begin
        Set @mode = 'check_only'
    End

    If Not @mode In ('add', 'update', 'check_only')
    Begin
        Set @msg = 'Invalid @mode: ' + @mode
        RAISERROR (@msg, 11, 1)
    End

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------
    
    Set @targetName = Ltrim(Rtrim(Coalesce(@targetName, '')))
    Set @targetEntityName = Ltrim(Rtrim(Coalesce(@targetEntityName, '')))
    Set @categoryName = Ltrim(Rtrim(Coalesce(@categoryName, '')))
    Set @subCategoryName = Ltrim(Rtrim(Coalesce(@subCategoryName, '')))
    Set @itemNameList = Ltrim(Rtrim(Coalesce(@itemNameList, '')))
    Set @itemValueList = Ltrim(Rtrim(Coalesce(@itemValueList, '')))

    If @targetName = 'Cell Culture' And Exists (Select * From T_Aux_Info_Target Where Target_Type_Name = 'Biomaterial')
    Begin
        Set @targetName = 'Biomaterial'
    End

    ---------------------------------------------------
    -- For sample prep requests, @targetEntityName should have a sample prep request ID
    -- For experiments and biomaterial, it can have experiment name, experiment ID, biomaterial name, or biomaterial ID
    -- If the value is an integer, we will assume it is experiment ID or biomaterial ID, since experiment names and biomaterial names should not be integers
    ---------------------------------------------------

    Declare @targetID int = 0
    
    Set @targetID = Try_Parse(@targetEntityName as int)

    If @targetName = 'SamplePrepRequest' And @targetID Is Null
    Begin
        Set @msg = 'Cannot update aux info for the sample prep request since argument @targetEntityName is not an integer: ' + @targetEntityName
        RAISERROR (@msg, 11, 1)
    End 
    Else If @targetID Is Null
    Begin -- <a1>
        ---------------------------------------------------
        -- Resolve target name to target table criteria
        ---------------------------------------------------
        --
        Declare @tgtTableName varchar(128)
        Declare @tgtTableNameCol varchar(128)
        Declare @tgtTableIDCol varchar(128)

        SELECT
            @tgtTableName = Target_Table,
            @tgtTableIDCol = Target_ID_Col,
            @tgtTableNameCol = Target_Name_Col
        FROM T_Aux_Info_Target
        WHERE Target_Type_Name = @targetName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 or @myRowCount <> 1
        Begin
            Set @msg = 'Could not look up table criteria for target: "' + @targetName + '"'
            RAISERROR (@msg, 11, 1)
        End

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

        If @mode <> 'check_only'
        Begin --<b1>
            ---------------------------------------------------
            -- Resolve target name and entity name to entity ID
            ---------------------------------------------------

            Declare @sql nvarchar(1024)

            Set @sql = N' SELECT @targetID = ' + @tgtTableIDCol +
                        ' FROM ' + @tgtTableName +
                        ' WHERE ' + @tgtTableNameCol +
                          ' = ''' + @targetEntityName + ''''

            exec sp_executesql @sql, N'@targetID  int output', @targetID = @targetID  output

            If @targetID = 0
            Begin
                Set @msg = 'Could not resolve target name and entity name to entity ID: "' + @targetEntityName + '" '
                RAISERROR (@msg, 11, 2)
            End
        End -- </b1>
    End -- </a1>

    ---------------------------------------------------
    -- If list is empty, we are done
    ---------------------------------------------------

    If LEN(@itemNameList) = 0
        return 0

    ---------------------------------------------------
    -- Populate temorary tables using @itemNameList and @itemValueList
    ---------------------------------------------------

    Declare @tblAuxInfoNames Table
    (
        EntryID int,
        ItemName varchar(256)
    )

    Declare @tblAuxInfoValues Table
    (
        EntryID int,
        ItemValue varchar(256)
    )

    INSERT INTO @tblAuxInfoNames (EntryID, ItemName)
    SELECT EntryID, Value
    FROM dbo.udfParseDelimitedListOrdered(@itemNameList, '!', 0)
    ORDER BY EntryID


    INSERT INTO @tblAuxInfoValues (EntryID, ItemValue)
    SELECT EntryID, Value
    FROM dbo.udfParseDelimitedListOrdered(@itemValueList, '!', 0)
    ORDER BY EntryID


    Declare @done int = 0
    Declare @count int = 0
    Declare @EntryID int = -1

    Declare @descriptionID int

    Declare @inFld varchar(128)
    Declare @vFld varchar(128)
    Declare @tVal varchar(128)

    ---------------------------------------------------
    -- Process @tblAuxInfoNames
    ---------------------------------------------------

    While @done = 0
    Begin -- <a2>

        SELECT TOP 1 @EntryID = EntryID,
                     @inFld = ItemName
        FROM @tblAuxInfoNames
        WHERE EntryID > @EntryID
        ORDER BY EntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @Done = 1

        If @myRowCount = 1 And Len(IsNull(@inFld, '')) > 0
        Begin -- <b2>

            Set @count = @count + 1

            -- Lookup the value for this aux info entry
            --
            Set @vFld = ''
            --
            SELECT @vFld = ItemValue
            FROM @tblAuxInfoValues
            WHERE EntryID = @EntryID

            -- Resolve item name to aux description ID
            --
            Set @descriptionID = 0

            SELECT @descriptionID = Item_ID
            FROM V_Aux_Info_Definition
            WHERE Target = @targetName AND
                  Category = @categoryName AND
                  Subcategory = @subCategoryName AND
                  Item = @inFld
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0 or @descriptionID = 0
            Begin
                Set @msg = 'Could not resolve item to ID: "' + @inFld + '" for category ' + @categoryName + ', subcategory ' + @subCategoryName
                RAISERROR (@msg, 11, 1)
            End

            If @mode <> 'check_only'
            Begin --<c>
                -- If value is blank, delete any existing entry from value table
                --
                If @vFld = ''
                Begin
                    DELETE FROM T_Aux_Info_Value
                    WHERE Aux_Description_ID = @descriptionID AND Target_ID = @targetID
                End
                Else
                Begin -- <d>

                    -- Does entry exist in value table?
                    --
                    SELECT @tVal = [Value]
                    FROM T_Aux_Info_Value
                    WHERE Aux_Description_ID = @descriptionID AND Target_ID = @targetID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                    --
                    If @myError <> 0
                    Begin
                        Set @msg = 'Error in searching for existing value for item: "' + @inFld + '"'
                        RAISERROR (@msg, 11, 1)
                    End

                    -- If entry exists in value table, update it
                    -- otherwise insert it
                    --
                    If @myRowCount > 0
                    Begin
                        If @tVal <> @vFld
                        Begin
                            UPDATE T_Aux_Info_Value
                            SET [Value] = @vFld
                            WHERE Aux_Description_ID = @descriptionID AND Target_ID = @targetID
                        End
                    End
                    Else
                    Begin
                        INSERT INTO T_Aux_Info_Value( Target_ID,
                                                     Aux_Description_ID,
                                                     [Value] )
                        VALUES(@targetID, @descriptionID, @vFld)
                    End

                End -- </d>

            End -- </c>

        End -- </b2>
    End -- </a2>

    End TRY
    Begin CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    End CATCH

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfo] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAuxInfo] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateAuxInfo] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateAuxInfo] TO [Limited_Table_Write] AS [dbo]
GO
