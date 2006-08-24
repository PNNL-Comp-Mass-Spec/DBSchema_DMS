/****** Object:  StoredProcedure [dbo].[RequestDataExtractionTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestDataExtractionTask
/****************************************************
**
**	Desc: 
**	Looks for 'Data Extraction Required' status
**	in the T_Analysis_State_Name table.
**	If found, the record is set to 'Data Extraction In Progress'
**	and information needed for data extraction task is returned
**	in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@toolResultType			type of analysis results to be processed
**	@requestedPriority		desired priority of job (n -> accept jobs only with priority = n)
**	@demProcessorName			name of machine performing dem processing
**	@taskID						unique identifier for analysis job
**	@message						Output message if error occurs
**
**	Auth: jds
**	Date: 1/5/2006
**        5/10/2006 grk - assigned processor removed from task assignment criteria
**                      - changed to use new extraction fields in job table
**			 5/11/2006 dac - changed to accomodate different analysis/extraction machines, removed archive state checks
**    
*****************************************************/
	@toolResultType varchar(64),
	@requestedPriority int = 0,
	@demProcessorName varchar(64),
	@taskID varchar(32) output,
	@message varchar(255) output
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	---------------------------------------------------
	-- temporary table to hold candidate jobs
	---------------------------------------------------

	CREATE TABLE #PD (
		ID  int -- ,
	) 
 
	---------------------------------------------------
	-- Populate temporary table with a small pool of 
	-- suitable jobs.
	---------------------------------------------------

	INSERT INTO #PD
	(ID)
	SELECT TOP 20  taskNum as Job
	FROM V_Data_Extraction_Task
	WHERE
		(StateID = 16) --'Data Extraction Required'
		AND (toolResultType = @toolResultType)
		AND (Priority = @requestedPriority) 
	ORDER BY Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end

	---------------------------------------------------
	--  Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'RequestDataExtractionTask'
	begin transaction @transName
	
	set @taskID = 0

	---------------------------------------------------
	-- Select and lock a specific job by joining
	-- from the local pool to the actual analysis job table.
	---------------------------------------------------

	SELECT top 1 @taskID = AJ_jobID
	FROM T_Analysis_Job with (HoldLock) 
	inner join #PD on ID = AJ_jobID 
	WHERE (AJ_StateID = 16) -- Make sure record has a status of Data Extraction Required
	Order by AJ_jobID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error looking for available job'
		goto done
	end

	if @myRowCount = 0
	begin
		rollback transaction @transName
		set @message = 'No jobs found'
		set @myError = 53000
		goto done
	end
		
	if @myRowCount <> 1
	begin
		rollback transaction @transName
		set @message = 'Invalid row count while looking for available job'
		set @myError = 53001
		goto done
	end

	---------------------------------------------------
	-- set state and assigned processor
	---------------------------------------------------

	UPDATE T_Analysis_Job 
	SET 
	AJ_StateID = 17, -- Data extraction in progress
	AJ_extractionProcessor = @demProcessorName,
	AJ_extractionStart = getdate()
	WHERE (AJ_jobID = @taskID)
	
	if @@rowcount <> 1
	begin
		rollback transaction @transName
		RAISERROR ('Update operation failed',
			10, 1)
		return 53002
	end

	commit transaction @transName
	

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError 



GO
