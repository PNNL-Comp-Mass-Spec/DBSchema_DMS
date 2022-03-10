/****** Object:  StoredProcedure [dbo].[UpdateDataPackageItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateDataPackageItems]
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      This procedure is used by web page "DMS Data Package Detail Report" (data_package/show)
**
**  Auth:   grk
**  Date:   05/21/2009
**          06/10/2009 grk - changed size of item list to max
**          05/23/2010 grk - factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          03/07/2012 grk - changed data type of @itemList from varchar(max) to text
**          12/31/2013 mem - Added support for EUS Proposals
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/07/2016 mem - Switch to udfParseDelimitedList
**          05/18/2016 mem - Add parameter @infoOnly
**          10/19/2016 mem - Update #TPI to use an integer field for data package ID
**          11/14/2016 mem - Add parameter @removeParents
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          03/10/2022 mem - Replace spaces and tabs in the item list with commas
**
*****************************************************/
(
    @packageID int,                         -- Data package ID
    @itemType varchar(128),                 -- analysis_jobs, datasets, experiments, biomaterial, or proposals
    @itemList varchar(max),                 -- Comma separated list of items
    @comment varchar(512),
    @mode varchar(12) = 'update',           -- 'add', 'update', 'comment', 'delete'    
    @removeParents tinyint = 0,             -- When 1, remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
    @message varchar(512) = '' output,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    
    Declare @wasModified tinyint = 0

    BEGIN TRY 
    
        ---------------------------------------------------
        -- Verify that the user can execute this procedure from the given client host
        ---------------------------------------------------
            
        Declare @authorized tinyint = 0    
        Exec @authorized = VerifySPAuthorized 'UpdateDataPackageItems', @raiseError = 1

        If @authorized = 0
        Begin
            RAISERROR ('Access denied', 11, 3)
        End

        Declare @entityName varchar(32)

        SELECT @entityName = CASE
                                 WHEN @itemType IN ('analysis_jobs', 'job', 'jobs') THEN 'Job'
                                 WHEN @itemType IN ('datasets', 'dataset') THEN 'Dataset'
                                 WHEN @itemType IN ('experiments', 'experiment') THEN 'Experiment'
                                 WHEN @itemType = 'biomaterial' THEN 'Biomaterial'
                                 WHEN @itemType = 'proposals' THEN 'EUSProposal'
                                 ELSE ''
                             END
        --
        If IsNull(@entityName, '') = ''
            RAISERROR('Item type "%s" is unrecognized', 11, 14, @itemType)        
        
        Declare @logUsage tinyint = 0
        
        If @logUsage > 0
        Begin
            Declare @usageMessage varchar(255) = 'Updating ' + @entityName + 's for data package ' + Cast(@packageID as varchar(12))
            Exec PostLogEntry 'Debug', @usageMessage, 'UpdateDataPackageItems'
        End

        Set @itemList = LTrim(RTrim(IsNull(@itemList, '')))
        Set @itemList = Replace(Replace(@itemList, ' ', ','), Char(9), ',')

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in @paramListXML
        ---------------------------------------------------
        --
        CREATE TABLE #TPI(
            DataPackageID int not null,                -- Data package ID
            Type varchar(50) null,                    -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier varchar(256) null            -- Job ID, Dataset Name or ID, Experiment Name, Cell_Culture Name, or EUSProposal ID
        )
        INSERT INTO #TPI(DataPackageID, Type, Identifier) 
        SELECT @packageID, @entityName, Value
        FROM dbo.udfParseDelimitedList(@itemList, ',')
        
        ---------------------------------------------------
        -- Apply the changes
        ---------------------------------------------------
        --
        exec @myError = UpdateDataPackageItemsUtility
                                    @comment,
                                    @mode,
                                    @removeParents,
                                    @message output,
                                    @callingUser,
                                    @infoOnly = @infoOnly
        if @myError <> 0
            RAISERROR(@message, 11, 14)
        
    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        Declare @msgForLog varchar(512) = ERROR_MESSAGE()
        
        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
        
        Exec PostLogEntry 'Error', @msgForLog, 'UpdateDataPackageItems'
        
    END CATCH
    
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDataPackageItems] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDataPackageItems] TO [DMS_SP_User] AS [dbo]
GO
