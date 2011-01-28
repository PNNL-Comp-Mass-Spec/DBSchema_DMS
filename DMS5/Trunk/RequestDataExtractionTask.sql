/****** Object:  StoredProcedure [dbo].[RequestDataExtractionTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RequestDataExtractionTask 
/****************************************************
**
**	Desc: Looks for data extraction tasks that 
**        match what caller requests.  If found, task is 
**        assigned to caller and task ID  is returned
**        in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@toolTypes				Comma-delimited list of tool types supported by calling manager
**  @priorityList			Comma-delimited list of priorities supported by calling manager
**  @mgrName					Name of data extraction manager that's calling SP
**	@jobNum					unique identifier for results transfer job
**  @infoOnly				preview switch
**
**	Auth:	dac
**	06/27/2007 -- initial release
**	09/25/2007 grk - Rolled back to DMS from broker (http://prismtrac.pnl.gov/trac/ticket/537)
**
*****************************************************/
(
	@toolTypes varchar(128),
	@priorityList varchar(64),
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

	declare @jobID int
	
	-- The data extraction manager expects a non-zero return value if no jobs are available
	-- Code 53000 is used for this
	declare @taskNotAvailableErrorCode int
	set @taskNotAvailableErrorCode = 53000
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	set @toolTypes = IsNull(@toolTypes, '')
	set @priorityList = IsNull(@priorityList, '')
	set @infoOnly = IsNull(@infoOnly, 0)

	set @jobNum = 0
	set @message = ''

	if Len(LTrim(RTrim(@toolTypes))) = 0
	begin
		set @message = 'Tool types list is blank'
		set @myError = 50000
		goto Done
	end
	
	if Len(LTrim(RTrim(@priorityList))) = 0
	begin
		set @message = 'Priority list is blank'
		set @myError = 51000
		goto Done
	end

	---------------------------------------------------
	-- temporary table to hold candidate tasks
	---------------------------------------------------

	CREATE TABLE #PD (
		Job  int,
		AssignmentState  int,
		Priority int
	) 

	---------------------------------------------------
	-- Convert delimited list of tool types to table variable
	---------------------------------------------------
	
	DECLARE @ToolTypeTable TABLE(Item varchar(128))
	--
	INSERT INTO @ToolTypeTable(Item)
	SELECT Item FROM dbo.MakeTableFromList(@toolTypes)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error converting tool type list'
		goto Done
	end

	---------------------------------------------------
	-- Convert delimited list of priorities to table variable
	---------------------------------------------------
	
	DECLARE @PriorityListTable TABLE(Item int)
	--
	INSERT INTO @PriorityListTable(Item)
	SELECT Item FROM dbo.MakeTableFromList(@priorityList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error converting priority list'
		goto Done
	end


	---------------------------------------------------
	-- Populate temporary table with a small pool of 
	-- candidate tasks
	---------------------------------------------------
	INSERT INTO #PD
	(Job)
	SELECT TOP 20
		AJ_jobID
	FROM         
		T_Analysis_Job INNER JOIN
		T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID
	WHERE
		AJ_StateID = 16 AND
		AJT_resultType IN (SELECT Item FROM @ToolTypeTable) AND 
		AJ_priority IN (SELECT Item FROM @PriorityListTable)
	ORDER BY AJ_jobID
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
	--  Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'RequestDataExtractionTask'
	begin transaction @transName
	
	set @jobNum = 0

	---------------------------------------------------
	-- Select and lock a specific job by joining
	-- from the local pool to the actual analysis job table.
	---------------------------------------------------

	SELECT top 1 @jobNum = AJ_jobID
	FROM T_Analysis_Job with (HoldLock) 
	inner join #PD on Job = AJ_jobID 
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

	If @infoOnly = 0
	begin
		UPDATE T_Analysis_Job 
		SET 
		AJ_StateID = 17, -- Data extraction in progress
--		AJ_extractionProcessor = @demProcessorName,  NEED TO FIX
		AJ_extractionStart = getdate()
		WHERE (AJ_jobID = @jobNum)
		
		if @@rowcount <> 1
		begin
			rollback transaction @transName
			RAISERROR ('Update operation failed',
				10, 1)
			return 53002
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
GRANT VIEW DEFINITION ON [dbo].[RequestDataExtractionTask] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestDataExtractionTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestDataExtractionTask] TO [PNL\D3M580] AS [dbo]
GO
