/****** Object:  StoredProcedure [dbo].[update_osm_package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_osm_package]
/****************************************************
**
**  Desc:
**  Update or delete given OSM Package
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   07/08/2013 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @osmPackageID INT,
    @mode VARCHAR(32),
    @message VARCHAR(512) output,
    @callingUser VARCHAR(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    DECLARE @myError int = 0
    DECLARE @myRowCount int = 0
    SET @message = ''

    DECLARE @DebugMode tinyint = 0

    BEGIN TRY

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_osm_package', @raiseError = 1
    If @authorized = 0
    Begin
        RAISERROR ('Access denied', 11, 3)
    End

    ---------------------------------------------------
    -- verify OSM package exists
    ---------------------------------------------------

    IF @mode = 'delete'
    BEGIN --<delete>

        ---------------------------------------------------
        -- start transaction
        ---------------------------------------------------
        --
        declare @transName varchar(32)
        set @transName = 'update_osm_package'
        begin transaction @transName

        ---------------------------------------------------
        -- 'delete' (mark as inactive) associated file attachments
        ---------------------------------------------------

        UPDATE S_File_Attachment
        SET [Active] = 0
        WHERE Entity_Type = 'osm_package'
        AND Entity_ID = @osmPackageID

        ---------------------------------------------------
        -- remove OSM package from table
        ---------------------------------------------------

        DELETE  FROM dbo.T_OSM_Package
        WHERE   ID = @osmPackageID

        commit transaction @transName

    END --<delete>

    IF @mode = 'test'
    BEGIN
        RAISERROR ('Test: %d', 11, 20, @osmPackageID)
    END

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        Declare @msgForLog varchar(512) = ERROR_MESSAGE()

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @msgForLog, 'update_osm_package'

    END CATCH
    RETURN @myError
/*
GRANT EXECUTE ON update_osm_package TO DMS2_SP_User
GRANT EXECUTE ON update_osm_package TO DMS_SP_User
*/

GO
GRANT VIEW DEFINITION ON [dbo].[update_osm_package] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_osm_package] TO [DMS_SP_User] AS [dbo]
GO
