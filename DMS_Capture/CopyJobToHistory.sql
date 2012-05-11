/****** Object:  StoredProcedure [dbo].[CopyJobToHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CopyJobToHistory
/****************************************************
**
**	Desc:
**    For a given job, copies the job details, steps, 
**    and parameters to the history tables
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	09/12/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			03/12/2012 mem - Now copying column Tool_Version_ID
**    
*****************************************************/
(
	@job int,
	@JobState int,
	@message varchar(512) output,
	@OverrideSaveTime tinyint = 0,		-- Set to 1 to use @SaveTimeOverride for the SaveTime instead of GetDate()
	@SaveTimeOverride datetime = Null
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
 	---------------------------------------------------
	-- Bail if no candidates found
 	---------------------------------------------------
	--
 	if IsNull(@job, 0) = 0
		goto Done

 	---------------------------------------------------
	-- Bail if not a state we save for
 	---------------------------------------------------
 	--
  	if not @JobState in (3,5)
		goto Done

 	---------------------------------------------------
 	-- Define a common timestamp for all history entries
 	---------------------------------------------------
 	--
	declare @saveTime datetime
	
	If IsNull(@OverrideSaveTime, 0) <> 0
		Set @SaveTime = IsNull(@saveTimeOverride, GetDate())
	Else
		set @saveTime = GetDate()

 	---------------------------------------------------
 	-- Start transaction
 	---------------------------------------------------
	--
	declare @transName varchar(64)
	set @transName = 'MoveJobsToHistory'
	begin transaction @transName

  	---------------------------------------------------
	-- copy jobs
	---------------------------------------------------
	--
	INSERT INTO T_Jobs_History (
		Job,
		Priority,
		Script,
		State,
		Dataset,
		Dataset_ID,
		Results_Folder_Name,
		Imported,
		Start,
		Finish,
		Saved
	)
	SELECT 
		Job,
		Priority,
		Script,
		State,
		Dataset,
		Dataset_ID,
		Results_Folder_Name,
		Imported,
		Start,
		Finish,
		@saveTime
	FROM   
	  T_Jobs
	WHERE  Job = @job
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
     --
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error '
		goto Done
	end

   	---------------------------------------------------
	-- copy steps
	---------------------------------------------------
	--
	INSERT INTO T_Job_Steps_History (
		Job,
		Step_Number,
		Step_Tool,
		State,
		Input_Folder_Name,
		Output_Folder_Name,
		Processor,
		Start,
		Finish,
		Completion_Code,
		Completion_Message,
		Evaluation_Code,
		Evaluation_Message,
		Saved,
		Tool_Version_ID
	)
	SELECT 
		Job,
		Step_Number,
		Step_Tool,
		State,
		Input_Folder_Name,
		Output_Folder_Name,
		Processor,
		Start,
		Finish,
		Completion_Code,
		Completion_Message,
		Evaluation_Code,
		Evaluation_Message,
		@saveTime,
		Tool_Version_ID
	FROM   
	  T_Job_Steps
	WHERE  Job = @job
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
     --
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error '
		goto Done
	end

   	---------------------------------------------------
	-- copy parameters
	---------------------------------------------------
	--
	INSERT INTO T_Job_Parameters_History (
		Job, 
		Parameters, 
		Saved
	)
	SELECT
		Job, 
		Parameters, 
		@saveTime
	FROM
		T_Job_Parameters
	WHERE 
		Job = @job
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
     --
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error '
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
