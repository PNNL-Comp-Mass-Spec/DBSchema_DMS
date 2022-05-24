/****** Object:  StoredProcedure [dbo].[DoMaterialItemOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[DoMaterialItemOperation]
/****************************************************
**
**  Desc: Do an operation on an item, using the item name
**
**  Return values: 0: success, otherwise, error code
**
**  Auth: grk
**  Date: 07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**        10/01/2009 mem - Expanded error message
**        08/19/2010 grk - Add try-catch for error handling
**        02/23/2016 mem - Add Set XACT_ABORT on
**        04/12/2017 mem - Log exceptions to T_Log_Entries
**        06/16/2017 mem - Restrict access using VerifySPAuthorized
**        08/01/2017 mem - Use THROW if not authorized
**        09/25/2019 mem - Allow @name to be an experiment ID, which happens if "Retire Experiment" is clicked at https://dms2.pnl.gov/experimentid/show/123456
**        05/24/2022 mem - Validate parameters
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
    @name varchar(128),                    -- Item name (biomaterial name, experiment name, or experiment ID)
    @mode varchar(32),                    -- 'retire_biomaterial', 'retire_experiment'
    @message varchar(512) output,
    @callingUser varchar (128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @logErrors Tinyint = 0
    Declare @msg varchar(512)
    Declare @experimentID int

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'DoMaterialItemOperation', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY 

    ---------------------------------------------------
    -- Verify input values
    ---------------------------------------------------

    Set @name = IsNull(@name, '')
    Set @mode = IsNull(@mode, '')

    If @mode = ''
    Begin
        Set @msg = 'Material item operation mode not defined'
        RAISERROR (@msg, 11, 1)
    End

    If Not @mode In ('retire_biomaterial', 'retire_experiment')
    Begin
        Set @msg = 'Material item operation mode must be retire_biomaterial or retire_experiment, not ' + @mode
        RAISERROR (@msg, 11, 1)
    End
    
    If @name = ''
    Begin
        Set @msg = 'Material name not defined; cannot retire'
        RAISERROR (@msg, 11, 1)
    End

    ---------------------------------------------------
    -- Convert name to ID
    ---------------------------------------------------
    Declare @tmpID Int = 0
    Declare @type_tag varchar(2) = ''

    If @mode = 'retire_biomaterial'
    Begin
        -- Look up cell culture ID from the name
        Set @type_tag = 'B'
        --
        SELECT @tmpID = CC_ID
        FROM T_Cell_Culture
        WHERE CC_Name = @name    
    End

    If @mode = 'retire_experiment'
    Begin
        -- Look up experiment ID from the name or ID
        Set @type_tag = 'E'

        Set @experimentID = Try_Cast(@name as Int)

        If IsNull(@experimentID, 0) > 0 And Not Exists (SELECT * FROM T_Experiments WHERE Experiment_Num = @name)
        Begin
            Set @tmpID = @experimentID
        End
        Else
        Begin
            SELECT @tmpID = Exp_ID
            FROM T_Experiments
            WHERE Experiment_Num = @name
        End
    End
    
    If @tmpID = 0
    Begin
        Set @msg = 'Could not find the material item for mode "' + @mode + '", name "' + @name + '"'
        RAISERROR (@msg, 11, 1)
    End
    Else
    Begin

        Set @logErrors = 1

        ---------------------------------------------------
        -- Call the material update function
        ---------------------------------------------------
        --
        Declare 
            @iMode varchar(32),
            @itemList varchar(4096),
            @itemType varchar(128),
            @newValue varchar(128),
            @comment varchar(512)

            Set @iMode = 'retire_items'
            Set @itemList  = @type_tag + ':' + convert(varchar, @tmpID)
            Set @itemType  = 'mixed_material'
            Set @newValue  = ''
            Set @comment  = ''

        exec @myError = UpdateMaterialItems
                @iMode,         -- 'retire_item'
                @itemList,
                @itemType,      -- 'mixed_material'
                @newValue,
                @comment,
                @msg output,
                @callingUser
        
        If @myError <> 0
        Begin
            RAISERROR (@msg, 11, 1)
        End
    End

    End TRY
    Begin CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
        
        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @message, 'DoMaterialItemOperation'
        End
    End Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialItemOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoMaterialItemOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialItemOperation] TO [Limited_Table_Write] AS [dbo]
GO
