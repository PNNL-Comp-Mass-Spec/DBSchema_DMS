/****** Object:  StoredProcedure [dbo].[DeleteStoragePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteStoragePath]
/****************************************************
**
**  Desc:
**  Deletes given storage path from the storage path table
**  Storage path may not have any associated datasets.
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/14/2006
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @pathID int,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @result int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'DeleteStoragePath', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- verify no associated datasets
    ---------------------------------------------------
    declare @cn int
    --
    SELECT @cn = COUNT(*)
    FROM T_Dataset
    WHERE (DS_storage_path_ID = @pathID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        RAISERROR ('Error while trying to find associated datasets', 10, 1)
        return 51131
    end

    if @cn <> 0
    begin
        RAISERROR ('Cannot delete storage path that is being used by existing datasets', 10, 1)
        return 51132
    end


    ---------------------------------------------------
    -- delete storage path from table
    ---------------------------------------------------

    DELETE FROM t_storage_path
    WHERE     (SP_path_ID = @pathID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        RAISERROR ('Delete from storage path table was unsuccessful', 10, 1)
        return 51130
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteStoragePath] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteStoragePath] TO [Limited_Table_Write] AS [dbo]
GO
