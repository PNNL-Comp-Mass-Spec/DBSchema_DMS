/****** Object:  StoredProcedure [dbo].[RequestUnpurgeTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure RequestUnpurgeTask
/****************************************************
**
**	Desc: 
**	Looks for dataset that needs to have its raw spectra files
**  recovered from the archive.
**	If found, dataset archive status is set to 'Spectra Reqd In Progress'
**	and information needed for unpurge task is returned
**	in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**  if DatasetID is returned 0, no available dataset was found
**
**		Auth: grk
**		Date: 3/06/2003
**            2/11/2005 added @RawDataType to output
**    
**    
*****************************************************/

	@StorageServerName varchar(64),
	@jobNum varchar(32) output,
	@dataset varchar(128) output,
	@DatasetID int output,
	@Folder varchar(256) output, 
	@StorageVol varchar(256) output, 
	@storagePath varchar(256) output, 
	@StorageVolExternal varchar(256) output, -- use instead of @StorageVol when manager is not on same machine as dataset folder
	@ArchivePath varchar(256) output, 
	@RawDataType varchar(32) output,
	@ParamList varchar(1024) output, -- for future use
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	set @jobNum = ''
  set @dataset = ''
	set @DatasetID = 0
	set @Folder = ''
	set @storagePath = ''
	set @StorageVolExternal = ''
	set @RawDataType = ''
	set @ParamList = ''
	set @ArchivePath = '' 
	
	declare @jobID int
	set @jobID = 0

	declare @storageID int
	
	---------------------------------------------------
	-- temporary table to hold candidate unpurge requests
	---------------------------------------------------

	CREATE TABLE #PD (
		ID  int,
		MostRecent  datetime
	) 
 
	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- unpurge requests for given storage server
	---------------------------------------------------

	INSERT INTO #PD
	(ID)
	SELECT top 20 JobID
	FROM V_Unpurge_Requests
	WHERE 
		(StorageServerName = @StorageServerName) AND
		(ServerVol = @StorageVol)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end

	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'RequestUnpurgeTask'
	begin transaction @transName

  ---------------------------------------------------
	-- Select and lock a specific unpurge request by joining
	-- from the local pool to the actual analysis job table
	---------------------------------------------------
	
	SELECT top 1 @jobID = AJ_jobID
	FROM T_Analysis_Job with (HoldLock) 
	inner join #PD on ID = AJ_jobID 
	WHERE (AJ_StateID = 10)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'could not load temporary table'
		goto done
	end
	
	if @jobID = 0
	begin
		rollback transaction @transName
		goto done
	end

	---------------------------------------------------
	-- update analysis job state to show unpurge in progress
	---------------------------------------------------
	--
	UPDATE T_Analysis_Job
	SET AJ_StateID = 11
	WHERE (AJ_jobID = @jobID)
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
	-- get information for assigned task
	---------------------------------------------------
	--
	set @jobNum = cast(@jobID as varchar(12))
	--
	SELECT
		@Dataset = T_Dataset.Dataset_Num, 
		@DatasetID = T_Dataset.Dataset_ID, 
		@Folder = T_Dataset.DS_folder_name, 
		@StorageVol = t_storage_path.SP_vol_name_server, 
		@storagePath = t_storage_path.SP_path, 
		@StorageVolExternal = t_storage_path.SP_vol_name_client,
		@ArchivePath = T_Archive_Path.AP_Server_Name + ';' + T_Archive_Path.AP_archive_path, 
		@RawDataType = T_Instrument_Class.raw_data_type
	FROM
		T_Dataset INNER JOIN
		t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
		T_Analysis_Job ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID INNER JOIN
		T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID INNER JOIN
		T_Archive_Path ON T_Dataset_Archive.AS_storage_path_ID = T_Archive_Path.AP_path_ID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
                      T_Instrument_Class ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
WHERE
		(T_Analysis_Job.AJ_jobID = @jobID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Find dataset operation failed'
		goto done
	end
	
  ---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[RequestUnpurgeTask] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestUnpurgeTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestUnpurgeTask] TO [PNL\D3M580] AS [dbo]
GO
