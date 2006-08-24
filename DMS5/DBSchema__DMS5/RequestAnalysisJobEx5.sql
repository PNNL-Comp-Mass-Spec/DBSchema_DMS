/****** Object:  StoredProcedure [dbo].[RequestAnalysisJobEx5] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure RequestAnalysisJobEx5
/****************************************************
**
**	Desc: Looks for analysis job that matches what
**        caller requests.  If found, job is assigned
**        to caller and job information is returned
**        in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@toolName				name of analysis tool
**	@processorName			name of caller's computer
**	@requestedPriority		desired priority of job
**							(0 -> accept higest available) (DAC note - no longer applicable after 11/17/2002)
**							(n -> accept jobs only with priority = n)
**	@requestedMinDuration   Job must have estimated average duration between requested values
**	@requestedMaxDuration
**
**	@jobNum					  unique identifier for analysis job
**	@datasetNum				   dataset on which to perform analysis
**  @datasetFolderName		
**  @datasetFolderStoragePath
**  @transferFolderPath		  folder on DMS server to receive results
**	@parmFileName			  parameter file name
**	@parmFileStoragePath	  path to storage folder that contains parameter file
**	@settingsFileName		  settings file name
**	@settingsFileStoragePath  path to storage folder that contains settings file
**	@organismDBName			  name of organism database file
**	@organismDBStoragePath	  path to storage folder that contains organism database file
**  @instClass		Instrument class
**  @comment				  comment field
**
**		Auth: grk
**		Date: 02/28/2001
**    
**		Mod: DAC
**		Date: 10/01/2001
**		Added Comment as return field, Working Directory as input field
**    
**		Mod: GRK
**		Date: 11/17/2002
**		modified for new manager architecture
**
**		Mod: DAC
**		Date: 12/16/2002
**		added instrument class to output, revised description of priority handling
**
**		Mod: GRK
**		Date: 3/5/2003
**		revised locking strategy for selecting job
**
**		Mod: GRK
**		Date: 9/17/2003
**		added logic to eliminate jobs from temporary #PD
**		that have datasets in an unsuitable archive state
**
**		Mod: GRK
**		Date: 1/14/2004
**		added logic to filter job assignment based on archive state
**
**		Mod: GRK
**		Date: 8/30/2004
**		look for processor preassignments
**
**		Mod: GRK
**		Date: 2/20/2006
**		for QC preference
**
**		04/04/2006 grk - increased sized of param file name
**
*****************************************************/
	@toolName varchar(64),
	@processorName varchar(64),
	@requestedPriority int = 0,
	@requestedMinDuration float = 0,
	@requestedMaxDuration float = 99000,

	@jobNum varchar(32) output,
	@datasetNum varchar(64) output,
	@datasetFolderName varchar(128) output,
	@datasetFolderStoragePath varchar(255) output,
	@transferFolderPath varchar(255) output,

	@parmFileName varchar(255) output,
	@parmFileStoragePath varchar(255) output,

	@settingsFileName varchar(64) output,
	@settingsFileStoragePath varchar(255) output,

	@organismDBName varchar(64) output,
	@organismDBStoragePath varchar(255) output,

	@instClass varchar(32) output,

	@comment varchar(255) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
    declare @message varchar(255)
	set @message = ''

	declare @jobID int
	
	---------------------------------------------------
	-- temporary table to hold candidate jobs
	---------------------------------------------------

	CREATE TABLE #PD (
		ID  int,
		AssignedProcessor  varchar(64)
	) 

	---------------------------------------------------
	-- Populate temporary table with a small pool of 
	-- suitable jobs.
	-- Prefer jobs with processor preassigned to requestor
	---------------------------------------------------

	INSERT INTO #PD
	(ID, AssignedProcessor)
	SELECT TOP 20  Job, ISNULL(AssignedProcessor, '')
	FROM V_Analysis_Job_Duration_Est_New
	WHERE
		(State = 'New') AND
		(ArchiveState = 'complete') AND
		(Tool = @toolName) AND 
		(Priority = @requestedPriority) AND
		( 
			(ISNULL(AssignedProcessor, '') = @processorName) OR (
				(ISNULL(AssignedProcessor, '') = '') AND
				( ISNULL([Avg Duration (min.)], 99000) BETWEEN @requestedMinDuration AND @requestedMaxDuration)
			)
		)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end

	---------------------------------------------------
	--  Eliminate jobs that have datasets 
	--  in an unsuitable archive state
	---------------------------------------------------
	
	DELETE From #PD
	WHERE ID IN
	(
		SELECT T_Analysis_Job.AJ_jobID
		FROM T_Dataset_Archive INNER JOIN
		T_Analysis_Job ON T_Dataset_Archive.AS_Dataset_ID = T_Analysis_Job.AJ_datasetID
		WHERE (T_Dataset_Archive.AS_state_ID IN (2, 7))	
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'error cleaning up pool with dataset archive state'
	end

	---------------------------------------------------
	--  Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'RequestAnalysisJob'
	begin transaction @transName
	
	set @jobID = 0

  ---------------------------------------------------
	-- Select and lock a specific job by joining
	-- from the local pool to the actual analysis job table.
	-- Prefer jobs with preassigned processor
	---------------------------------------------------

	SELECT top 1 @jobID = AJ_jobID
	FROM T_Analysis_Job with (HoldLock) 
	inner join #PD on ID = AJ_jobID 
	WHERE (AJ_StateID = 1)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error looking for available job'
		goto done
	end
	
	if @myRowCount <> 1
	begin
		rollback transaction @transName
		set @myError = 53000
		goto done
	end

	---------------------------------------------------
	-- set state and assigned processor
	---------------------------------------------------

	UPDATE T_Analysis_Job 
	SET 
	AJ_StateID = 2, 
	AJ_assignedProcessorName = @processorName,
	AJ_start = getdate()
	WHERE (AJ_jobID = @jobID)
	
	if @@rowcount <> 1
	begin
		rollback transaction @transName
		RAISERROR ('Update operation failed',
			10, 1)
		return 53001
	end

	commit transaction @transName

	---------------------------------------------------
	-- get the detailed information for the chosen job
	---------------------------------------------------
	-- 
	declare @storageServerPath varchar(64)
	--
	SELECT  
		@jobID = jobID,
		@jobNum = JobNum, 
		@datasetNum = DatasetNum, 
		@datasetFolderName = DatasetFolderName, 
		@datasetFolderStoragePath = DatasetStoragePath, 
		@parmFileName = ParmFileName, 
		@settingsFileName = SettingsFileName, 
		@parmFileStoragePath = ParmFileStoragePath, 
		@organismDBName = OrganismDBName, 
		@organismDBStoragePath = OrganismDBStoragePath,
		@instClass = InstClass,
		@comment = Comment,
		@storageServerPath = StorageServerPath 
	FROM V_Analysis_Job
	WHERE jobID = @jobID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Error getting job details'
		set @myError = 53001
		goto done
	end

	---------------------------------------------------
	-- construct storage path for settings file
	---------------------------------------------------

	set @settingsFileStoragePath = @parmFileStoragePath + 'SettingsFiles\'	--DAC change, eliminate extra "\"
	
	---------------------------------------------------
	-- get transfer directory path
	---------------------------------------------------

	-- generic part of transfer directory
	--
	SELECT @transferFolderPath = Client 
	FROM T_MiscPaths 
	WHERE ([Function] = 'AnalysisXfer')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Error getting Transfer Folder Path'
		set @myError = 53001
		goto done
	end
	
	set @transferFolderPath = @storageServerPath + @transferFolderPath

  ---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	if @message <> '' 
	begin
		set @comment = @message
		RAISERROR (@message, 10, 1)
	end

	return @myError
/**/


GO
GRANT EXECUTE ON [dbo].[RequestAnalysisJobEx5] TO [DMS_Analysis_Job_Runner]
GO
GRANT EXECUTE ON [dbo].[RequestAnalysisJobEx5] TO [DMS_SP_User]
GO
