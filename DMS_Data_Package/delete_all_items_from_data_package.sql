/****** Object:  StoredProcedure [dbo].[delete_all_items_from_data_package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_all_items_from_data_package]
/****************************************************
**
**  Desc:
**      Removes all existing items from a data package
**
**  Auth:   grk
**  Date:   06/10/2009 grk - initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/05/2016 mem - Add T_Data_Package_EUS_Proposals
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/17/2023 mem - Use renamed column data_pkg_id in data package tables
**
*****************************************************/
(
    @packageID INT,
    @mode varchar(12) = 'delete',
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    BEGIN TRY

        ---------------------------------------------------
        -- Verify that the user can execute this procedure from the given client host
        ---------------------------------------------------

        Declare @authorized tinyint = 0
        Exec @authorized = verify_sp_authorized 'delete_all_items_from_data_package', @raiseError = 1
        If @authorized = 0
        Begin
            RAISERROR ('Access denied', 11, 3)
        End

        Declare @transName varchar(32) = 'delete_all_items_from_data_package'

        Begin Transaction @transName

        DELETE FROM T_Data_Package_Analysis_Jobs
        WHERE Data_Pkg_ID  = @packageID

        DELETE FROM T_Data_Package_Datasets
        WHERE Data_Pkg_ID  = @packageID

        DELETE FROM T_Data_Package_Experiments
        WHERE Data_Pkg_ID  = @packageID

        DELETE FROM T_Data_Package_Biomaterial
        WHERE Data_Pkg_ID = @packageID

        DELETE FROM T_Data_Package_EUS_Proposals
        WHERE Data_Pkg_ID = @packageID

        Commit Transaction @transName

        ---------------------------------------------------
        -- update item counts
        ---------------------------------------------------

        Exec update_data_package_item_counts @packageID, @message output, @callingUser

        UPDATE T_Data_Package
        SET Last_Modified = GETDATE()
        WHERE ID = @packageID

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        Declare @msgForLog varchar(512) = ERROR_MESSAGE()

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @msgForLog, 'delete_all_items_from_data_package'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[delete_all_items_from_data_package] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_all_items_from_data_package] TO [DMS_SP_User] AS [dbo]
GO
