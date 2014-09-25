/****** Object:  StoredProcedure [dbo].[UpdateJobInMainTables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateJobInMainTables
/****************************************************
**
**	Desc:	Updates T_Jobs, T_Job_Steps, and T_Job_Parameters
**			using the information in #Job_Parameters, #Jobs, and #Job_Steps
**
**			Note: Does not update job steps in state 5 = Complete
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	mem
**			03/11/2009 mem - Initial release (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**			03/21/2011 mem - Changed transaction name to match procedure name
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			10/17/2011 mem - Added column Memory_Usage_MB
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**    
*****************************************************/
(
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Start a transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'UpdateJobInMainTables'
	--
	begin transaction @transName
	--
	---------------------------------------------------
	-- Replace job parameters
	---------------------------------------------------
	--
	UPDATE T_Job_Parameters
	SET T_Job_Parameters.Parameters = #Job_Parameters.Parameters
	FROM T_Job_Parameters
	     INNER JOIN #Job_Parameters
	       ON #Job_Parameters.Job = T_Job_Parameters.Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end

	---------------------------------------------------
	-- Update job
	---------------------------------------------------
	--
	UPDATE T_Jobs
	SET Priority = #Jobs.Priority,
	    State = #Jobs.State,
	    Imported = Getdate(),
	    Start = Getdate(),
	    Finish = NULL
	FROM T_Jobs
	     INNER JOIN #Jobs
	       ON #Jobs.Job = T_Jobs.Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end


	-- Delete job step dependencies for job steps that are not yet completed
	DELETE T_Job_Step_Dependencies
	FROM T_Job_Step_Dependencies JSD
	     INNER JOIN T_Job_Steps JS
	       ON JSD.Job = JS.Job AND
	          JSD.Step_Number = JS.Step_Number
	     INNER JOIN #Job_Steps
	       ON JS.Job = #Job_Steps.Job AND
	          JS.Step_Number = #Job_Steps.Step_Number
	WHERE JS.State <> 5			-- 5 = Complete
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end

	-- Delete job steps that are not yet completed
	DELETE T_Job_Steps
	FROM T_Job_Steps JS
	     INNER JOIN #Job_Steps
	       ON JS.Job = #Job_Steps.Job AND
	          JS.Step_Number = #Job_Steps.Step_Number
	WHERE JS.State <> 5			-- 5 = Complete
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end
	
	---------------------------------------------------
	-- Add steps for job that currently aren't in main tables
	---------------------------------------------------

	INSERT INTO T_Job_Steps (
		Job,
		Step_Number,
		Step_Tool,
		CPU_Load,
		Memory_Usage_MB,
		Dependencies,
		Shared_Result_Version,
		Signature,
		State,
		Input_Folder_Name,
		Output_Folder_Name,
		Processor
	)	
	SELECT
		Src.Job,
		Src.Step_Number,
		Src.Step_Tool,
		Src.CPU_Load,
		Src.Memory_Usage_MB,
		Src.Dependencies,
		Src.Shared_Result_Version,
		Src.Signature,
		1,			-- State
		Src.Input_Folder_Name,
		Src.Output_Folder_Name,
		Src.Processor 
	FROM #Job_Steps Src
	     LEFT OUTER JOIN T_Job_Steps JS
	       ON JS.Job = Src.Job AND
	          JS.Step_Number = Src.Step_Number
	WHERE JS.Job Is Null
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end
	
	---------------------------------------------------
	-- add step dependencies for job that currently aren't 
	-- in main tables
	---------------------------------------------------

	INSERT INTO T_Job_Step_Dependencies (
		Job,
		Step_Number,
		Target_Step_Number,
		Condition_Test,
		Test_Value,
		Enable_Only
	)
	SELECT
		Src.Job,
		Src.Step_Number,
		Src.Target_Step_Number,
		Src.Condition_Test,
		Src.Test_Value,
		Src.Enable_Only 
	FROM #Job_Step_Dependencies Src
	     LEFT OUTER JOIN T_Job_Step_Dependencies JSD
	       ON JSD.Job = Src.Job AND
	          JSD.Step_Number = Src.Step_Number
	WHERE JSD.Job IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end

 	commit transaction @transName
 
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobInMainTables] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobInMainTables] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobInMainTables] TO [PNL\D3M580] AS [dbo]
GO
