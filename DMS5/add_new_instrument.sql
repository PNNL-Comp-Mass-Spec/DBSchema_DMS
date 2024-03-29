/****** Object:  StoredProcedure [dbo].[add_new_instrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_instrument]
/****************************************************
**
**  Desc:
**      Adds new instrument to database and new storage paths to storage table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/26/2001
**          07/24/2001 grk - Added Archive Path setup
**          03/12/2003 grk - Modified to call add_update_storage:
**          11/06/2003 grk - Modified to handle new ID for archive path independent of instrument id
**          01/30/2004 grk - Modified to return message (grk)
**          02/24/2004 grk - Fixed problem inserting first entry into empty tables
**          07/01/2004 grk - Modified the function to add records to T_Archive_Path table
**          12/14/2005 grk - Added check for existing instrument
**          04/07/2006 grk - Got rid of CDBurn stuff
**          06/28/2006 grk - Added support for Usage and Operations Role fields
**          12/11/2008 grk - Fixed problem with NULL @Usage
**          12/14/2008 grk - Fixed problem with select result being inadvertently returned
**          01/05/2009 grk - added @archiveNetworkSharePath (http://prismtrac.pnl.gov/trac/ticket/709)
**          01/05/2010 grk - added @allowedDatasetTypes (http://prismtrac.pnl.gov/trac/ticket/752)
**          02/12/2010 mem - Now calling UpdateInstrumentAllowedDatasetType for each dataset type in @allowedDatasetTypes
**          05/25/2010 dac - Updated archive paths for switch from nwfs to aurora
**          08/30/2010 mem - Replaced parameter @allowedDatasetTypes with @InstrumentGroup
**          05/12/2011 mem - Added @autoDefineStoragePath
**                         - Expanded @archivePath, @archiveServer, and @archiveNote to larger varchar() variables
**          05/13/2011 mem - Now calling validate_auto_storage_path_params
**          11/30/2011 mem - Added parameter @PercentEMSLOwned
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/05/2016 mem - Archive path is now aurora.emsl.pnl.gov
**          09/02/2016 mem - Archive path is now adms.emsl.pnl.gov
**          05/03/2019 mem - Add the source machine to T_Storage_Path_Hosts
**          10/27/2020 mem - Populate Auto_SP_URL_Domain and store https:// in T_Storage_Path_Hosts.URL_Prefix
**                           Pass @urlDomain to add_update_storage
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          04/19/2023 mem - Change severity level from 10 to 11 for RAISERROR() calls
**          07/18/2023 mem - Expand @description to varchar(255)
**          09/01/2023 mem - Expand @instrumentName to varchar(64), @description to varchar(1024), and @usage to varchar(128)
**          10/05/2023 mem - Archive path is now agate.emsl.pnl.gov
**
*****************************************************/
(
    @instrumentName varchar(64),        -- Name of new instrument
    @instrumentClass varchar(32),       -- Class of instrument
    @instrumentGroup varchar(64),       -- Item in T_Instrument_Group
    @captureMethod varchar(10),         -- Capture method of instrument
    @roomNumber varchar(50),            -- Where new instrument is located
    @description varchar(1024),         -- Description of instrument
    @usage varchar(128),                -- Optional description of instrument usage
    @operationsRole varchar(50),        -- Production, QC, Research, or Unused

    @percentEMSLOwned varchar(24),      -- % of instrument owned by EMSL; number between 0 and 100
    @autoDefineStoragePath varchar(32) = 'No',    -- Set to Yes to enable auto-defining the storage path based on the @spPath and @archivePath related parameters

    @sourceMachineName varchar(128),    -- Source Machine to capture data from
    @sourcePath varchar(255),           -- Transfer directory on source machine

    @spVolClient  varchar(128),         -- Storage server name, e.g. \\proto-8\
    @spVolServer  varchar(128),         -- Drive letter on storage server (local to server itself), e.g. F:\
    @spPath varchar(255),               -- Storage path on Storage Server; treated as @autoSPPathRoot if @autoDefineStoragePath is yes (e.g. Lumos01\)

    @archivePath varchar(128),          -- Storage path on EMSL archive, e.g.
    @archiveServer varchar(64),         -- Archive server name
    @archiveNote varchar(128),          -- Note describing archive path

    @message varchar(512) output
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @result int

    Declare @spSourcePathID int  = 2 -- valid reference to 'na' storage path for initial entry
    Declare @spStoragePathID int = 2 -- valid reference to 'na' storage path for initial entry

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @instrumentName = LTrim(RTrim(Coalesce(@instrumentName, '')))
    Set @description    = LTrim(RTrim(Coalesce(@description, '')))
    Set @usage          = LTrim(RTrim(Coalesce(@usage, '')))

    Set @autoDefineStoragePath = IsNull(@autoDefineStoragePath, 'No')

    Declare @Value int = Try_Parse(@PercentEMSLOwned as int)
    If @Value Is Null
        RAISERROR ('Percent EMSL Owned should be a number between 0 and 100', 11, 4)

    Declare @PercentEMSLOwnedVal int = Convert(int, @PercentEMSLOwned)

    If @PercentEMSLOwnedVal < 0 Or @PercentEMSLOwnedVal > 100
        RAISERROR ('Percent EMSL Owned should be a number between 0 and 100', 11, 4)

    ---------------------------------------------------
    -- Make sure instrument is not already in instrument table
    ---------------------------------------------------
    --
    Declare @hit int = -1

    SELECT @hit = Instrument_ID
    FROM T_Instrument_Name
    WHERE IN_name = @instrumentName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Failed to look for existing instrument'
        RAISERROR (@message, 11, 1)
        return 51007
    End

    If @myRowCount <> 0
    Begin
        Set @message = 'Instrument name already in use'
        RAISERROR (@message, 11, 1)
        return 51008
    End

    ---------------------------------------------------
    -- Derive shared path name
    ---------------------------------------------------
    --
    Declare @archiveNetworkSharePath varchar(128)
    Set @archiveNetworkSharePath = '\' + REPLACE(REPLACE(@archivePath, 'archive', 'agate.emsl.pnl.gov'), '/', '\')

    ---------------------------------------------------
    -- Resolve Yes/No parameters to 0 or 1
    ---------------------------------------------------
    --
    Declare @valAutoDefineStoragePath tinyint = 0

    If @autoDefineStoragePath = 'Yes' Or @autoDefineStoragePath = 'Y' OR @autoDefineStoragePath = '1'
        Set @valAutoDefineStoragePath = 1

    ---------------------------------------------------
    -- Define the @autoSP variables
    -- Auto-populate if @valAutoDefineStoragePath is non-zero
    ---------------------------------------------------
    --
    Declare @autoSPVolNameClient varchar(128)
    Declare @autoSPVolNameServer varchar(128)
    Declare @autoSPPathRoot varchar(128)
    Declare @autoSPUrlDomain varchar(64) = 'pnl.gov'
    Declare @autoSPArchiveServerName varchar(64)
    Declare @autoSPArchivePathRoot varchar(128)
    Declare @autoSPArchiveSharePathRoot varchar(128)

    If @valAutoDefineStoragePath <> 0
    Begin
        Set @autoSPVolNameClient = @spVolClient
        Set @autoSPVolNameServer = @spVolServer
        Set @autoSPPathRoot = @spPath
        Set @autoSPArchiveServerName = @archiveServer
        Set @autoSPArchivePathRoot = @archivePath
        Set @autoSPArchiveSharePathRoot = @archiveNetworkSharePath

        If IsNull(@autoSPVolNameClient, '') <> '' AND @autoSPVolNameClient NOT LIKE '%\'
            -- Auto-add a slash
            Set @autoSPVolNameClient = @autoSPVolNameClient + '\'

        If IsNull(@autoSPVolNameServer, '') <> '' AND @autoSPVolNameServer NOT LIKE '%\'
            -- Auto-add a slash
            Set @autoSPVolNameServer = @autoSPVolNameServer + '\'

        ---------------------------------------------------
        -- Validate the @autoSP parameteres
        ---------------------------------------------------

        exec @myError = validate_auto_storage_path_params  @valAutoDefineStoragePath, @autoSPVolNameClient, @autoSPVolNameServer,
                                                       @autoSPPathRoot, @autoSPArchiveServerName,
                                                       @autoSPArchivePathRoot, @autoSPArchiveSharePathRoot

    End

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'add_new_instrument'

    Begin transaction @transName

    ---------------------------------------------------
    -- Add new instrument ot instrument table
    ---------------------------------------------------

    -- get new instrument ID
    --
    Declare @instrumentID int

    SELECT @instrumentID = isnull(MAX(Instrument_ID), 0) + 1
    FROM T_Instrument_Name

    -- make entry into instrument table
    --
    INSERT INTO T_Instrument_Name(
        IN_name,
        Instrument_ID,
        IN_class,
        IN_Group,
        IN_source_path_ID,
        IN_storage_path_ID,
        IN_capture_method,
        IN_Room_Number,
        IN_Description,
        IN_usage,
        IN_operations_role,
        Percent_EMSL_Owned,
        Auto_Define_Storage_Path,
        Auto_SP_Vol_Name_Client,
        Auto_SP_Vol_Name_Server,
        Auto_SP_Path_Root,
        Auto_SP_URL_Domain,
        Auto_SP_Archive_Server_Name,
        Auto_SP_Archive_Path_Root,
        Auto_SP_Archive_Share_Path_Root
    ) VALUES (
        @instrumentName,
        @instrumentID,
        @instrumentClass,
        @InstrumentGroup,
        @spSourcePathID,
        @spStoragePathID,
        @captureMethod,
        @roomNumber,
        @description,
        IsNull(@Usage, ''),
        @OperationsRole,
        @PercentEMSLOwnedVal,
        @valAutoDefineStoragePath,
        @autoSPVolNameClient,
        @autoSPVolNameServer,
        @autoSPPathRoot,
        @autoSPUrlDomain,
        @autoSPArchiveServerName,
        @autoSPArchivePathRoot,
        @autoSPArchiveSharePathRoot
    )
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error

    If @myError <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Insert into x table was unsuccessful for add instrument', 11, 1)
        return 51131
    End

    ---------------------------------------------------
    -- Make sure the source machine exists in T_Storage_Path_Hosts
    ---------------------------------------------------
    --
    Declare @sourceMachineNameToFind varchar(128) =  replace(@sourceMachineName, '\', '')
    Declare @hostName Varchar(128)
    Declare @suffix Varchar(128)
    Declare @periodLoc Int
    Declare @logMessage Varchar(256)

    If Not Exists (Select * From T_Storage_Path_Hosts Where SP_machine_name = @sourceMachineNameToFind)
    Begin
        Set @periodLoc = CharIndex('.', @sourceMachineNameToFind)
        If @periodLoc > 1
        Begin
            Set @hostName = Substring(@sourceMachineNameToFind, 1, @periodLoc-1)
            Set @suffix = Substring(@sourceMachineNameToFind, @periodLoc, Len(@sourceMachineNameToFind))
        End
        Else
        Begin
            Set @hostName = @sourceMachineNameToFind
            Set @suffix = '.pnl.gov'
        End

        INSERT INTO T_Storage_Path_Hosts ( SP_machine_name, Host_Name, DNS_Suffix, URL_Prefix)
        VALUES (@sourceMachineNameToFind, @hostName, @suffix, 'https://')

        Set @logMessage = 'Added machine ' + @sourceMachineNameToFind + ' to T_Storage_Path_Hosts with host name ' + @hostName

        Exec post_log_entry 'Normal', @logMessage, 'add_new_instrument'
    End

    If @valAutoDefineStoragePath <> 0
    Begin
        Set @result = 0
    End
    Else
    Begin
        ---------------------------------------------------
        -- make new raw storage directory in storage table
        ---------------------------------------------------
        --
        exec @result = add_update_storage
                @spPath,
                @spVolClient,
                @spVolServer,
                'raw-storage',
                @instrumentName,
                '(na)',
                @autoSPUrlDomain,
                @spStoragePathID output,
                'add',
                @message output
    End

    --
    If @result <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Creating storage path was unsuccessful for add instrument', 11, 1)
        return 51132
    End

    ---------------------------------------------------
    -- Make new source (inbox) directory in storage table
    ---------------------------------------------------
    --
    exec @result = add_update_storage
            @sourcePath,
            '(na)',
            @sourceMachineName,     -- Note that add_update_storage will remove '\' characters from @sourceMachineName since @storFunction = 'inbox'
            'inbox',
            @instrumentName,
            '(na)',
            '',
            @spSourcePathID output,
            'add',
            @message output

    --
    If @result <> 0
    Begin
        rollback transaction @transName
        RAISERROR ('Creating source path was unsuccessful for add instrument', 11, 1)
        return 51133
    End

    If @valAutoDefineStoragePath = 0
    Begin -- <a>
        ---------------------------------------------------
        -- add new archive storage path for new instrument
        ---------------------------------------------------
        --
        -- get new archive ID
        --
        Declare @aID int
        --
        -- insert new archive path
        --
        INSERT INTO T_Archive_Path (
            AP_instrument_name_ID,
            AP_archive_path,
            AP_network_share_path,
            Note,
            AP_Server_Name,
            AP_Function
        ) VALUES (
            @instrumentID,
            @archivePath,
            @archiveNetworkSharePath,
            @archiveNote,
            @archiveServer,
            'Active'
        )
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        If @myError = 0
        Begin
            Set @aID = SCOPE_IDENTITY()
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error
        End

        If @myError <> 0
        Begin
            rollback transaction @transName
            RAISERROR ('Insert into archive path table was unsuccessful for add instrument', 11, 1)
            return 51134
        End
    End -- </a>

    ---------------------------------------------------
    -- Finalize the transaction
    ---------------------------------------------------
    --
    Commit Transaction @transName

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_instrument] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_new_instrument] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_new_instrument] TO [Limited_Table_Write] AS [dbo]
GO
