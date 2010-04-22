/****** Object:  StoredProcedure [dbo].[RequestPurgeTask_JDS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestPurgeTask_JDS
/****************************************************
**
**	Desc: 
**	Looks for dataset that is best candidate to be purged
**	If found, dataset archive status is set to 'Purge In Progress'
**	and information needed for purge task is returned
**	in the output arguments
**
**	Return values: 0: success, otherwise, error code
**	

**  if DatasetID is returned 0, no available dataset was found
**
**		Auth: grk
**		Date: 3/04/2003
**            2/11/2005 added @RawDataType to output
**    
*****************************************************/

	@StorageServerName varchar(64),
	@dataset varchar(128) output,
	@DatasetID int output,
	@Folder varchar(256) output, 
	@StorageVol varchar(256) output, 
	@storagePath varchar(256) output, 
	@StorageVolExternal varchar(256) output, -- use instead of @StorageVol when manager is not on same machine as dataset folder
	@RawDataType varchar(32) output,
	@ParamList varchar(1024) output, -- for future use
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = 'Test'
	set @DatasetID = 0
  set @dataset = ''
	set @DatasetID = ''
	set @Folder = ''
	set @storagePath = ''
	set @StorageVolExternal = ''
	set @RawDataType = ''
	set @ParamList = ''
	
	declare @storageID int

  ---------------------------------------------------
	-- temporary table to hold candidate purgable datasets
	---------------------------------------------------

	CREATE TABLE #PD (
		DatasetID  int,
		MostRecent  datetime
	) 

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- purgable datasets for given storage server
	---------------------------------------------------
	
	set @myRowCount = 0
	
	-- find candidates on the basis of "'no interest' datasets" 
	--
	if @myRowCount = 0
	begin
		INSERT INTO #PD
		(DatasetID, MostRecent)
		SELECT top 20    Dataset_ID, Created
		FROM         V_Purgable_Datasets_NoInterest
		WHERE     
			(StorageServerName = @StorageServerName) AND
			(ServerVol = @StorageVol)
		and DATEDIFF(Day, Created, GetDate()) > 5
		ORDER by Created
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'could not load temporary table'
			goto done
		end
	end
	
	-- find candidates on the basis of "old datasets that have never been analyzed" 
	-- (at least older than the given minimum)
	--
	if @myRowCount = 0
	begin
		INSERT INTO #PD
		(DatasetID, MostRecent)
		SELECT top 20    Dataset_ID, Created
		FROM         V_Purgable_Datasets_NoJob
		WHERE     
			(StorageServerName = @StorageServerName) AND
			(ServerVol = @StorageVol)
		and DATEDIFF(Day, Created, GetDate()) > 20
		ORDER by Created
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'could not load temporary table'
			goto done
		end
	end

	-- find candidates on the basis of "least recently analysed" 
	-- algorithm based on most recent analysis for each dataset
	--
	if @myRowCount = 0
	begin
	
		INSERT INTO #PD
		(DatasetID, MostRecent)
		SELECT top 20    Dataset_ID, MostRecentJob
		FROM         V_Purgable_Datasets
		WHERE
			(StorageServerName = @StorageServerName) AND
			(ServerVol = @StorageVol)
		ORDER by MostRecentJob
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'could not load temporary table'
			goto done
		end
	end
		
	-- FUTURE: establish minimum age? 
	
	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'RequestPurgeTask'
	begin transaction @transName

  ---------------------------------------------------
	-- Select and lock a specific purgable dataset by joining
	-- from the local pool to the actual archive table
	---------------------------------------------------

	SELECT  top 1 @datasetID = AS_Dataset_ID
	FROM T_Dataset_Archive with (HoldLock) 
	inner join #PD on DatasetID = AS_Dataset_ID 
	WHERE (AS_state_ID = 3)
	ORDER by MostRecent
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'could not load temporary table'
		goto done
	end
	
	if @datasetID = 0
	begin
		rollback transaction @transName
		goto done
	end
	
	---------------------------------------------------
	-- update archive state to show purge in progress
	---------------------------------------------------

	UPDATE T_Dataset_Archive
	SET AS_state_ID = 7 -- "purge in progress"
	WHERE (AS_Dataset_ID = @datasetID)
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
	-- get information for assigned dataset
	---------------------------------------------------

	SELECT 
		@dataset = T_Dataset.Dataset_Num, 
		@DatasetID = T_Dataset.Dataset_ID, 
		@Folder = T_Dataset.DS_folder_name, 
		@StorageVol  = t_storage_path.SP_vol_name_server, 
		@storagePath = t_storage_path.SP_path, 
		@StorageVolExternal = t_storage_path.SP_vol_name_client,
		@RawDataType = T_Instrument_Class.raw_data_type
	FROM
		T_Dataset INNER JOIN
		T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID INNER JOIN
		t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
		T_Instrument_Class ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
	WHERE
	T_Dataset.Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		rollback transaction @transName
		set @message = 'Find purgeable dataset operation failed'
		goto done
	end
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[RequestPurgeTask_JDS] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPurgeTask_JDS] TO [PNL\D3M580] AS [dbo]
GO
