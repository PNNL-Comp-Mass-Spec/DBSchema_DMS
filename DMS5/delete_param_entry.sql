/****** Object:  StoredProcedure [dbo].[DeleteParamEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteParamEntry]
/****************************************************
**
**  Desc: Deletes given Sequest Param Entry from the T_Param_Entries
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   kja
**  Date:   07/22/2004
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @paramFileID int,
    @entrySeqOrder int,
    @entryType varchar(32),
    @entrySpecifier varchar(32),
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @msg varchar(256)

    declare @ParamEntryID int
--  declare @state int

    declare @result int



    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'DeleteParamEntry', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- get ParamFileID
    ---------------------------------------------------

    set @ParamEntryID = 0
    --
    execute @ParamEntryID = GetParamEntryID @ParamFileID, @EntryType, @EntrySpecifier, @EntrySeqOrder
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Could not get ID for Param Entry "' + @ParamEntryID + '"'
        RAISERROR (@msg, 10, 1)
        return 51140
    end

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'DeleteParamEntry'
    begin transaction @transName
--  print 'start transaction' -- debug only

    ---------------------------------------------------
    -- delete any entries for the parameter file from the entries table
    ---------------------------------------------------

    DELETE FROM T_Param_Entries
    WHERE (Param_Entry_ID = @ParamEntryID)
    if @@error <> 0
    begin
        rollback transaction @transName
        RAISERROR ('Delete from entries table was unsuccessful for param file',
            10, 1)
        return 51130
    end

    commit transaction @transName

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamEntry] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteParamEntry] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteParamEntry] TO [Limited_Table_Write] AS [dbo]
GO
