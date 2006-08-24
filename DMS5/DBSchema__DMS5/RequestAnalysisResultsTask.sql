/****** Object:  StoredProcedure [dbo].[RequestAnalysisResultsTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure RequestAnalysisResultsTask
/****************************************************
**
**	Desc: 
**	Looks for analysis job that needs to have its results
**	transferred from receiving folder to dataset folder.
**
**	All information needed for transfer task is returned
**	in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**  if DatasetID is returned 0, no available job was found
**
**		Auth: grk
**		Date: 11/6/2002
**    
**    
*****************************************************/
	@StorageServerName varchar(64),
  @JobNum varchar(32) output,
  @dataset varchar(128) output,
	@DatasetFolder varchar(256) output,
	@ResultsFolder varchar(256) output,
	@ProcessorName varchar(64) output,
	@TransferPath varchar(256) output,
	@StorageVol varchar(256) output, 
	@storagePath varchar(256) output,  			
	@StorageVolExternal varchar(256) output, -- use instead of @StorageVol when manager is not on same machine as dataset folder
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
    set @dataset = ''
	set @DatasetFolder = ''
	set @ResultsFolder = ''
	set @ProcessorName = '' 
	set @TransferPath  = ''
	set @StorageVol  = ''
	set @storagePath = ''
	set @JobNum = ''
	set @StorageVolExternal = ''

	declare @storageID int
	declare @jobID int
	
	---------------------------------------------------
	-- temporary table to hold candidate results requests
	---------------------------------------------------

	CREATE TABLE #XPD (
		Job int, 
		Dataset varchar(128), 
		StorageVol varchar(256), 
		StoragePath varchar(256), 
		StorageVolExternal varchar(128),
		DatasetFolder varchar(128), 
		Processor varchar(128), 
		ResultsFolder varchar(256), 
		ServerRelativeTransferPath varchar(256)
	) 
	
	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- results requests for given storage server
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	INSERT INTO #XPD
	SELECT TOP 5    
		Job, 
		Dataset, 
		StorageVol, 
		StoragePath, 
		StorageVolExternal,
		DatasetFolder, 
		Processor, 
		ResultsFolder, 
		ServerRelativeTransferPath
	FROM V_Get_Received_Analysis_Results
	WHERE (StorageServer = @StorageServerName)
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
	--
	declare @transName varchar(32)
	set @transName = 'RequestAnalysisResultsTask'
	begin transaction @transName
	
  ---------------------------------------------------
	-- Select and lock a specific dataset by joining
	-- from the local pool to the actual analysis job table
	-- Note:  This takes a lock on the selected row
	-- so that that dataset can be exclusively assigned,
	-- but only locks T_Dataset table, not the others
	-- involved in resolving the request
	---------------------------------------------------

	set @jobID = 0
	--
	SELECT	TOP 1 
		@jobID = #XPD.Job,
	  @dataset = #XPD.Dataset,
		@DatasetFolder = #XPD.DatasetFolder,
		@ResultsFolder = #XPD.ResultsFolder,
		@ProcessorName = #XPD.Processor,
		@TransferPath = #XPD.ServerRelativeTransferPath,
		@StorageVol = #XPD.StorageVol, 
		@storagePath = #XPD.StoragePath,  			
		@StorageVolExternal = #XPD.StorageVolExternal
	FROM T_Analysis_Job with (HoldLock)
		inner join #XPD on #XPD.Job = T_Analysis_Job.AJ_jobID 
	WHERE (AJ_StateID = 3)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Find job operation failed'
		goto done
	end
	
  ---------------------------------------------------
	-- Check to see if job was found
	---------------------------------------------------
	
	if @jobID = 0
	begin
		rollback transaction @transName
		set @message = 'No jobs available'
		goto done
	end
	
	---------------------------------------------------
	-- Update job status
	---------------------------------------------------
	
	UPDATE T_Analysis_Job 
	SET 
		AJ_finish = GETDATE(), 
		AJ_StateID = 9 -- transfer in progress
	WHERE (AJ_jobID = @jobID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		rollback transaction @transName
		set @message = 'Update operation failed'
		goto done
	end

	commit transaction @transName

  ---------------------------------------------------
	-- resolve job number to job ID
	---------------------------------------------------
	--
	set @JobNum = cast(@jobID as varchar(32))


   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[RequestAnalysisResultsTask] TO [DMS_SP_User]
GO
