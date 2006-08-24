/****** Object:  StoredProcedure [dbo].[RequestPreparationTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure RequestPreparationTask
/****************************************************
**
**	Desc: 
**	Looks for dataset that needs to Prepared
**	If found, dataset is set 'Prep. In Progress' state
**	and information needed for preparation task is returned
**	in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**  if DatasetID is returned 0, no available dataset was found
**
**		Auth: grk
**		Date: 11/14/2002
**    
**		Rev: dac    
**    Date: 07/16/2003
**      Added @StorageVolExternal to list of output arguments being cleared prior to transaction start
**		5/10/2005 grk changed select logic to do oldest datasets first
**		6/2/2005 grk - added handling for prep server
**		7/1/2005 grk - add sorting by dataset ID for candidate pool select
**		2/20/2006 grk - removed sorting by dataset ID for candidate pool select (for QC preference in view)
**    
*****************************************************/
	@StorageServerName varchar(64),
	@PrepServerName varchar(64),
    @Dataset varchar(128) output,
	@DatasetID int output,
	@Folder varchar(256) output, 
	@StorageVol varchar(256) output, 
	@StoragePath varchar(256) output, 
	@InstrumentClass varchar(32) output, -- supply a value to restrict search
	@StorageVolExternal varchar(256) output, -- use instead of @StorageVol when manager is not on same machine as dataset folder
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

   	---------------------------------------------------
	-- remember the requested instrument class
	---------------------------------------------------
	--
	declare @requestedInstClass varchar(32)
	if @InstrumentClass <> ''
		set @requestedInstClass = @InstrumentClass
	else
		set @requestedInstClass = '%'
	
   	---------------------------------------------------
	-- clear the output arguments
	---------------------------------------------------
	--
	set @message = ''
	set @DatasetID = 0
	set @Dataset = ''
	set @DatasetID = ''
	set @Folder = ''
	set @StorageVol  = ''
	set @StoragePath = ''
	set @StorageVolExternal = ''
		
	---------------------------------------------------
	-- temporary table to hold candidate capture requests
	---------------------------------------------------

	CREATE TABLE #XPD (
		Dataset varchar(128), 
		Folder varchar(128), 
		StorageServerName varchar(64), 
		StorageVolClient varchar(128), 
		StorageVolServer varchar(128), 
		storagePath varchar(255), 
		Dataset_ID int, 
		StorageID int, 
		InstrumentClass varchar(32), 
		InstrumentName varchar(24)
	) 

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- dataset capture requests for given storage server
	-- and prep server (if specified)
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	-- consider datasets for capture that are associated with an instrument
	-- whose currently assigned storage is on the requesting processor
	
	INSERT INTO #XPD
	SELECT TOP 5
		Dataset, 
		Folder, 
		StorageServerName, 
		StorageVolClient, 
		StorageVolServer, 
		storagePath, 
		Dataset_ID, 
		StorageID, 
		InstrumentClass, 
		InstrumentName
	FROM V_GetDatasetsForPreparationTask
	WHERE 
		(StorageServerName = @StorageServerName) AND 
		(InstrumentClass LIKE @requestedInstClass) AND
		((PrepServerName = @PrepServerName) OR (@PrepServerName = ''))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end
	--
	if @myRowCount = 0
	begin
		set @message = 'No candidate datasets available'
		goto done
	end

   	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'RequestCaptureTask'
	begin transaction @transName
	
   	---------------------------------------------------
	-- find a dataset matching the input request
	---------------------------------------------------
	--
	-- get dataset for Preparation that is in the 'Received' state 
	-- and that is associated with a storage path that is on the requesting processor
	--
	SELECT top 1
		@Dataset = #XPD.Dataset, 
		@DatasetID = #XPD.Dataset_ID,
		@Folder = #XPD.Folder, 
		@StorageVol = #XPD.StorageVolServer, 
		@storagePath = #XPD.storagePath,
		@InstrumentClass = #XPD.InstrumentClass, 
		@StorageVolExternal = #XPD.StorageVolClient
	FROM
		T_Dataset with (HoldLock) INNER JOIN 
		#XPD on #XPD.Dataset_ID = T_Dataset.Dataset_ID 
	WHERE (T_Dataset.DS_state_ID = 6)
	ORDER BY T_Dataset.Dataset_ID ASC
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Find dataset operation failed'
		goto done
	end

   	---------------------------------------------------
	-- Check to see if dataset was found
	---------------------------------------------------
	
	if @DatasetID = 0
	begin
		rollback transaction @transName
		set @message = 'No datasets available'
		goto done
	end
	
   	---------------------------------------------------
	-- set state and storage path
	---------------------------------------------------
	--

	UPDATE    T_Dataset
	SET 
		DS_state_ID = 7
	WHERE     (Dataset_ID = @DatasetID)
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
GRANT EXECUTE ON [dbo].[RequestPreparationTask] TO [DMS_SP_User]
GO
