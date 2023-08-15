/****** Object:  StoredProcedure [dbo].[get_auto_import_osm_package_items] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_auto_import_osm_package_items]
/****************************************************
**
**  Desc:
**   Populates supplied temp table with items
**   to be imported into given OSM package
**   based on other items in package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date:
**          03/20/2013 grk - initial release
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @packageID int,
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    --
    ---------------------------------------------------

    ---------------------------------------------------
    -- Get OSM package status and auto import settings
    ---------------------------------------------------

    DECLARE
        @packageState VARCHAR(32) = '',
        @datasetsFromPackageExperiments TINYINT = 0,
        @datasetsFromPackageRequests TINYINT = 0

    -- FUTURE: add auto import control fields to OSM package table
     SELECT
        @packageState = State,
        @datasetsFromPackageExperiments = CASE WHEN State = 'Active' THEN 1 ELSE 0 END,
        @datasetsFromPackageRequests = CASE WHEN State = 'Active' THEN 1 ELSE 0 END
     FROM   dbo.T_OSM_Package
     WHERE  dbo.T_OSM_Package.ID = @packageID

    ---------------------------------------------------
    -- datasets from experiments in package not already in package
    ---------------------------------------------------

    IF @datasetsFromPackageExperiments = 1
    BEGIN --<a>
        INSERT INTO #TPI(OSM_Package_ID, Item_Type, Item)
        SELECT  DISTINCT @packageID, 'Datasets', TDS.Dataset
        FROM    S_V_Dataset_List_Report_2 AS TDS
                INNER JOIN T_OSM_Package_Items AS TOPI ON TOPI.Item = TDS.Experiment
        WHERE   ( TOPI.Item_Type = 'Experiments' )
                AND TOPI.OSM_Package_ID = @packageID
                AND NOT TDS.Dataset IN (
                    SELECT Item
                    FROM   T_OSM_Package_Items
                    WHERE  OSM_Package_ID = @packageID
                    AND Item_Type = 'Datasets'
                )
                AND NOT TDS.Dataset IN (
                    SELECT Item FROM #TPI
                )
    END --<a>
    ---------------------------------------------------
    -- datasets from requests in package not already in package (dispositioned?)
    ---------------------------------------------------

    IF @datasetsFromPackageRequests = 1
    BEGIN --<b>
        INSERT INTO #TPI(OSM_Package_ID, Item_Type, Item)
        SELECT  DISTINCT @packageID, 'Datasets', Dataset
        FROM    S_V_Dataset_List_Report_2 AS TDS
                INNER JOIN T_OSM_Package_Items TOPI ON TOPI.Item_ID = TDS.Request
        WHERE   TOPI.Item_Type = 'Requested_Runs'
                AND TOPI.OSM_Package_ID = @packageID
                AND NOT TDS.Dataset IN (
                    SELECT Item
                    FROM   T_OSM_Package_Items
                    WHERE  OSM_Package_ID = @packageID
                    AND Item_Type = 'Datasets'
                )
                AND NOT TDS.Dataset IN (
                    SELECT Item FROM #TPI
                )
    END --<b>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_auto_import_osm_package_items] TO [DDL_Viewer] AS [dbo]
GO
