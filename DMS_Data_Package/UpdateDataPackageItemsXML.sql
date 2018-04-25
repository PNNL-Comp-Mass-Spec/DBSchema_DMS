/****** Object:  StoredProcedure [dbo].[UpdateDataPackageItemsXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateDataPackageItemsXML
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      This procedure is used by web page "Data Package Items List Report page" (data_package_items/report)
**
**      Example contents of @paramListXML
**      <item pkg="194" type="Job" id="913603"></item><item pkg="194" type="Job" id="913604"></item>
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/10/2009 grk - initial release
**          05/23/2010 grk - factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/19/2016 mem - Update #TPI to use an integer field for data package ID
**          11/11/2016 mem - Add parameter @removeParents
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          04/25/2018 mem - Assure that @removeParents is not null
**
*****************************************************/
(
    @paramListXML varchar(max),
    @comment varchar(512),
    @mode varchar(12) = 'update',           -- 'add', 'update', 'comment', 'delete'
    @removeParents tinyint = 0,             -- When 1, remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''
    
    Declare @itemCountChanged int
    set @itemCountChanged = 0

    Declare @wasModified int
    set @wasModified = 0

    -- these are necessary to avoid XML throwing errors
    -- when this stored procedure is called from web page
    --
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_NULLS ON
    SET ANSI_PADDING ON
    SET ANSI_WARNINGS ON

    BEGIN TRY 
    
        ---------------------------------------------------
        -- Verify that the user can execute this procedure from the given client host
        ---------------------------------------------------
            
        Declare @authorized tinyint = 0    
        Exec @authorized = VerifySPAuthorized 'UpdateDataPackageItemsXML', @raiseError = 1
        If @authorized = 0
        Begin
            RAISERROR ('Access denied', 11, 3)
        End

        Set @removeParents = IsNull(@removeParents, 0)

        -- Set this to 1 to debug
        Declare @logUsage tinyint = 0
        
        If @logUsage > 0
        Begin
            Declare @logMessage varchar(4000)
            Set @logMessage = 'Mode: ' + 
                              IsNull(@mode, 'Null mode') + '; ' + 
                              'RemoveParents: ' + Cast(@removeParents as varchar(2)) + '; ' + 
                              IsNull(@paramListXML, 'Error: @paramListXML is null')
            Exec PostLogEntry 'Debug', @logMessage, 'UpdateDataPackageItemsXML'
        End
        
        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in @paramListXML
        ---------------------------------------------------
        --
        CREATE TABLE #TPI(
            DataPackageID int not null,     -- Data package ID
            Type varchar(50) null,          -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier varchar(256) null    -- Job ID, Dataset ID, Experiment Id, Cell_Culture ID, or EUSProposal ID
        )

        Declare @xml xml
        set @xml = @paramListXML

        INSERT INTO #TPI (DataPackageID, Type, Identifier)
        SELECT 
            xmlNode.value('@pkg', 'int') [Package],
            xmlNode.value('@type', 'varchar(50)') [Type],
            xmlNode.value('@id', 'varchar(256)') [Identifier]
        FROM   @xml.nodes('//item') AS R(xmlNode)

        ---------------------------------------------------
        exec @myError = UpdateDataPackageItemsUtility
                                @comment,
                                @mode,
                                @removeParents,
                                @message output,
                                @callingUser
        if @myError <> 0
            RAISERROR(@message, 11, 14)
        
     ---------------------------------------------------
     ---------------------------------------------------
    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        Declare @msgForLog varchar(512) = ERROR_MESSAGE()
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
        
        Exec PostLogEntry 'Error', @msgForLog, 'UpdateDataPackageItemsXML'
    END CATCH
    
     ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItemsXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDataPackageItemsXML] TO [DMS_SP_User] AS [dbo]
GO
