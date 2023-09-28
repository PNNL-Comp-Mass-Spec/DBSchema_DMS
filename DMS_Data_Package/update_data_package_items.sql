/****** Object:  StoredProcedure [dbo].[update_data_package_items] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_data_package_items]
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      This procedure is used by web page "DMS Data Package Detail Report" (data_package/show)
**
**  Auth:   grk
**  Date:   05/21/2009
**          06/10/2009 grk - changed size of item list to max
**          05/23/2010 grk - factored out grunt work into new sproc update_data_package_items_utility
**          03/07/2012 grk - changed data type of @itemList from varchar(max) to text
**          12/31/2013 mem - Added support for EUS Proposals
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/07/2016 mem - Switch to udf_parse_delimited_list
**          05/18/2016 mem - Add parameter @infoOnly
**          10/19/2016 mem - Update #TPI to use an integer field for data package ID
**          11/14/2016 mem - Add parameter @removeParents
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          03/10/2022 mem - Replace spaces and tabs in the item list with commas
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/27/2023 mem - Add support for @itemType = 'EUSProposal'
**
*****************************************************/
(
    @packageID int,                         -- Data package ID
    @itemType varchar(128),                 -- 'analysis_jobs', 'jobs', 'job', 'datasets', 'dataset', 'experiments', 'experiment', 'biomaterial', 'proposals', 'EUSProposal'
    @itemList varchar(max),                 -- Comma separated list of items
    @comment varchar(512),
    @mode varchar(12) = 'update',           -- 'add', 'update', 'comment', 'delete'
    @removeParents tinyint = 0,             -- When 1, remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
    @message varchar(512) = '' output,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0
)
AS
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
        Exec @authorized = verify_sp_authorized 'update_data_package_items', @raiseError = 1

        If @authorized = 0
        Begin
            RAISERROR ('Access denied', 11, 3)
        End

        Declare @entityName varchar(32)

        SELECT @entityName = CASE
                                 WHEN @itemType IN ('analysis_jobs', 'job', 'jobs') THEN 'Job'
                                 WHEN @itemType IN ('datasets', 'dataset')          THEN 'Dataset'
                                 WHEN @itemType IN ('experiments', 'experiment')    THEN 'Experiment'
                                 WHEN @itemType IN ('biomaterial')                  THEN 'Biomaterial'
                                 WHEN @itemType IN ('proposals', 'EUSProposal')     THEN 'EUSProposal'
                                 ELSE ''
                             END
        --
        If IsNull(@entityName, '') = ''
            RAISERROR('Item type "%s" is unrecognized', 11, 14, @itemType)

        Declare @logUsage tinyint = 0

        If @logUsage > 0
        Begin
            Declare @usageMessage varchar(255) = 'Updating ' + @entityName + 's for data package ' + Cast(@packageID as varchar(12))
            Exec post_log_entry 'Debug', @usageMessage, 'update_data_package_items'
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
        FROM dbo.parse_delimited_list(@itemList, ',')

        ---------------------------------------------------
        -- Apply the changes
        ---------------------------------------------------
        --
        exec @myError = update_data_package_items_utility
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
        EXEC format_error_message @message output, @myError output

        Declare @msgForLog varchar(512) = ERROR_MESSAGE()

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @msgForLog, 'update_data_package_items'

    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_data_package_items] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_data_package_items] TO [DMS_SP_User] AS [dbo]
GO
