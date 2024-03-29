/****** Object:  StoredProcedure [dbo].[delete_param_entries_for_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_param_entries_for_id]
/****************************************************
**
**  Desc: Deletes Sequest Param Entries from a given Param File ID
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   kja
**  Date:   07/22/2004
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramFileID int,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @msg varchar(256)

    declare @result int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_param_entries_for_id', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'DeleteParamEntries'
    begin transaction @transName
--  print 'start transaction' -- debug only

    ---------------------------------------------------
    -- delete any entries for the parameter file from the entries table
    ---------------------------------------------------

    DELETE FROM T_Param_Entries
    WHERE (Param_File_ID = @ParamFileID)
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from entries table was unsuccessful for param file',
            10, 1)
        return 51130
    end

    ---------------------------------------------------
    -- delete any entries for the parameter file from the global mod mapping table
    ---------------------------------------------------

    DELETE FROM T_Param_File_Mass_Mods
    WHERE (Param_File_ID = @ParamFileID)

    if @@error <> 0
    begin
        rollback transaction @transname
        RAISERROR ('Delete from global mapping table was unsuccessful for param file',
            10, 1)
        return 51131
    end

    commit transaction @transname

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[delete_param_entries_for_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_param_entries_for_id] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_param_entries_for_id] TO [Limited_Table_Write] AS [dbo]
GO
