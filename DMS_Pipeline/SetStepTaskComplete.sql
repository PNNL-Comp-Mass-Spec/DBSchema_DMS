/****** Object:  StoredProcedure [dbo].[SetStepTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetStepTaskComplete
/****************************************************
**
**	Desc: 
**		Mark job step as complete
**		Also updates CPU and Memory info tracked by T_Machines
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**			05/07/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			06/17/2008 dac - Added default values for completionMessage, evaluationCode, and evaluationMessage
**			10/05/2009 mem - Now allowing for CPU_Load to be null in T_Job_Steps
**			10/17/2011 mem - Added column Memory_Usage_MB
**			09/25/2012 mem - Expanded @organismDBName to varchar(128)
**    
*****************************************************/
(
    @job int,
    @step int,
    @completionCode int,
    @completionMessage varchar(256) = '',
    @evaluationCode int = 0,
    @evaluationMessage varchar(256) = '',
	@organismDBName varchar(128) = ''
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @message varchar(512)
	set @message = ''
	
	---------------------------------------------------
	-- get current state of this job step
	---------------------------------------------------
	--
	declare @processor varchar(64)
	declare @state tinyint
	declare @cpuLoad smallint
	declare @MemoryUsageMB int
	declare @machine varchar(64)
	--
	set @processor = ''
	set @state = 0
	set @cpuLoad = 0
	set @MemoryUsageMB = 0
	set @machine = ''
	--
	SELECT	
		@machine = Machine,
		@cpuLoad = IsNull(CPU_Load, 1),
		@MemoryUsageMB = IsNull(Memory_Usage_MB, 0),
		@state = State,
		@processor = Processor
	FROM T_Job_Steps
	WHERE (Job = @job) AND (Step_Number = @step)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting machine name from T_Job_Steps'
		goto Done
	end
	--
	if IsNull(@machine, '') = ''
	begin
		set @myError = 66
		set @message = 'Could not find machine name in T_Job_Steps'
		goto Done
	end
	--
	if @state <> 4
	begin
		set @myError = 67
		set @message = 'Job step is not in correct state (4) to be completed'
		goto Done
	end

	---------------------------------------------------
	-- Determine completion state
	---------------------------------------------------
	--
	declare @stepState int

	if @completionCode = 0
		set @stepState = 5 -- success
	else
		set @stepState = 6 -- fail

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'SetStepTaskComplete'
		
	-- Start transaction
	begin transaction @transName

	---------------------------------------------------
	-- Update job step
	---------------------------------------------------
	--
	UPDATE T_Job_Steps
	SET    State = @stepState,
		   Finish = Getdate(),
		   Completion_Code = @completionCode,
		   Completion_Message = @completionMessage,
		   Evaluation_Code = @evaluationCode,
		   Evaluation_Message = @evaluationMessage
	WHERE  (Job = @job)
	AND (Step_Number = @step)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating step table'
		goto Done
	end
	
	---------------------------------------------------
	-- Update machine loading for this job step's processor's machine
	---------------------------------------------------
	--
	UPDATE T_Machines
	SET CPUs_Available = CPUs_Available + @cpuLoad,
	    Memory_Available = Memory_Available + @MemoryUsageMB
	WHERE (Machine = @machine)

 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error updating CPU loading'
		goto Done
	end

	-- update was successful
	commit transaction @transName

	---------------------------------------------------
	-- Update fasta file name (if one passed in from tool manager)
	---------------------------------------------------
	--
	if IsNull(@organismDBName,'') <> ''
	begin
		UPDATE T_Jobs
		SET Organism_DB_Name = @organismDBName
		WHERE Job = @job	
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error updating organism DB name'
			goto Done
		end
	end
		
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [svc-dms] AS [dbo]
GO
