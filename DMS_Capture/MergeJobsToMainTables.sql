/****** Object:  StoredProcedure [dbo].[MergeJobsToMainTables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MergeJobsToMainTables
/****************************************************
**
**	Desc: 
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	Date:	02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
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


/*
select * from #Jobs
select * from #Job_Steps 
select * from #Job_Step_Dependencies
select * from #Job_Parameters 
goto Done
*/

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'MergeJobsToMainTables'
	--
	begin transaction @transName
	--
	---------------------------------------------------
	-- replace job parameters
	---------------------------------------------------
	--
	UPDATE T_Job_Parameters
		SET T_Job_Parameters.Parameters = #Job_Parameters.Parameters
	FROM T_Job_Parameters INNER JOIN
	#Job_Parameters ON #Job_Parameters.Job = T_Job_Parameters.Job
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
	-- update job
	---------------------------------------------------
	--
	UPDATE T_Jobs
	SET
		Priority = #Jobs.Priority,
		State = #Jobs.State,
		Imported = Getdate(),
		Start = Getdate(),
		Finish = NULL
	FROM T_Jobs INNER JOIN
	#Jobs ON #Jobs.Job = T_Jobs.Job
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
	-- add steps for job that currently aren't in main tables
	---------------------------------------------------

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
	WHERE NOT EXISTS 
	(
		SELECT * 
		FROM T_Job_Steps
		WHERE 
			T_Job_Steps.Job = #Job_Steps.Job and 
			T_Job_Steps.Step_Number = #Job_Steps.Step_Number
	)
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
		Job,
		Step_Number,
		Target_Step_Number,
		Condition_Test,
		Test_Value,
		Enable_Only 
	FROM #Job_Step_Dependencies
	WHERE NOT EXISTS 
	(
		SELECT * 
		FROM T_Job_Step_Dependencies
		WHERE 
			T_Job_Step_Dependencies.Job = #Job_Step_Dependencies.Job and
			T_Job_Step_Dependencies.Step_Number = #Job_Step_Dependencies.Step_Number
	)
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
