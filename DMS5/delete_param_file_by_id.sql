/****** Object:  StoredProcedure [dbo].[DeleteParamFileByID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteParamFileByID]
/****************************************************
**
**  Desc: Deletes a parameter file by ID
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   08/11/2004 kja
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @ParamFileID int,
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
    Exec @authorized = VerifySPAuthorized 'DeleteParamFileByID', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'DeleteParamFile'
    begin transaction @transName
--  print 'start transaction' -- debug only

    ---------------------------------------------------
    -- delete any entries for the parameter file from the entries table
    ---------------------------------------------------

    execute @result = DeleteParamEntriesForID @ParamFileID, @msg output

--  DELETE FROM T_Param_Entries
--  WHERE (Param_File_ID = @ParamFileID)
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from entries table was unsuccessful for param file',
            10, 1)
        return 51130
    end

    ---------------------------------------------------
    -- delete entry from dataset table
    ---------------------------------------------------

    DELETE FROM T_Param_Files
    WHERE Param_File_ID = @ParamFileID

    if @@rowcount <> 1
    begin
        rollback transaction @transName
        RAISERROR ('Delete from param files table was unsuccessful for param file',
            10, 1)
        return 51136
    end


    commit transaction @transName

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamFileByID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteParamFileByID] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamFileByID] TO [Limited_Table_Write] AS [dbo]
GO
