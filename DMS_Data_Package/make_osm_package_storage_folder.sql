/****** Object:  StoredProcedure [dbo].[make_osm_package_storage_folder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_osm_package_storage_folder]
/****************************************************
**
**  Desc: Requests creation of data storage folder for OSM Package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   08/21/2013
**          05/27/2016 mem - Remove call to CallSendMessage
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @id int,
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- Lookup the parameters needed to call add_data_folder_create_task
    ---------------------------------------------------

    Declare @PackageID int
    Declare @PathLocalRoot varchar(256) = ''
    Declare @PathSharedRoot varchar(256) = ''
    Declare @PathFolder varchar(512) = ''
    Declare @SourceDB varchar(128) = DB_Name()

    SELECT
        @PackageID = ID,
        @PathSharedRoot  = Path_Shared_Root ,
        @PathFolder = Path_Folder
    FROM V_OSM_Package_Paths
    WHERE ID = @ID

    exec @myError = S_Add_Data_Folder_Create_Task
                    @pathLocalRoot = @PathLocalRoot,
                    @pathSharedRoot = @PathSharedRoot,
                    @folderPath = @PathFolder,
                    @sourceDB = @SourceDB,
                    @sourceTable = 'T_OSM_Package',
                    @sourceID = @PackageID,
                    @sourceIDFieldName = 'ID',
                    @command = 'add'


    ---------------------------------------------------
    -- Execute CallSendMessage, which will use xp_cmdshell to run C:\DMS_Programs\DBMessageSender\DBMessageSender.exe
    -- We stopped doing this in May 2016 because login DMSWebUser no longer has execute privileges on xp_cmdshell
    ---------------------------------------------------
    --
    /*
    EXEC @myError = CallSendMessage @ID, @mode, @message output

    If IsNull(@message, '') = ''
        Set @message = 'Called SendMessage for OSM Package ID ' + Convert(varchar(12), @PackageID) + ': ' + @PathFolder

    exec post_log_entry 'Normal', @message, 'MakeODMPackageStorageFolder', @callingUser=@CallingUser
    */

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[make_osm_package_storage_folder] TO [DDL_Viewer] AS [dbo]
GO
