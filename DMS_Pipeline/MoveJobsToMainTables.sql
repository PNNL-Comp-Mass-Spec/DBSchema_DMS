/****** Object:  StoredProcedure [dbo].[MoveJobsToMainTables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MoveJobsToMainTables
/****************************************************
**
**	Desc: 
**  Make move contents of temporary tables:
**      #Jobs
**      #Job_Steps
**      #Job_Step_Dependencies
**      #Job_Parameters
**  To main database tables
**
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	Date:	02/06/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			10/17/2011 mem - Added column Memory_Usage_MB
**    
*****************************************************/
(
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'MoveJobsToMainTables'

	---------------------------------------------------
	-- populate actual tables from accumulated entries
	---------------------------------------------------
/*
select * from #Jobs
select * from #Job_Steps 
select * from #Job_Step_Dependencies
select * from #Job_Parameters 
goto Done
*/

	begin transaction @transName

	UPDATE T_Jobs 
	SET
		T_Jobs.State = #Jobs.State,
		T_Jobs.Results_Folder_Name = #Jobs.Results_Folder_Name
	FROM T_Jobs INNER JOIN #Jobs ON
		T_Jobs.Job = #Jobs.Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end

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
	 FROM #Job_Steps
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end

	INSERT INTO T_Job_Step_Dependencies (
		Job_ID,
		Step_Number,
		Target_Step_Number,
		Condition_Test,
		Test_Value,
		Enable_Only
	)
	SELECT
		Job_ID,
		Step_Number,
		Target_Step_Number,
		Condition_Test,
		Test_Value,
		Enable_Only
	 FROM #Job_Step_Dependencies
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error'
		goto Done
	end

	INSERT INTO T_Job_Parameters (
		Job,
		Parameters
	)
	SELECT
		Job,
		Parameters
	FROM #Job_Parameters
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
GRANT VIEW DEFINITION ON [dbo].[MoveJobsToMainTables] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveJobsToMainTables] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveJobsToMainTables] TO [PNL\D3M580] AS [dbo]
GO
