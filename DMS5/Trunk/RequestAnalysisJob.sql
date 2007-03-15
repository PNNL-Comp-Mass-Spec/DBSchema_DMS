/****** Object:  StoredProcedure [dbo].[RequestAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.RequestAnalysisJob
/****************************************************
**
**	Desc: Looks for analysis job that matches what
**        caller requests.  If found, job is assigned
**        to caller and job ID  is returned
**        in the output arguments
**
** Job assignment will be based on the processor name and the tool name (tool name list, actually)
** that are supplied by the analysis manager to the request stored procedure (manager program will
** not care about job priority).
** 
** 1. Search for candidate jobs that are in the "New" state whose tool is in the given tool list
** where the jobs are directly associated with a processor group in which the given processor has
** active membership. Order by priority and job number if more than one candidate is found.
** 
** 2. If no candidates were found in step 1, look for candidate jobs that are in the "New" state
** whose tool is in the given tool list where the jobs are either not associated with a processor
** group or are associated with at least one processor group that allows general processing.
** Order by priority and job number if more than one candidate is found.
** 
** A job can be exclusively locked to a specific processor group if that group declares itself not
** available for general processing, and the job is not associated with any other groups that are
** available for general processing
** 
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	@processorName			name of caller's computer
**	@jobNum					unique identifier for analysis job
**
**	Auth:	grk
**	Date:	02/08/2007
**			02/09/2007 mem - Added parameter @infoOnly
**			02/22/2007 grk - Modify to use direct job-to-group association (Ticket #382)
**			02/23/2007 grk - Modify to eliminate @toolList in favor of T_Analysis_Job_Processor_Tools
**
*****************************************************/
(
	@processorName varchar(128),
	@jobNum varchar(32)=0 output,		-- Job number assigned; 0 if no job available
    @message varchar(512)='' output,
	@infoOnly tinyint = 0			-- Set to 1 to preview the job that would be returned
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @jobID int

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	set @processorName = IsNull(@processorName, '')
	set @infoOnly = IsNull(@infoOnly, 0)

	set @jobNum = 0
	set @message = ''

	if Len(LTrim(RTrim(@processorName))) = 0
	begin
		set @message = 'Processor name is blank'
		set @myError = 50000
		goto done
	end
	
	declare @processorID int
	set @processorID = 0
	--
	SELECT  @processorID = ID
	FROM T_Analysis_Job_Processors
	WHERE Processor_Name = @processorName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving processor name to ID'
		set @myError = 50002
		goto done
	end
	--
	if @processorID = 0
	begin
		set @message = 'Invalid processor name'
		set @myError = 50003
		goto done
	end

	---------------------------------------------------
	-- temporary table to hold candidate jobs
	---------------------------------------------------

	CREATE TABLE #PD (
		Job_ID  int,
		Priority  int,
		Assignment_Method varchar(128) NULL
	) 

	---------------------------------------------------
	-- Populate temporary table with a small pool of 
	-- candidate jobs according to job-to-group
	-- associations
	---------------------------------------------------

	INSERT INTO #PD
		(Job_ID, Priority, Assignment_Method)
	SELECT DISTINCT TOP 10 
		T_Analysis_Job.AJ_jobID AS Job_ID, 
		T_Analysis_Job.AJ_priority,
		'Specific Association' as Assignment_Method
	FROM
		T_Analysis_Job  INNER JOIN
		T_Analysis_Job_Processor_Group_Associations ON T_Analysis_Job.AJ_jobID = T_Analysis_Job_Processor_Group_Associations.Job_ID INNER JOIN
		T_Analysis_Job_Processor_Group_Membership INNER JOIN
		T_Analysis_Job_Processor_Group ON 
		T_Analysis_Job_Processor_Group_Membership.Group_ID = T_Analysis_Job_Processor_Group.ID INNER JOIN
		T_Analysis_Job_Processors ON T_Analysis_Job_Processor_Group_Membership.Processor_ID = T_Analysis_Job_Processors.ID ON 
		T_Analysis_Job_Processor_Group_Associations.Group_ID = T_Analysis_Job_Processor_Group.ID
	WHERE
		(T_Analysis_Job_Processor_Group.Group_Enabled = 'Y') AND
		(T_Analysis_Job_Processor_Group_Membership.Membership_Enabled = 'Y') AND 
		(T_Analysis_Job_Processors.State = 'E') AND 
		(T_Analysis_Job.AJ_analysisToolID IN
		(SELECT Tool_ID FROM T_Analysis_Job_Processor_Tools WHERE Processor_ID = @processorID)) AND 
		(T_Analysis_Job_Processors.Processor_Name = @processorName) AND 
		(T_Analysis_Job.AJ_StateID = 1)
	ORDER BY 
		T_Analysis_Job.AJ_priority, 
		T_Analysis_Job.AJ_jobID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary candidate table'
		goto done
	end
	
	-- if there are candidates in table, go assign one
	--
	if @myRowCount > 0
	begin
		goto AssignJob
	end

	---------------------------------------------------
	-- If no candidate jobs are found via associations
	-- with groups of which processor is an active member
	-- try other jobs, if processor is allowed to do 
	-- general processing
	---------------------------------------------------

	-- Does Processor belong to least one active group that is enabled for general processing?
	--
	declare @gp int
	set @gp = 0
	--
	SELECT     
		@gp = COUNT(*)
	FROM         
		T_Analysis_Job_Processor_Group INNER JOIN
		T_Analysis_Job_Processor_Group_Membership ON 
		T_Analysis_Job_Processor_Group.ID = T_Analysis_Job_Processor_Group_Membership.Group_ID INNER JOIN
		T_Analysis_Job_Processors ON T_Analysis_Job_Processor_Group_Membership.Processor_ID = T_Analysis_Job_Processors.ID
	WHERE     
		(T_Analysis_Job_Processor_Group.Group_Enabled = 'Y') AND
		(T_Analysis_Job_Processor_Group.Available_For_General_Processing = 'Y') AND 
		(T_Analysis_Job_Processor_Group_Membership.Membership_Enabled = 'Y') AND
		(T_Analysis_Job_Processors.Processor_Name = @processorName) 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not check processor membership in pool group'
		goto done
	end
	--
	-- Processor is not allowed to do general processing, so no doughnut...
	--
	if @gp = 0
	begin
		set @myError = 50004
		set @message = 'Job not available via job-to-group association for processor "' + @processorName + '" and it is not allowed to perform general processing'
		goto Done
	end

	-- Processor is allowed to do general processing, go get some candidates
	
	-- Select some candidate jobs from jobs 
	-- that are associated with any group that is 
	-- enabled for general processing
	--
	INSERT INTO #PD
		(Job_ID, Priority, Assignment_Method)
	SELECT DISTINCT TOP 10 
		T_Analysis_Job.AJ_jobID AS Job_ID, 
		T_Analysis_Job.AJ_priority, 
		'General Association' AS Assignment_Method
	FROM
		T_Analysis_Job INNER JOIN
		T_Analysis_Job_Processor_Group_Associations ON T_Analysis_Job.AJ_jobID = T_Analysis_Job_Processor_Group_Associations.Job_ID INNER JOIN
		T_Analysis_Job_Processor_Group ON T_Analysis_Job_Processor_Group_Associations.Group_ID = T_Analysis_Job_Processor_Group.ID
	WHERE
		(T_Analysis_Job_Processor_Group.Group_Enabled = 'Y') AND 
		(T_Analysis_Job.AJ_analysisToolID IN
		(SELECT Tool_ID FROM T_Analysis_Job_Processor_Tools WHERE Processor_ID = @processorID)) AND 
		(T_Analysis_Job.AJ_StateID = 1) AND 
		(T_Analysis_Job_Processor_Group.Available_For_General_Processing = 'Y')
	ORDER BY 
		T_Analysis_Job.AJ_priority, T_Analysis_Job.AJ_jobID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary candidate table'
		goto done
	end
	
	-- Select some candidate jobs from jobs 
	-- that are not associated with any group
	--
	INSERT INTO #PD
		(Job_ID, Priority, Assignment_Method)
	SELECT TOP 10 
		T_Analysis_Job.AJ_jobID AS Job_ID, 
		T_Analysis_Job.AJ_priority, 
		'Non-Association' AS Assignment_Method
	FROM
		 T_Analysis_Job 
	WHERE
		(T_Analysis_Job.AJ_analysisToolID IN
		(SELECT Tool_ID FROM T_Analysis_Job_Processor_Tools WHERE Processor_ID = @processorID)) AND 
		(T_Analysis_Job.AJ_StateID = 1) AND
		NOT EXISTS (
			SELECT *
			FROM T_Analysis_Job_Processor_Group_Associations
			WHERE (T_Analysis_Job_Processor_Group_Associations.Job_ID = T_Analysis_Job.AJ_jobID)    
		)
	ORDER BY 
		T_Analysis_Job.AJ_priority, T_Analysis_Job.AJ_jobID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary candidate table'
		goto done
	end

