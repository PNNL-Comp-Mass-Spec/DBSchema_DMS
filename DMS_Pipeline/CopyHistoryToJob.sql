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
**			02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**			10/05/2009 mem - Now looking up CPU_Load for each step tool
**			04/05/2011 mem - Now copying column Special_Processing
**			05/19/2011 mem - Now calling UpdateJobParameters
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			07/12/2011 mem - Now calling ValidateJobServerInfo
**			10/17/2011 mem - Added column Memory_Usage_MB
**			11/01/2011 mem - Added column Tool_Version_ID
**			11/14/2011 mem - Added column Transfer_Folder_Path
**			01/09/2012 mem - Added column Owner
**			01/19/2012 mem - Added column DataPkgID
**			03/26/2013 mem - Added column Comment
**    
*****************************************************/
(
	@job int,
	@message varchar(512)='' output
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
	
	-- find most recent successful historic job
	--
	SELECT @dateStamp = MAX(Saved)
	FROM T_Jobs_History
	WHERE Job = @job AND State = 4
	GROUP BY Job, State
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

  	---------------------------------------------------
	-- copy jobs
	---------------------------------------------------
	--
	INSERT INTO T_Jobs (
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
		Comment
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
		Comment
	FROM
		T_Jobs_History
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
	-- copy steps
	---------------------------------------------------
	--
	INSERT INTO T_Job_Steps (
		Job,
		Step_Number,
		Step_Tool,
		CPU_Load,
		Memory_Usage_MB,
		Shared_Result_Version,
		Signature,
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
	SELECT H.Job,
	       H.Step_Number,
	       H.Step_Tool,
	       ST.CPU_Load,
	       H.Memory_Usage_MB,
	       H.Shared_Result_Version,
	       H.Signature,
	       H.State,
	       H.Input_Folder_Name,
	       H.Output_Folder_Name,
	       H.Processor,
	       H.Start,
	       H.Finish,
	       H.Tool_Version_ID,
	       H.Completion_Code,
	       H.Completion_Message,
	       H.Evaluation_Code,
	       H.Evaluation_Message
	FROM T_Job_Steps_History H
	     INNER JOIN T_Step_Tools ST
	       ON H.Step_Tool = ST.Name
	WHERE H.Job = @job AND
	      H.Saved = @dateStamp
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
		Job, 
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
	-- Update the job parameters in case any parameters have changed (in particular, storage path)
	---------------------------------------------------
	--
	exec @myError = UpdateJobParameters @job, @infoOnly=0


	---------------------------------------------------
	-- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
	---------------------------------------------------
	--
	exec ValidateJobServerInfo @job, @UseJobParameters=1
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError
ALTER PROCEDURE CopyHistoryToJob
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
**			02/06/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**			10/05/2009 mem - Now looking up CPU_Load for each step tool
**			04/05/2011 mem - Now copying column Special_Processing
**			05/19/2011 mem - Now calling UpdateJobParameters
**			05/25/2011 mem - Removed priority column from T_Job_Steps
**			07/12/2011 mem - Now calling ValidateJobServerInfo
**			10/17/2011 mem - Added column Memory_Usage_MB
**			11/01/2011 mem - Added column Tool_Version_ID
**			11/14/2011 mem - Added column Transfer_Folder_Path
**			01/09/2012 mem - Added column Owner
**			01/19/2012 mem - Added column DataPkgID
**			03/26/2013 mem - Added column Comment
**    
*****************************************************/
(
	@job int,
	@message varchar(512)='' output
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
	
	-- find most recent successful historic job
	--
	SELECT @dateStamp = MAX(Saved)
	FROM T_Jobs_History
	WHERE Job = @job AND State = 4
	GROUP BY Job, State
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

  	---------------------------------------------------
	-- copy jobs
	---------------------------------------------------
	--
	INSERT INTO T_Jobs (
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
		Comment
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
		Comment
	FROM
		T_Jobs_History
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
	-- copy steps
	---------------------------------------------------
	--
	INSERT INTO T_Job_Steps (
		Job,
		Step_Number,
		Step_Tool,
		CPU_Load,
		Memory_Usage_MB,
		Shared_Result_Version,
		Signature,
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
	SELECT H.Job,
	       H.Step_Number,
	       H.Step_Tool,
	       ST.CPU_Load,
	       H.Memory_Usage_MB,
	       H.Shared_Result_Version,
	       H.Signature,
	       H.State,
	       H.Input_Folder_Name,
	       H.Output_Folder_Name,
	       H.Processor,
	       H.Start,
	       H.Finish,
	       H.Tool_Version_ID,
	       H.Completion_Code,
	       H.Completion_Message,
	       H.Evaluation_Code,
	       H.Evaluation_Message
	FROM T_Job_Steps_History H
	     INNER JOIN T_Step_Tools ST
	       ON H.Step_Tool = ST.Name
	WHERE H.Job = @job AND
	      H.Saved = @dateStamp
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
		Job, 
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
	-- Update the job parameters in case any parameters have changed (in particular, storage path)
	---------------------------------------------------
	--
	exec @myError = UpdateJobParameters @job, @infoOnly=0


	---------------------------------------------------
	-- Make sure Transfer_Folder_Path and Storage_Server are up-to-date in T_Jobs
	---------------------------------------------------
	--
	exec ValidateJobServerInfo @job, @UseJobParameters=1
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CopyHistoryToJob] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyHistoryToJob] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CopyHistoryToJob] TO [PNL\D3M580] AS [dbo]
GO
