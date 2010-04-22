/****** Object:  StoredProcedure [dbo].[RequestPreparationTask_Rmed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure RequestPreparationTask_Rmed
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
**		Date: 11/18/2002
**    
**		Rev: dac    
**    Date: 07/16/2003
**    Added @StorageVolExternal to list of output arguments being cleared prior to transaction start
**
**    NOTE: This procedure is only to be used for 
**	  remedial operation of the preparation manager
**    as it returns an FTICR dataset that is in the "complete"
**	  state that has null values in both its compression state and
**    compression date fields.
*****************************************************/
	@StorageServerName varchar(64),
  @Dataset varchar(128) output,
	@DatasetID int output,
	@Folder varchar(256) output, 
	@StorageVol varchar(256) output, 
	@StoragePath varchar(256) output, 
	@InstrumentClass varchar(32) output,  -- supply a value to restrict search
	@StorageVolExternal varchar(256) output,  -- use instead of @StorageVol when manager is not on same machine as dataset folder
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
	-- temporary table to hold candidate preparation requests
	---------------------------------------------------

	CREATE TABLE #XPD (
		 Dataset varchar(128),
		 Dataset_ID int,
		 Folder varchar(256), 
		 StorageVolServer varchar(256), 
		 storagePath varchar(256),
		 InstrumentClass varchar(64),
		 StorageVolClient varchar(256)
	) 

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- dataset capture requests for given storage server
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	INSERT INTO #XPD
	SELECT TOP 5 
		Dataset, 
		Dataset_ID,
		Folder, 
		StorageVolServer, 
		storagePath,
		InstrumentClass,
		StorageVolClient
	FROM V_GetDatasetsForPreparationTask_Rmed
	WHERE
		(StorageServerName = @StorageServerName)AND 
		(InstrumentClass LIKE @requestedInstClass)
	ORDER BY Created
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
	set @transName = 'RequestCaptureTask'
	begin transaction @transName

  ---------------------------------------------------
	-- Select and lock a specific dataset by joining
	-- from the local pool to the actual dataset table
	-- Note:  This takes a lock on the selected row
	-- so that that dataset can be exclusively assigned,
	-- but only locks T_Dataset table, not the others
	-- involved in resolving the request
	---------------------------------------------------

  ---------------------------------------------------
	-- find a dataset matching the input request
	---------------------------------------------------
	--
	SELECT top 1
		@Dataset = #XPD.Dataset, 
		@DatasetID = #XPD.Dataset_ID,
		@Folder = #XPD.Folder, 
		@StorageVol = #XPD.StorageVolServer, 
		@StoragePath = #XPD.storagePath,
		@InstrumentClass = #XPD.InstrumentClass,
		@StorageVolExternal = #XPD.StorageVolClient
	FROM
		T_Dataset with (HoldLock) 
		inner join #XPD on #XPD.Dataset_ID = T_Dataset.Dataset_ID 
	WHERE (T_Dataset.DS_state_ID = 3)
	ORDER BY T_Dataset.DS_state_ID
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
	-- set state
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
GRANT EXECUTE ON [dbo].[RequestPreparationTask_Rmed] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTask_Rmed] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTask_Rmed] TO [PNL\D3M580] AS [dbo]
GO
