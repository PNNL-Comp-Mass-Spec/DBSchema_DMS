/****** Object:  StoredProcedure [dbo].[MakeDataPackageStorageFolder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeDataPackageStorageFolder
/****************************************************
**
**  Desc: Requests creation of data storage folder for data package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**  Date:	06/03/2009
**			07/10/2009 dac - Incorporated tested changes from T3 version of SP
**			07/14/2009 mem - Now logging to T_Log_Entries
**			08/19/2009 grk - Added failover to backup broker
**			11/05/2009 grk - Modified to use external message sender
**			03/17/2011 mem - Now calling AddDataFolderCreateTask in the DMS_Pipeline database
**			04/07/2011 mem - Fixed bug constructing @PathFolder (year was in the wrong place)
**			07/30/2012 mem - Now updating @message prior to calling PostLogEntry
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@ID int,
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	-- Lookup the parameters needed to call AddDataFolderCreateTask
	---------------------------------------------------

	Declare @PackageID int
	Declare @PathLocalRoot varchar(256)
	Declare @PathSharedRoot varchar(256)
	Declare @PathFolder varchar(512)
	Declare @SourceDB varchar(128) = DB_Name()
	
	SELECT @PackageID = ID,
	       @PathLocalRoot = [Local],
	       @PathSharedRoot = [share],
	       @PathFolder = team + '\' + [year] + '\' + folder
	FROM V_Data_Package_Folder_Creation_Parameters
	WHERE package = @ID

	exec @myError = S_AddDataFolderCreateTask 
					@PathLocalRoot = @PathLocalRoot, 
					@PathSharedRoot = @PathSharedRoot, 
					@FolderPath = @PathFolder, 
					@SourceDB = @SourceDB, 
					@SourceTable = 'T_Data_Package', 
					@SourceID = @PackageID, 
					@SourceIDFieldName = 'ID', 
					@Command = 'add'


	---------------------------------------------------
	-- Execute CallSendMessage, which will use xp_cmdshell to run C:\DMS_Programs\DBMessageSender\DBMessageSender.exe
	---------------------------------------------------
	--
	EXEC @myError = CallSendMessage @ID, @mode, @message output

	If IsNull(@message, '') = ''
		Set @message = 'Called SendMessage for Data Package ID ' + Convert(varchar(12), @PackageID) + ': ' + @PathFolder
		
	exec PostLogEntry 'Normal', @message, 'MakeDataPackageStorageFolder', @callingUser=@CallingUser


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
	exec PostLogEntry 'Normal', @message, 'MakeDataPackageStorageFolder', @callingUser=@CallingUser
*/	

	---------------------------------------------------
	-- Done
	---------------------------------------------------

	return @myError

GO
GRANT EXECUTE ON [dbo].[MakeDataPackageStorageFolder] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeDataPackageStorageFolder] TO [PNL\D3M578] AS [dbo]
GO
