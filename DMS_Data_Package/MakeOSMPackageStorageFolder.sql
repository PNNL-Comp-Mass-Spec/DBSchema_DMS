/****** Object:  StoredProcedure [dbo].[MakeOSMPackageStorageFolder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MakeOSMPackageStorageFolder]
/****************************************************
**
**  Desc: Requests creation of data storage folder for OSM Package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**  Date:	08/21/2013
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
	Declare @PathLocalRoot varchar(256) = ''
	Declare @PathSharedRoot varchar(256) = ''
	Declare @PathFolder varchar(512) = ''
	Declare @SourceDB varchar(128) = DB_Name()

	SELECT 
		@PackageID = ID, 
		@PathSharedRoot  = Path_Shared_Root ,
		@PathFolder = Path_Folder 
	FROM    V_OSM_Package_Paths
	WHERE ID = @ID

	exec @myError = S_AddDataFolderCreateTask 
					@PathLocalRoot = @PathLocalRoot, 
					@PathSharedRoot = @PathSharedRoot, 
					@FolderPath = @PathFolder, 
					@SourceDB = @SourceDB, 
					@SourceTable = 'T_OSM_Package', 
					@SourceID = @PackageID, 
					@SourceIDFieldName = 'ID', 
					@Command = 'add'


	---------------------------------------------------
	-- Execute CallSendMessage, which will use xp_cmdshell to run C:\DMS_Programs\DBMessageSender\DBMessageSender.exe
	---------------------------------------------------
	--
	EXEC @myError = CallSendMessage @ID, @mode, @message output

	If IsNull(@message, '') = ''
		Set @message = 'Called SendMessage for OSM Package ID ' + Convert(varchar(12), @PackageID) + ': ' + @PathFolder
		
	exec PostLogEntry 'Normal', @message, 'MakeODMPackageStorageFolder', @callingUser=@CallingUser


	---------------------------------------------------
	-- Done
	---------------------------------------------------

	return @myError



GO
