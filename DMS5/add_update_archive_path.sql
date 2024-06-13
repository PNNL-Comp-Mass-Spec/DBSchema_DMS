/****** Object:  StoredProcedure [dbo].[add_update_archive_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_archive_path]
/****************************************************
**
**  Desc:
**      Adds new or updates existing archive paths in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   06/24/2004 jds - initial release
**          12/29/2008 grk - Added @networkSharePath (http://prismtrac.pnl.gov/trac/ticket/708)
**          05/11/2011 mem - Expanded @ArchivePath, @ArchiveServer, @networkSharePath, and @archiveNote to larger varchar() variables
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/16/2022 mem - Change RAISERROR severity to 11 (required so that the web page shows the error message)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          06/13/2024 mem - Rename parameter to @archivePathID
**
*****************************************************/
(
    @archivePathID varchar(32) output,            -- ID value (as a string)
    @archivePath varchar(128),
    @archiveServer varchar(64),
    @instrumentName varchar(24),
    @networkSharePath varchar(128),
    @archiveNote varchar(128),
    @archiveFunction varchar(32),
    @mode varchar(12) = 'add',                -- 'add' or 'update'
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @msg varchar(256)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_archive_path', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    set @myError = 0
    if LEN(@instrumentName) < 1
    begin
        set @myError = 51000
        RAISERROR ('Instrument Name must be specified', 11, 51000)
    end
    --
    if @myError <> 0
        return @myError

    set @myError = 0
    if LEN(@archivePath) < 1
    begin
        set @myError = 51001
        RAISERROR ('Archive Path must be specified', 11, 51001)
    end
    --
    if @myError <> 0
        return @myError

    set @myError = 0
    if LEN(@archiveFunction) < 1
    begin
        set @myError = 51002
        RAISERROR ('Archive Status must be specified', 10, 51002)
    end
    --
    if @myError <> 0
        return @myError

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @archiveIdCheck int = 0

    execute @archiveIdCheck = get_archive_path_id @archivePath

    -- cannot create an entry that already exists
    --
    if @archiveIdCheck <> 0 and @mode = 'add'
    begin
        set @msg = 'Cannot add: Archive Path "' + @archivePath + '" already in database '
        RAISERROR (@msg, 11, 51004)
        return 51004
    end

    ---------------------------------------------------
    -- Resolve instrument ID
    ---------------------------------------------------

    declare @instrumentID int
    execute @instrumentID = get_instrument_id @instrumentName
    if @instrumentID = 0
    begin
        set @msg = 'Could not find entry in database for instrument "' + @instrumentName + '"'
        RAISERROR (@msg, 11, 51014)
        return 51014
    end


    ---------------------------------------------------
    -- Resolve Archive function
    ---------------------------------------------------
    --
    -- Check to see if changing existing "Active" to non active
    -- leaving no active archive path for current instrument
    --
    declare @tempArchiveID int
    if @archiveFunction <> 'Active'
    begin
        SELECT @tempArchiveID = AP_Path_ID
        FROM T_Archive_Path
        WHERE AP_Path_ID = @archivePathID AND AP_Function = 'Active'
        if @tempArchiveID <> 0
        begin
            set @msg = 'Cannot change path to non Active for instrument "' + @instrumentName + '"'
            RAISERROR (@msg, 11, 51015)
            return 51015
        end
    end


    ---------------------------------------------------
    -- action for active instrument
    ---------------------------------------------------
    --
    -- check for active instrument to prevent multiple Active paths for an instrument
    --
    declare @instrumentIDTemp int
    execute @instrumentIDTemp = get_active_instrument_id @instrumentName
    if @instrumentIDTemp <> 0 and @archiveFunction = 'Active'
    begin
        UPDATE T_Archive_Path
        SET AP_Function = 'Old'
        WHERE AP_Path_ID in (Select AP_Path_ID FROM T_Instrument_Name
            INNER JOIN T_Archive_Path ON Instrument_ID = AP_Instrument_Name_ID
            and IN_name = @instrumentName and AP_Function = 'Active')
    end

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    --
    -- insert new archive path
    --
    if @Mode = 'add'
    begin

        INSERT INTO T_Archive_Path (
            AP_Archive_Path,
            AP_Server_Name,
            AP_Instrument_Name_ID,
            AP_network_share_path,
            Note,
            AP_Function
        ) VALUES (
            @archivePath,
            @archiveServer,
            @instrumentID,
            @networkSharePath,
            @archiveNote,
            @archiveFunction
        )

        -- return Archive ID of newly created archive
        --
        set @archivePathID = SCOPE_IDENTITY()

        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Insert operation failed: "' + @archivePath + '"'
            RAISERROR (@msg, 11, 51007)
            return 51007
        end
    end -- add mode



    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin

        set @myError = 0
        --
        UPDATE T_Archive_Path
        SET
            AP_Archive_Path = @archivePath,
            AP_Server_Name = @archiveServer,
            AP_Instrument_Name_ID = @instrumentID,
            AP_network_share_path = @networkSharePath,
            Note = @archiveNote,
            AP_Function = @archiveFunction
        WHERE (AP_Path_ID = @archivePathID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Update operation failed: "' + @archivePath + '"'
            RAISERROR (@msg, 11, 51008)
            return 51008
        end
    end -- update mode

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_archive_path] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_archive_path] TO [DMS_Archive_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_archive_path] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_archive_path] TO [Limited_Table_Write] AS [dbo]
GO