AssignJob:
	---------------------------------------------------
	--  Can't assign job if no candidates
	---------------------------------------------------
	declare @tmp int
	set @tmp = 0
	--
	SELECT @tmp = count(*) FROM #PD
	--
	if @tmp = 0
	begin
		set @myError = 50005
		set @message = 'No candidate jobs were found'
		goto done
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

	SELECT TOP 1 
		@jobID = T_Analysis_Job.AJ_jobID
	FROM 
		T_Analysis_Job WITH (HoldLock) INNER JOIN
		#PD ON #PD.Job_ID = T_Analysis_Job.AJ_jobID 
	WHERE 
		(T_Analysis_Job.AJ_StateID = 1)
	ORDER BY 
		#PD.Priority, #PD.Job_ID
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
		set @message = 'No candidate could be assigned'
		set @myError = 53000
		goto done
	end

	if @infoOnly = 0
	begin -- <a>
		---------------------------------------------------
		-- set state and assigned processor
		---------------------------------------------------

		UPDATE T_Analysis_Job 
		SET 
			AJ_StateID = 2, 
			AJ_assignedProcessorName = @processorName,
			AJ_start = GetDate()
		WHERE (AJ_jobID = @jobID)
		
		if @@rowcount <> 1
		begin
			rollback transaction @transName
			RAISERROR ('Update operation failed', 10, 1)
			return 53001
		end
	end -- </a>

	commit transaction @transName

	If @infoOnly = 0
		Set @jobNum = @jobID
	Else
	Begin
		set @message = 'Job ' + Convert(varchar(12), @jobID) + ' would be assigned to processor "' + @processorName + '"'
		
		SELECT #PD.Priority, #PD.Job_ID, Group_ID, Assignment_Method, @processorName AS Processor
		FROM #PD LEFT OUTER JOIN 
			 T_Analysis_Job_Processor_Group_Associations AJPGA ON #PD.Job_ID = AJPGA.Job_ID
		ORDER BY #PD.Priority, #PD.Job_ID 
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	if @message <> '' AND @infoOnly = 0
	begin
		RAISERROR (@message, 10, 1)
	end

	return @myError

GO
