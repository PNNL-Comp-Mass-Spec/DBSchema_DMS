/****** Object:  StoredProcedure [dbo].[RequestArchiveUpdateTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure RequestArchiveUpdateTask
/****************************************************
**
**	Desc: Looks for dataset that needs to be archived
**        If found, job is assigned
**        to caller and job information is returned
**        in the output arguments
**
**
**		Auth: grk
**		Date: 12/3/2002
**    
**    Mod: dac
**		Date: 12/6/2002
**		Corrected ArchivePath and ArchiveServerName outputs, changed Update State to 3 on success
**
*****************************************************/
	@StorageServerName varchar(64),
	@Dataset varchar(128) output,
	@DatasetID int output,
	@Folder varchar(256) output, 
	@StorageVol varchar(256) output, 
	@StoragePath varchar(256) output, 
	@ArchivePath varchar(256) output, 
	@ArchiveServer varchar(64) output, 
	@InstrumentClass varchar(32) output, -- supply input value to request a particular instrument class
	@InstrumentName varchar(24) output,
	@StorageVolExternal varchar(256) output, -- use instead of @StorageVol when manager is not on same machine as dataset folder
	@LastUpdate datetime output,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

   	---------------------------------------------------
	-- remember the requested instrument class
	---------------------------------------------------
	--
	declare @requestedInstClass varchar(32)
	--
	if @InstrumentClass <> ''
		set @requestedInstClass = @InstrumentClass
	else
		set @requestedInstClass = '%'
	
   	---------------------------------------------------
	-- clear the output arguments
	---------------------------------------------------
	set @Dataset = ''
	set @DatasetID = 0
	set @Folder  = ''
	set @StorageVol  = '' 
	set @StoragePath  = '' 
	set @ArchivePath   = ''
	set @ArchiveServer  = ''
	set @InstrumentClass  = ''
	set @InstrumentName  = ''
	set @StorageVolExternal = '' 
	
	
	---------------------------------------------------
	-- temporary table to hold candidate capture requests
	---------------------------------------------------

	CREATE TABLE #XPD (
		Dataset varchar(128) , 
		Dataset_ID  int, 
		Folder  varchar(256), 
		Storage_Vol  varchar(256), 
		Storage_Path  varchar(256),
		Archive_Path  varchar(256),
		Archive_Server_Name  varchar(64),
		Instrument_Class varchar(32), 
		Instrument_Name  varchar(24), 
		Storage_Vol_External  varchar(256),
		Last_Update datetime  
	) 

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- dataset archive update requests for given storage server
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	-- consider datasets for archive update that are associated with an instrument
	-- whose currently assigned storage is on the requesting processor
	
	INSERT INTO #XPD
	SELECT     TOP 5 
		Dataset, 
		Dataset_ID, 
		Folder, 
	  Storage_Vol, 
	  Storage_Path,
		Archive_Path,
		Archive_Server_Name,
		Instrument_Class, 
		Instrument_Name, 
		Storage_Vol_External,
		Last_Update 
	FROM  V_GetDatasetsForArchiveUpdateTask
	WHERE (Storage_Server_Name = @StorageServerName) AND 
	(Instrument_Class LIKE @requestedInstClass)
	ORDER BY Dataset_ID DESC
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end

  ---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'RequestArchiveTask'
	begin transaction @transName
	
   	---------------------------------------------------
	-- find a job matching the input request
	---------------------------------------------------
	--
/**/
	SELECT     TOP 1 
		@Dataset = #XPD.Dataset, 
		@DatasetID = #XPD.Dataset_ID, 
		@Folder = #XPD.Folder, 
		@StorageVol = #XPD.Storage_Vol, 
		@StoragePath = #XPD.Storage_Path,
		@ArchivePath = #XPD.Archive_Path,
		@ArchiveServer =#XPD. Archive_Server_Name,
		@InstrumentClass = #XPD.Instrument_Class, 
		@InstrumentName = #XPD.Instrument_Name, 
		@StorageVolExternal = #XPD.Storage_Vol_External,
		@LastUpdate = #XPD.Last_Update 
	FROM
		T_Dataset_Archive with (HoldLock) 
		inner join #XPD on #XPD.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID 
	WHERE (T_Dataset_Archive.AS_update_state_ID = 2)
	--
	SELECT @myError = @@error
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error trying to find archive record'
		goto done
	end

   	---------------------------------------------------
	-- bail if no task found
	---------------------------------------------------

	if @datasetID = 0
	begin
		rollback transaction @transName
		set @message = 'Could not find archive record'
		goto done
	end
	
		
   	---------------------------------------------------
	-- set state
	---------------------------------------------------
	--
	UPDATE    T_Dataset_Archive
	SET         
		AS_update_state_ID = 3 
	WHERE     (AS_Dataset_ID = @datasetID)
	-- future: AS_assignedProcessorName = @processorName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Update operation failed'
		goto done
	end

	commit transaction @transName

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError



GO
GRANT EXECUTE ON [dbo].[RequestArchiveUpdateTask] TO [DMS_SP_User]
GO
