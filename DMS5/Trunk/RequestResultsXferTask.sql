/****** Object:  StoredProcedure [dbo].[RequestResultsXferTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestResultsXferTask 
/****************************************************
**
**	Desc: Looks for analysis results transfer tasks that 
**        match what caller requests.  If found, task is 
**        assigned to caller and task ID  is returned
**        in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@machineName			name of storage server results transfer will occur on
** @mgrName					Name results manager that's calling SP
**	@jobNum					unique identifier for results transfer job
** @infoOnly				preview switch
**
**	Auth:	dac
**	05/10/2007 -- initial release
**	09/25/2007 grk - Rolled back to DMS from broker (http://prismtrac.pnl.gov/trac/ticket/537)
**	11/26/2007 grk - prevent assigning task while archive operation in progress (http://prismtrac.pnl.gov/trac/ticket/396)
**
*****************************************************/
(
	@machineName varchar(128),
	@mgrName varchar(50),
	@jobNum int = 0 output,		-- Job number assigned; 0 if no job available
	@message varchar(512)='' output,
	@infoOnly tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @infoOnly = IsNull(@infoOnly, 0)
	
	-- The results manager expects a non-zero return value if no jobs are available
	-- Code 53000 is used for this
	declare @taskNotAvailableErrorCode int
	set @taskNotAvailableErrorCode = 53000
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	set @machineName = IsNull(@machineName, '')
	set @infoOnly = IsNull(@infoOnly, 0)

	set @jobNum = 0
	set @message = ''

	if Len(LTrim(RTrim(@machineName))) = 0
	begin
		set @message = 'Machine name is blank'
		set @myError = 50000
		goto Done
	end
	
	---------------------------------------------------
	-- temporary table to hold candidate tasks
	---------------------------------------------------

	CREATE TABLE #PD (
		Job  int
	) 

	---------------------------------------------------
	-- Populate temporary table with  
	-- candidate tasks for this storage server
	---------------------------------------------------
	
	INSERT INTO #PD
	SELECT   
	  T_Analysis_Job.AJ_jobID
	FROM     
	  T_Dataset
	  INNER JOIN T_Analysis_Job
		ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
	  INNER JOIN t_storage_path
		ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID
	  INNER JOIN T_Dataset_Archive
		ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
	WHERE    (T_Analysis_Job.AJ_StateID = 3)
	AND (t_storage_path.SP_machine_name = @machineName)
	AND (NOT (T_Dataset_Archive.AS_state_ID IN (2,7,12)))
	AND (NOT (T_Dataset_Archive.AS_update_state_ID IN (3)))
	ORDER BY T_Analysis_Job.AJ_jobID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary candidate table'
		goto Done
	end
	
	-- if there are candidates in table, go assign one
	--
	if @myRowCount = 0
	begin
		set @myError = @taskNotAvailableErrorCode
		set @message = 'No task found'
		goto Done
	end
  ---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	-- 
	--
	declare @transName varchar(32)
	set @transName = 'RequestResultsXferTask'
	begin transaction @transName
	
  ---------------------------------------------------
	-- Select and lock a specific dataset by joining
	-- from the local pool to the actual analysis job table
	-- Note:  This takes a lock on the selected row
	-- so that that dataset can be exclusively assigned,
	-- but only locks T_Dataset table, not the others
	-- involved in resolving the request
	---------------------------------------------------

	set @jobNum = 0
	--
	SELECT	TOP 1 
		@jobNum = #PD.Job
	FROM T_Analysis_Job with (HoldLock)
		inner join #PD on #PD.Job = T_Analysis_Job.AJ_jobID 
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
	
	if @jobNum = 0
	begin
		rollback transaction @transName
		set @message = 'No jobs available'
		goto done
	end
	
	---------------------------------------------------
	-- Update job status
	---------------------------------------------------
	
	If @infoOnly = 0
	begin
		UPDATE T_Analysis_Job 
		SET 
			AJ_finish = GETDATE(), 
			AJ_StateID = 9 -- transfer in progress
		WHERE (AJ_jobID = @jobNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			rollback transaction @transName
			set @message = 'Update operation failed'
			goto done
		end
	end

	commit transaction @transName

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	if @message <> '' AND @myError <> @taskNotAvailableErrorCode AND @infoOnly = 0
	begin
		RAISERROR (@message, 10, 1)
	end

	return @myError

 
GO
GRANT VIEW DEFINITION ON [dbo].[RequestResultsXferTask] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestResultsXferTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestResultsXferTask] TO [PNL\D3M580] AS [dbo]
GO
