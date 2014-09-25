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
**			01/14/2010 grk - removed path ID fields
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
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
		T_Jobs.Results_Folder_Name = #Jobs.Results_Folder_Name,
		T_Jobs.Storage_Server = #Jobs.Storage_Server,
		T_Jobs.Instrument = #Jobs.Instrument,
		T_Jobs.Instrument_Class = #Jobs.Instrument_Class,
		T_Jobs.Max_Simultaneous_Captures = #Jobs.Max_Simultaneous_Captures
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
		Dependencies,
		State,
		Input_Folder_Name,
		Output_Folder_Name,
		Processor,
		Holdoff_Interval_Minutes,
		Retry_Count
	)	
	SELECT
		Job,
		Step_Number,
		Step_Tool,
		CPU_Load,
		Dependencies,
		State,
		Input_Folder_Name,
		Output_Folder_Name,
		Processor,
		Holdoff_Interval_Minutes,
		Retry_Count
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
		Job,
		Step_Number,
		Target_Step_Number,
		Condition_Test,
		Test_Value,
		Enable_Only
	)
	SELECT
		Job,
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
