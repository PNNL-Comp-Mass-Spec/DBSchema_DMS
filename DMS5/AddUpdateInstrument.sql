/****** Object:  StoredProcedure [dbo].[AddUpdateInstrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateInstrument]
/****************************************************
**
**  Desc:
**      Edits existing Instrument
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/07/2005 grk - Initial release
**          10/15/2008 grk - Allowed for null Usage
**          08/27/2010 mem - Add parameter @instrumentGroup
**                         - try-catch for error handling
**          05/12/2011 mem - Add @autoDefineStoragePath and related @autoSP parameters
**          05/13/2011 mem - Now calling ValidateAutoStoragePathParams
**          11/30/2011 mem - Add parameter @percentEMSLOwned
**          04/01/2013 mem - Expanded @description to varchar(255)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          04/10/2018 mem - Add parameter @scanSourceDir
**          12/06/2018 mem - Change variable names to camelCase
**                         - Use Try_Cast instead of Try_Convert
**          05/28/2019 mem - Add parameter @trackUsageWhenInactive
**
*****************************************************/
(
    @instrumentID int Output,
    @instrumentName varchar(24),
    @instrumentClass varchar(32),
    @instrumentGroup varchar(64),
    @captureMethod varchar(10),
    @status varchar(8),
    @roomNumber varchar(50),
    @description varchar(255),
    @usage varchar(50),
    @operationsRole varchar(50),
    @trackUsageWhenInactive varchar(32) = 'No',
    @scanSourceDir varchar(32) = 'Yes',         -- Set to No to skip this instrument when the DMS_InstDirScanner looks for files and directories on the instrument's source share
    @percentEMSLOwned varchar(24),              -- % of instrument owned by EMSL; number between 0 and 100
    @autoDefineStoragePath varchar(32) = 'No',  -- Set to Yes to enable auto-defining the storage path based on the @spPath and @archivePath related parameters
    @autoSPVolNameClient varchar(128),          -- Example: \\proto-8\
    @autoSPVolNameServer varchar(128),          -- Example: F:\
    @autoSPPathRoot varchar(128),               -- Example: Lumos01\
    @autoSPUrlDomain varchar(64),               -- Example: pnl.gov
    @autoSPArchiveServerName varchar(64),
    @autoSPArchivePathRoot varchar(128),
    @autoSPArchiveSharePathRoot varchar(128),
    @mode varchar(12) = 'update',               -- Note that 'add' is not allowed in this procedure; instead use https://dms2.pnl.gov/new_instrument/create (which in turn calls AddNewInstrument)
    @message varchar(512) = '' output
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateInstrument', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If @usage is null
        Set @usage = ''

    Declare @percentEMSLOwnedVal int = Try_Cast(@percentEMSLOwned As int);

    If @percentEMSLOwnedVal Is Null Or @percentEMSLOwnedVal < 0 Or @percentEMSLOwnedVal > 100
    Begin;
        THROW 51001, 'Percent EMSL Owned should be a number between 0 and 100', 1
    End;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- cannot update a non-existent entry
        --
        Declare @tmp int
        Set @tmp = 0
        --
        SELECT @tmp = Instrument_ID
        FROM  T_Instrument_Name
        WHERE (IN_name = @instrumentName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount;
        --
        If @myError <> 0 OR @tmp = 0
        Begin;
            THROW 51002, 'No entry could be found in database for update', 1
        End;
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Resolve Yes/No parameters to 0 or 1
    ---------------------------------------------------
    --
    Declare @valTrackUsageWhenInactive tinyint = dbo.BooleanTextToTinyint(@trackUsageWhenInactive)
    Declare @valScanSourceDir tinyint = dbo.BooleanTextToTinyint(@scanSourceDir)
    Declare @valAutoDefineStoragePath tinyint = dbo.BooleanTextToTinyint(@autoDefineStoragePath)

    ---------------------------------------------------
    -- Validate the @autoSP parameteres
    ---------------------------------------------------

    exec @myError = ValidateAutoStoragePathParams  @valAutoDefineStoragePath, @autoSPVolNameClient, @autoSPVolNameServer,
                                                   @autoSPPathRoot, @autoSPArchiveServerName,
                                                   @autoSPArchivePathRoot, @autoSPArchiveSharePathRoot

    If @myError <> 0
        return @myError;

    ---------------------------------------------------
    -- Note: the add mode is not enabled in this stored procedure
    ---------------------------------------------------
    If @mode = 'add'
    Begin;
        Set @logErrors = 0;
        THROW 51003, 'The "add" instrument mode is disabled for this page; instead, use https://dms2.pnl.gov/new_instrument/create', 1
    End;

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin

        UPDATE T_Instrument_Name
        SET IN_name = @instrumentName,
            IN_class = @instrumentClass,
            IN_Group = @instrumentGroup,
            IN_capture_method = @captureMethod,
            IN_status = @status,
            IN_Room_Number = @roomNumber,
            IN_Description = @description,
            IN_usage = @usage,
            IN_operations_role = @operationsRole,
            IN_Tracking = @valTrackUsageWhenInactive,
            Scan_SourceDir = @valScanSourceDir,
            Percent_EMSL_Owned = @percentEMSLOwnedVal,
            Auto_Define_Storage_Path = @valAutoDefineStoragePath,
            Auto_SP_Vol_Name_Client = @autoSPVolNameClient,
            Auto_SP_Vol_Name_Server = @autoSPVolNameServer,
            Auto_SP_Path_Root = @autoSPPathRoot,
            Auto_SP_URL_Domain = @autoSPUrlDomain,
            Auto_SP_Archive_Server_Name = @autoSPArchiveServerName,
            Auto_SP_Archive_Path_Root = @autoSPArchivePathRoot,
            Auto_SP_Archive_Share_Path_Root = @autoSPArchiveSharePathRoot
        WHERE (Instrument_ID = @instrumentID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount;
        --
        If @myError <> 0
        Begin;
            THROW 51004, 'Update operation failed', 1
        End;

    End -- update mode

    END Try
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError Output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Instrument ' + @instrumentName
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateInstrument'
        End

    END Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrument] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS_Instrument_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateInstrument] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateInstrument] TO [Limited_Table_Write] AS [dbo]
GO
