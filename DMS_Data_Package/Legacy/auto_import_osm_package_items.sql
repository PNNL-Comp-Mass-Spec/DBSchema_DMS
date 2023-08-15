/****** Object:  StoredProcedure [dbo].[auto_import_osm_package_items] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[auto_import_osm_package_items]
/****************************************************
**
**  Desc:
**  Calls auto import function for all currently
**  active OSM packages
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/20/2013 grk - initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
AS
    Set XACT_ABORT, nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    DECLARE @message varchar(512) = ''

    ---------------------------------------------------
    --
    ---------------------------------------------------
    ---------------------------------------------------
    ---------------------------------------------------
    BEGIN TRY

        ---------------------------------------------------
        -- create and populate table to hold active package IDs
        ---------------------------------------------------

        CREATE TABLE #PKGS (
            ID INT
            -- FUTURE: details about auto-update
        )

        INSERT INTO #PKGS
                ( ID )
        SELECT ID FROM T_OSM_Package
        WHERE State = 'Active'

        ---------------------------------------------------
        -- cycle through active packages and do auto import
        -- for each one
        ---------------------------------------------------
        DECLARE
                @itemType varchar(128) = '',
                @itemList VARCHAR(max) = '',
                @comment varchar(512) = '',
                @mode varchar(12) = 'auto-import',
                @callingUser varchar(128) = USER

        DECLARE
            @currentId INT = 0,
            @prevId INT = 0,
            @done INT = 0

        WHILE @done = 0
        BEGIN --<d>
            SET @currentId = 0

            SELECT TOP 1 @currentId = ID
            FROM #PKGS
            WHERE ID > @prevId
            ORDER BY ID

            IF @currentId = 0
            BEGIN --<e>
                SET @done = 1
            END --<e>
            ELSE
            BEGIN  --<f>
                SET @prevId = @currentId

-- SELECT '->' + CONVERT(VARCHAR(12), @currentId)
            EXEC @myError = update_osm_package_items
                                @currentId,
                                @itemType,
                                @itemList,
                                @comment,
                                @mode,
                                @message output,
                                @callingUser
            END --<f>
        END --<d>

    ---------------------------------------------------
    ---------------------------------------------------

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        Declare @msgForLog varchar(512) = ERROR_MESSAGE()

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @msgForLog, 'auto_import_osm_package_items'

    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[auto_import_osm_package_items] TO [DDL_Viewer] AS [dbo]
GO
