/****** Object:  StoredProcedure [dbo].[AddUpdateInstrumentClass] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[AddUpdateInstrumentClass]
/****************************************************
**
**  Desc:   Updates existing Instrument Class in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   07/06/2006
**          07/25/2007 mem - Added parameter @allowedDatasetTypes
**          09/17/2009 mem - Removed parameter @allowedDatasetTypes (Ticket #748)
**          06/21/2010 mem - Added parameter @params
**          11/16/2010 mem - Added parameter @comment
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2018 mem - Add try/catch handling and disallow @mode = 'add'
**    
*****************************************************/
(
    @instrumentClass varchar(32), 
    @isPurgable varchar(1), 
    @rawDataType varchar(32), 
    @requiresPreparation varchar(1), 
    @params text,
    @comment varchar(255),
    @mode varchar(12) = 'update',       -- Note that 'add' is not allowed in this procedure; instead directly edit table T_Instrument_Class
    @message varchar(512) output
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @msg varchar(256)

    Declare @xmlParams xml

    Set @message = ''
    
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'AddUpdateInstrumentClass', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;
          
    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @myError = 0
    If LEN(@instrumentClass) < 1
    Begin;
        THROW 51000, 'Instrument Class Name cannot be blank', 1;
    End;

    If LEN(@isPurgable) < 1
    Begin;
        THROW 51001, 'Is Purgable cannot be blank', 1;
    End;
    --
    If LEN(@rawDataType) < 1
    Begin;
        THROW 51002, 'Raw Data Type cannot be blank', 1;
    End;
    --
    If LEN(@requiresPreparation) < 1
    Begin;
        THROW 51003, 'Requires Preparation cannot be blank', 1;
    End;
    --
    If @myError <> 0
        return @myError

    
    Set @params = IsNull(@params, '')
    If DataLength(@params) > 0
    Begin
        Set @xmlParams = Try_Cast(@params As Xml)
        If @xmlParams Is Null
        Begin;
            Set @message = 'Could not convert Params to XML';
            THROW 51004, @message, 1;
        End;
    End

    ---------------------------------------------------
    -- Note: the add mode is not enabled in this stored procedure
    ---------------------------------------------------
    If @mode = 'add'
    Begin;
        THROW 51005, 'The "add" instrument class mode is disabled for this page; instead directly edit table T_Instrument_Class', 1;
    End;

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update' 
    Begin
        Set @logErrors = 1

        Set @myError = 0
        --
        UPDATE T_Instrument_Class
        SET 
            is_purgable = @isPurgable, 
            raw_data_type = @rawDataType, 
            requires_preparation = @requiresPreparation,
            Params = @xmlParams,
            Comment = @comment
        WHERE (IN_class = @instrumentClass)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin;
            Set @message = 'Update operation failed: "' + @instrumentClass + '"';
            THROW 51004, @message, 1;
            return 51004
        End;

    End -- update mode
    
    END Try
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError Output
        
        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Instrument class ' + @instrumentClass
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateInstrumentClass'
        End

    END Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentClass] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrumentClass] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrumentClass] TO [Limited_Table_Write] AS [dbo]
GO
