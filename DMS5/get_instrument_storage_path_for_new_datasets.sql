/****** Object:  StoredProcedure [dbo].[get_instrument_storage_path_for_new_datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_instrument_storage_path_for_new_datasets]
/****************************************************
**
**  Desc:
**      Returns the ID for the most appropriate storage path for
**      new data uploaded for the given instrument.
**
**      If the Instrument has Auto_Define_Storage_Path enabled in
**      T_Instrument_Name, then will auto-define the storage path
**      based on the current year and quarter
**
**      If necessary, will call add_update_storage to auto-create an entry in T_Storage_Path
**
**  Returns: The storage path ID; 0 if an error
**
**  Auth:   mem
**  Date:   05/11/2011 mem - Initial Version
**          05/12/2011 mem - Added @RefDate and @autoSwitchActiveStorage
**          02/23/2016 mem - Add Set XACT_ABORT on
**          10/27/2020 mem - Pass Auto_SP_URL_Domain to add_update_storage
**          12/17/2020 mem - Rollback any open transactions before calling local_error_handler
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrumentID int,
    @refDate datetime = null,
    @autoSwitchActiveStorage tinyint = 1,
    @infoOnly tinyint = 0
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int    = 0
    Declare @myError int = 0

    Declare @StoragePathID int
    Declare @message varchar(255)

    Declare @autoDefineStoragePath tinyint

    Declare @autoSPVolNameClient varchar(128)
    Declare @autoSPVolNameServer varchar(128)
    Declare @autoSPPathRoot varchar(128)
    Declare @autoSPUrlDomain varchar(64)

    Declare @InstrumentName varchar(64)

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin try

        -----------------------------------------
        -- See if this instrument has Auto_Define_Storage_Path enabled
        -----------------------------------------
        --
        Set @autoDefineStoragePath = 0
        Set @StoragePathID = 0

        SELECT  @autoDefineStoragePath = Auto_Define_Storage_Path,
                @autoSPVolNameClient = Auto_SP_Vol_Name_Client,
                @autoSPVolNameServer = Auto_SP_Vol_Name_Server,
                @autoSPPathRoot = Auto_SP_Path_Root,
                @autoSPUrlDomain = Auto_SP_URL_Domain,
                @InstrumentName = IN_Name
        FROM T_Instrument_Name
        WHERE Instrument_ID = @InstrumentID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        If IsNull(@autoDefineStoragePath, 0) = 0
        Begin
            -- Using the storage path defined in T_Instrument_Name

            SELECT @StoragePathID = IN_storage_path_ID
            FROM T_Instrument_Name
            WHERE Instrument_ID = @instrumentID
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error
        End
        Else
        Begin -- <a>

            Declare @CurrentYear int
            Declare @CurrentQuarter tinyint
            Declare @StoragePathName varchar(255)

            Set @CurrentLocation = 'Auto-defining storage path'

            -- Validate the @autoSP variables
            If IsNull(@autoSPVolNameClient, '') = '' OR
               IsNull(@autoSPVolNameServer, '') = '' OR
               IsNull(@autoSPPathRoot, '') = ''
            Begin
                Set @message = 'One or more Auto_SP fields are empty or null for instrument ' + @InstrumentName + '; unable to auto-define the storage path'

                If @infoOnly = 0
                    exec post_log_entry 'Error', @message, 'get_instrument_storage_path_for_new_datasets'
                Else
                    print @message
            End
            Else
            Begin -- <b>
                -----------------------------------------
                -- Define the StoragePath
                -- It will look like VOrbiETD01\2011_2\
                -----------------------------------------

                Set @RefDate = IsNull(@RefDate, GetDate())

                SELECT @CurrentYear = DatePart(year, @RefDate),
                       @CurrentQuarter = DatePart(quarter, @RefDate)

                Declare @Suffix varchar(128)
                Set @Suffix = Convert(varchar(8), @CurrentYear) + '_' + Convert(varchar(4), @CurrentQuarter) + '\'

                Set @StoragePathName = @autoSPPathRoot

                If Right(@StoragePathName, 1) <> '\'
                        Set @StoragePathName = @StoragePathName + '\'

                Set @StoragePathName = @StoragePathName + @Suffix

                -----------------------------------------
                -- Look for existing entry in T_Storage_Path
                -----------------------------------------

                SELECT @StoragePathID = SP_path_ID
                FROM T_Storage_Path
                WHERE SP_Path = @StoragePathName AND
                      SP_Vol_Name_Client = @autoSPVolNameClient AND
                      SP_Vol_Name_Server = @autoSPVolNameServer AND
                      (SP_Function = 'raw-storage' OR
                       SP_Function = 'old-storage' AND @autoSwitchActiveStorage = 0)
                --
                SELECT @myRowCount = @@rowcount, @myError = @@error

                If @myRowCount = 0
                Begin
                    -- Path not found; add it if @infoOnly <> 0
                    If @infoOnly <> 0
                        Print 'Auto-defined storage path "' + @StoragePathName + '" not found T_Storage_Path; need to add it'
                    Else
                    Begin
                        Set @CurrentLocation = 'Call add_update_storage to add ' + @StoragePathName

                        Declare @StorageFunction varchar(24)

                        If @autoSwitchActiveStorage = 0
                            Set @StorageFunction = 'old-storage'
                        Else
                            Set @StorageFunction = 'raw-storage'

                        Exec add_update_storage @StoragePathName,
                                              @autoSPVolNameClient,
                                              @autoSPVolNameServer,
                                              @storFunction=@StorageFunction,
                                              @instrumentName=@InstrumentName,
                                              @description='',
                                              @urlDomain=@autoSPUrlDomain,
                                              @ID=@StoragePathID output,
                                              @mode='add',
                                              @message=@message output

                    End

                End
                Else
                Begin
                    If @infoOnly <> 0
                        Print 'Auto-defined storage path "' + @StoragePathName + '" matched in T_Storage_Path; ID=' + Convert(varchar(12), @StoragePathID)
                End

            End -- </b>
        End -- </a>

    End Try
    Begin Catch
        -- Error caught; log the error and Set @StoragePathID to 0

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'get_instrument_storage_path_for_new_datasets')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                            @ErrorNum = @myError output, @message = @message output

    End catch

    -----------------------------------------
    -- Return the storage path ID
    -----------------------------------------
    --
    Set @StoragePathID = IsNull(@StoragePathID, 0)

    return @StoragePathID

GO
GRANT VIEW DEFINITION ON [dbo].[get_instrument_storage_path_for_new_datasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_instrument_storage_path_for_new_datasets] TO [svc-dms] AS [dbo]
GO
