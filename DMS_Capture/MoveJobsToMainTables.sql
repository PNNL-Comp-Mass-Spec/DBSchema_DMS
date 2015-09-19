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
**			05/29/2015 mem - Add support for column Capture_Subfolder
**			09/17/2015 mem - Added parameter @DebugMode
**    
*****************************************************/
(
	@message varchar(512) output,
	@DebugMode tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	set @DebugMode = IsNull(@DebugMode, 0)

	---------------------------------------------------
	-- set up transaction parameters
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'MoveJobsToMainTables'

	---------------------------------------------------
	-- populate actual tables from accumulated entries
	---------------------------------------------------
	
	If @DebugMode <> 0
	Begin
		If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobs') Drop table T_Tmp_NewJobs
		If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobSteps') Drop table T_Tmp_NewJobSteps
		If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobStepDependencies') Drop table T_Tmp_NewJobStepDependencies
		If Exists (Select * from sys.tables where Name = 'T_Tmp_NewJobParameters') Drop table T_Tmp_NewJobParameters

		select * INTO T_Tmp_NewJobs from #Jobs 
		select * INTO T_Tmp_NewJobSteps from #Job_Steps  
		select * INTO T_Tmp_NewJobStepDependencies from #Job_Step_Dependencies 
		select * INTO T_Tmp_NewJobParameters from #Job_Parameters 
	End

	begin transaction @transName

	UPDATE T_Jobs 
	SET
		State = #Jobs.State,
		Results_Folder_Name = #Jobs.Results_Folder_Name,
		Storage_Server = #Jobs.Storage_Server,
		Instrument = #Jobs.Instrument,
		Instrument_Class = #Jobs.Instrument_Class,
		Max_Simultaneous_Captures = #Jobs.Max_Simultaneous_Captures,
		Capture_Subfolder = #Jobs.Capture_Subfolder
	FROM T_Jobs Target INNER JOIN #Jobs ON
		 Target.Job = #Jobs.Job
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
