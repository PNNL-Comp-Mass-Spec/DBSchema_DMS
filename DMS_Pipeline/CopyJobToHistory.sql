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
**			12/17/2008 grk - Initial alpha
**			02/06/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**			04/05/2011 mem - Now copying column Special_Processing
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			07/05/2011 mem - Now copying column Tool_Version_ID
**			11/14/2011 mem - Now copying column Transfer_Folder_Path
**			01/09/2012 mem - Added column Owner
**			01/19/2012 mem - Added columns DataPkgID and Memory_Usage_MB
**			03/26/2013 mem - Added column Comment
**			01/20/2014 mem - Added T_Job_Step_Dependencies_History
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
	declare @myRowCount int
	set @myError = 0
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
  	if not @JobState in (4,5)
  	Begin
  		Set @message = 'Job state not 4 or 5; aborting'
  		Print @message
		goto Done
	End

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
		Organism_DB_Name,
		Special_Processing,
		Imported,
		Start,
		Finish,
		Transfer_Folder_Path,
		Owner,
		DataPkgID,
		Comment,
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
		Organism_DB_Name,
		Special_Processing,
		Imported,
		Start,
		Finish,
		Transfer_Folder_Path,
		Owner,
		DataPkgID,
		Comment,
		@saveTime
	FROM T_Jobs
	WHERE Job = @job
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
		Memory_Usage_MB,
		Shared_Result_Version,
		Signature,
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
		Memory_Usage_MB,
		Shared_Result_Version,
		Signature,
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
	FROM T_Job_Steps
	WHERE Job = @job
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
	FROM T_Job_Parameters
	WHERE Job = @job
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
	-- Copy job step dependencies
	---------------------------------------------------
	--
	-- First delete any extra steps for this job that are in T_Job_Step_Dependencies_History
	DELETE T_Job_Step_Dependencies_History
	FROM T_Job_Step_Dependencies_History Target
	     LEFT OUTER JOIN T_Job_Step_Dependencies Source
	       ON Target.Job_ID = Source.Job_ID AND
	          Target.Step_Number = Source.Step_Number AND
	          Target.Target_Step_Number = Source.Target_Step_Number
	WHERE Target.Job_ID = @job AND
	      Source.Job_ID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
    --
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error '
		goto Done
	end
		
	-- Now add/update the job step dependencies
	--
	MERGE T_Job_Step_Dependencies_History AS target
	USING ( SELECT Job_ID, Step_Number, Target_Step_Number, Condition_Test, Test_Value, 
	               Evaluated, Triggered, Enable_Only
	        FROM T_Job_Step_Dependencies
	        WHERE Job_ID = @job	
	      ) AS Source (Job_ID, Step_Number, Target_Step_Number, Condition_Test, Test_Value, Evaluated, Triggered, Enable_Only)
	       ON (target.Job_ID = source.Job_ID And 
	           target.Step_Number = source.Step_Number And
	           target.Target_Step_Number = source.Target_Step_Number)
	WHEN Matched THEN 
		UPDATE Set 
			Condition_Test = source.Condition_Test,
			Test_Value = source.Test_Value,
			Evaluated = source.Evaluated,
			Triggered = source.Triggered,
			Enable_Only = source.Enable_Only,
			Saved = @saveTime
	WHEN Not Matched THEN
		INSERT (Job_ID, Step_Number, Target_Step_Number, Condition_Test, Test_Value, 
		        Evaluated, Triggered, Enable_Only, Saved)
		VALUES (source.Job_ID, source.Step_Number, source.Target_Step_Number, source.Condition_Test, source.Test_Value, 
		        source.Evaluated, source.Triggered, source.Enable_Only, @saveTime)
	;		
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
GRANT VIEW DEFINITION ON [dbo].[CopyJobToHistory] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyJobToHistory] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyJobToHistory] TO [PNL\D3M580] AS [dbo]
GO
