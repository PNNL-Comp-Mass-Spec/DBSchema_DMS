/****** Object:  StoredProcedure [dbo].[make_data_package_storage_folder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_data_package_storage_folder]
/****************************************************
**
**  Desc: Requests creation of data storage folder for data package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   06/03/2009
**          07/10/2009 dac - Incorporated tested changes from T3 version of SP
**          07/14/2009 mem - Now logging to T_Log_Entries
**          08/19/2009 grk - Added failover to backup broker
**          11/05/2009 grk - Modified to use external message sender
**          03/17/2011 mem - Now calling add_data_folder_create_task in the DMS_Pipeline database
**          04/07/2011 mem - Fixed bug constructing @PathFolder (year was in the wrong place)
**          07/30/2012 mem - Now updating @message prior to calling post_log_entry
**          03/17/2016 mem - Remove call to CallSendMessage
**          07/05/2022 mem - Remove reference to obsolete column in view V_Data_Package_Folder_Creation_Parameters
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

    Declare @PathLocalRoot varchar(256)
    Declare @PathSharedRoot varchar(256)
    Declare @PathFolder varchar(512)
    Declare @SourceDB varchar(128) = DB_Name()

    SELECT @PathLocalRoot = [Local],
           @PathSharedRoot = [share],
           @PathFolder = team + '\' + [year] + '\' + folder
    FROM V_Data_Package_Folder_Creation_Parameters
    WHERE ID = @ID

    exec @myError = s_add_data_folder_create_task
                    @PathLocalRoot = @PathLocalRoot,
                    @PathSharedRoot = @PathSharedRoot,
                    @FolderPath = @PathFolder,
                    @SourceDB = @SourceDB,
                    @SourceTable = 'T_Data_Package',
                    @SourceID = @ID,
                    @SourceIDFieldName = 'ID',
                    @Command = 'add'


    ---------------------------------------------------
    -- Execute CallSendMessage, which will use xp_cmdshell to run C:\DMS_Programs\DBMessageSender\DBMessageSender.exe
    -- We stopped doing this in February 2016 because login DMSWebUser no longer has execute privileges on xp_cmdshell
    ---------------------------------------------------
    --
    /*
    EXEC @myError = CallSendMessage @ID, @mode, @message output

    If IsNull(@message, '') = ''
        Set @message = 'Called SendMessage for Data Package ID ' + Convert(varchar(12), @PackageID) + ': ' + @PathFolder

    exec post_log_entry 'Normal', @message, 'make_data_package_storage_folder', @callingUser=@CallingUser
    */


/*
** The following was the original method for doing this, using .NET function SendMessage
**

    SELECT
        @creationParams = '<params>' +
        '<package>' + convert(varchar(12), @ID) + '</package>' +
        '<local>' + Path_Local_Root + '</local>' +
        '<share>' + Path_Shared_Root + '</share>' +
        '<year>' + Path_Year + '</year>' +
        '<team>' + Path_Team + '</team>' +
        '<folder>' + Package_File_Folder + '</folder>' +
        '<cmd>' + @mode + '</cmd>' +
        '</params>'
    FROM
      T_Data_Package
      INNER JOIN T_Data_Package_Storage
        ON T_Data_Package.Path_Root = T_Data_Package_Storage.ID
    WHERE  (T_Data_Package.ID = @ID)

    ---------------------------------------------------
    declare @queue varchar(128)
    declare @server1 varchar(128)
    declare @server2 varchar(128)
    declare @port int
    declare @msg varchar(4000)

    SELECT   @queue =  '/queue/' + Value FROM T_Properties WHERE Property = 'MessageQueue'
    SELECT   @port =  Value FROM T_Properties WHERE Property = 'MessagePort'
    SELECT   @server1 =  Value FROM T_Properties WHERE Property = 'MessageBroker1'
    SELECT   @server2 =  Value FROM T_Properties WHERE Property = 'MessageBroker2'

    set @msg = ''
    exec @myError = SendMessage @creationParams, @queue, @server1, @port, @msg output
    if @myError <> 0
    begin
        set @msg = ''
        exec @myError = SendMessage @creationParams, @queue, @server2, @port, @msg output
    end
    if @myError <> 0
    begin
        set @message = @msg
    end

    set @message = 'Calling SendMessage: ' + @creationParams
    exec post_log_entry 'Normal', @message, 'make_data_package_storage_folder', @callingUser=@CallingUser
*/

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[make_data_package_storage_folder] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[make_data_package_storage_folder] TO [DMS_SP_User] AS [dbo]
GO
