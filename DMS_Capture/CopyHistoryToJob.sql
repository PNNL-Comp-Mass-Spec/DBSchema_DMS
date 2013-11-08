/****** Object:  StoredProcedure [dbo].[CopyHistoryToJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CopyHistoryToJob
/****************************************************
**
**	Desc:
**    For a given job, copies the job details, steps, 
**    and parameters from the most recent successful
**    run in the history tables back into the main tables
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			03/12/2012 mem - Added column Tool_Version_ID
**			03/21/2012 mem - Now disabling identity_insert prior to inserting a row into T_Jobs
**						   - Fixed bug finding most recent successful job in T_Jobs_History
**			08/27/2013 mem - Now calling UpdateParametersForJob
**			10/21/2013 mem - Added @AssignNewJobNumber
**    
*****************************************************/
(
	@job int,
	@AssignNewJobNumber tinyint = 0,			-- Set to 1 to assign a new job number when copying
	@message varchar(512) = '' output
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

	Set @AssignNewJobNumber = IsNull(@AssignNewJobNumber, 0)
	
 	---------------------------------------------------
	-- Bail if job already exists in main tables
 	---------------------------------------------------
 	--
	if exists (select * from T_Jobs where Job = @job)
	begin
		GOTO Done
	end

	---------------------------------------------------
	-- Get job status from most recent completed historic job
	---------------------------------------------------
	--
	declare @dateStamp datetime
	--
	-- find most recent successful historic job
	SELECT @dateStamp = MAX(Saved)
	FROM T_Jobs_History
	GROUP BY Job, State
	HAVING Job = @job AND State = 3
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
    --
	if @myError <> 0
	begin
		set @message = 'Error '
		goto Done
	end

 	---------------------------------------------------
 	-- Start transaction
 	---------------------------------------------------
	--
	declare @transName varchar(64)
	set @transName = 'CopyHistoryToJob'
	begin transaction @transName

	
	Declare @NewJob int = @Job
	
	If @AssignNewJobNumber = 0
	Begin
		set identity_insert dbo.T_Jobs ON		
			
		INSERT INTO T_Jobs( Job, Priority, Script, State,
		                    Dataset, Dataset_ID, Results_Folder_Name,
		                    Imported, Start, Finish )
		SELECT Job, Priority, Script, State,
		       Dataset, Dataset_ID, Results_Folder_Name,
		       Imported, Start, Finish
		FROM T_Jobs_History
		WHERE Job = @job AND
		      Saved = @dateStamp
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error '
			goto Done
		end	
	
		set identity_insert dbo.T_Jobs OFF
	End
	Else
	Begin
		INSERT INTO T_Jobs( Priority, Script, State,
		                    Dataset, Dataset_ID, Results_Folder_Name,
		                    Imported, Start, Finish )
		SELECT Priority, Script, State,
		       Dataset, Dataset_ID, Results_Folder_Name,
		       GetDate(), Start, Finish
		FROM T_Jobs_History
		WHERE Job = @job AND
		      Saved = @dateStamp
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount, @NewJob = Scope_Identity()
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error '
			goto Done
		end	
		
		If @NewJob is null
		Begin
			rollback transaction @transName
			set @message = 'Error: Scope_Identity() returned null'
			goto Done
		end
		
		Print 'Cloned job ' + Convert(varchar(12), @job) + ' to create job ' + Convert(varchar(12), @NewJob)
	End

  	---------------------------------------------------
	-- copy steps
	---------------------------------------------------
	--
	INSERT INTO T_Job_Steps (
		Job,
		Step_Number,
		Step_Tool,
		State,
		Input_Folder_Name,
		Output_Folder_Name,
		Processor,
		Start,
		Finish,
		Tool_Version_ID,
		Completion_Code,
		Completion_Message,
		Evaluation_Code,
		Evaluation_Message
	)
	SELECT 
		@NewJob AS Job,
		Step_Number,
		Step_Tool,
		State,
		Input_Folder_Name,
		Output_Folder_Name,
		Processor,
		Start,
		Finish,
		Tool_Version_ID,
		Completion_Code,
		Completion_Message,
		Evaluation_Code,
		Evaluation_Message
	FROM
		T_Job_Steps_History
	WHERE
		Job = @job AND
		Saved = @dateStamp 
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
	INSERT INTO T_Job_Parameters (
		Job, 
		Parameters
	)
	SELECT
		@NewJob AS Job, 
		Parameters
	FROM
		T_Job_Parameters_History
	WHERE 
		Job = @job AND
		Saved = @dateStamp
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
	-- Manually create the job parameters if they were not present in T_Job_Parameters
	---------------------------------------------------
	
	If Not Exists (SELECT * FROM T_Job_Parameters WHERE Job = @NewJob)
	Begin
		exec UpdateParametersForJob @NewJob
	End
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	if @myError <> 0
		print @message
		
	return @myError

GO
