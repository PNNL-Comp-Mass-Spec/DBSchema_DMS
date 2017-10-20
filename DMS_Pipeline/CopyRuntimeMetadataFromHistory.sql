/****** Object:  StoredProcedure [dbo].[CopyRuntimeMetadataFromHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE CopyRuntimeMetadataFromHistory
/****************************************************
**
**	Desc:
**		Copies selected pieces of metadata from the history tables
**		to T_Jobs and T_Job_Steps.  Specifically,
**		  Start, Finish, Processor, 
**		  Completion_Code, Completion_Message, 
**		  Evaluation_Code, Evaluation_Message, 
**		  Tool_Version_ID, Remote_Info_ID, 
**		  Remote_Timestamp, Remote_Start, Remote_Finish
**
**		This procedure is intended to be used after re-running a job step
**		for debugging purposes, but the files created by the job step
**		were only used for comparison purposes back to the original results
**
**		It will only copy the runtime metadata if the Results_Transfer steps
**		in T_Job_Steps match exactly the Results_Transfer steps in T_Job_Steps_History
**
**	Auth:	mem
**			02/06/2009 mem - Initial release
**    
*****************************************************/
(
	@jobList varchar(2048),
	@infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @job int
	Declare @jobStep int
		
 	---------------------------------------------------
	-- Validate the inputs
 	---------------------------------------------------
	--
 	Set @jobList = IsNull(@jobList, '')
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''
	
 	---------------------------------------------------
	-- Create two temporary tables
 	---------------------------------------------------
 	--
	CREATE TABLE #Tmp_Jobs (
		Job int not null,
		UpdateRequired tinyint not null,
		Invalid tinyint not null,
		[Comment] varchar(512) null
	)

	CREATE TABLE #Tmp_JobStepsToUpdate (
		Job int not null,
		Step int not null
	)
	
	---------------------------------------------------
	-- Populate a temporary table with jobs to process
 	---------------------------------------------------
 	--
	INSERT INTO #Tmp_Jobs (Job, UpdateRequired, Invalid)
	SELECT Value as Job, 0, 0
	FROM dbo.udfParseDelimitedIntegerList(@jobList, ',')
	
	If Not Exists (SELECT * FROM #Tmp_Jobs)
	Begin
		Set @message = 'No valid jobs were found: ' + @jobList
		Goto Done
	End
	
	---------------------------------------------------
	-- Find job steps that need to be updated
	---------------------------------------------------
	--
	INSERT INTO #Tmp_JobStepsToUpdate( Job, Step )
	SELECT JS.Job, JS.Step
	FROM #Tmp_Jobs
	     INNER JOIN V_Job_Steps JS
	       ON #Tmp_Jobs.Job = JS.Job
	     INNER JOIN ( SELECT Job, Step, Start, Input_Folder
	                  FROM V_Job_Steps
	                  WHERE (Tool = 'Results_Transfer') 
	                ) FilterQ
	       ON JS.Job = FilterQ.Job AND
	          JS.Output_Folder = FilterQ.Input_Folder AND
	          JS.Finish > FilterQ.Start AND
	          JS.Step < FilterQ.Step
	WHERE JS.Tool <> 'Results_Transfer'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	UPDATE #Tmp_Jobs
	SET UpdateRequired = 1
	WHERE Job IN ( SELECT DISTINCT Job
	               FROM #Tmp_JobStepsToUpdate )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Look for jobs with UpdateRequired = 0
	---------------------------------------------------
	--
	UPDATE #Tmp_Jobs
	SET [Comment] = 'Nothing to update; no job steps were completed after their corresponding Results_Transfer step'
	WHERE UpdateRequired = 0
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Look for jobs where the Results_Transfer steps do not match T_Job_Steps_History
	---------------------------------------------------
	--
	UPDATE #Tmp_Jobs
	SET [Comment] = 'Results_Transfer step in T_Job_Steps has a different Start/Finish value vs. T_Job_Steps_History; ' + 
	       'Step ' + Cast(InvalidQ.Step AS varchar(9)) + '; ' + 
	       'Start ' +   Convert(varchar(34), InvalidQ.Start, 120) +  ' vs. ' + Convert(varchar(34), InvalidQ.Finish, 120) + '; ' + 
	       'Finish ' +  Convert(varchar(34), InvalidQ.Finish, 120) + ' vs. ' + Convert(varchar(34), InvalidQ.Finish_History, 120),
	    Invalid = 1
	FROM #Tmp_Jobs
	     INNER JOIN (  SELECT JS.Job,
	                         JS.Step_Number AS Step,
	                         JS.Start, JS.Finish,
	                         JSH.Start AS Start_History,
	                         JSH.Finish AS Finish_History
	                  FROM T_Job_Steps JS
	                       INNER JOIN T_Job_Steps_History JSH
	                         ON JS.Job = JSH.Job AND
	                            JS.Step_Number = JSH.Step_Number AND
	                            JSH.Most_Recent_Entry = 1
	                  WHERE JS.Job IN (Select DISTINCT Job FROM #Tmp_JobStepsToUpdate) AND 
	                        JS.Step_Tool = 'Results_Transfer' AND
	                        (JSH.Start <> JS.Start OR JSH.Finish <> JS.Finish) 
	               ) InvalidQ
	       ON #Tmp_Jobs.Job = InvalidQ.Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @infoOnly > 0
	Begin
		UPDATE #Tmp_Jobs
		SET [Comment] = 'Metadata would be updated'
		FROM #Tmp_Jobs J
			INNER JOIN #Tmp_JobStepsToUpdate JSU
			ON J.Job = JSU.Job
		WHERE J.Invalid = 0
	End
		
	If @infoOnly = 0 And Exists (SELECT * FROM  #Tmp_Jobs J INNER JOIN #Tmp_JobStepsToUpdate JSU ON J.Job = JSU.Job WHERE J.Invalid = 0)
	Begin -- <a>
		
		---------------------------------------------------
		-- Update metadata for the job steps in #Tmp_JobStepsToUpdate,
		-- filtering out any jobs with Invalid = 1
		---------------------------------------------------
		--		
		UPDATE T_Job_Steps
		SET Start = JSH.Start,
		    Finish = JSH.Finish,
		    Processor = JSH.Processor,
		    Completion_Code = JSH.Completion_Code,
		    Completion_Message = JSH.Completion_Message,
		    Evaluation_Code = JSH.Evaluation_Code,
		    Evaluation_Message = JSH.Evaluation_Message,
		    Tool_Version_ID = JSH.Tool_Version_ID,
		    Remote_Info_ID = JSH.Remote_Info_ID
		FROM #Tmp_Jobs J
		     INNER JOIN #Tmp_JobStepsToUpdate JSU
		       ON J.Job = JSU.Job
		     INNER JOIN T_Job_Steps JS
		       ON JS.Job = JSU.Job AND
		          JSU.Step = JS.Step_Number
		     INNER JOIN T_Job_Steps_History JSH
		       ON JS.Job = JSH.Job AND
		          JS.Step_Number = JSH.Step_Number AND
		          JSH.Most_Recent_Entry = 1
		WHERE J.Invalid = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
		Begin
			Set @message = 'No job steps were updated; this indicates a bug.  Examine the temp table contents'
			
			SELECT '#Tmp_Jobs' AS TheTable, * FROM #Tmp_Jobs
			
			SELECT '#Tmp_JobStepsToUpdate' AS TheTable, * FROM #Tmp_JobStepsToUpdate
		End
		
		If @myRowCount = 1
		Begin
			SELECT @job = JSU.Job,
				@jobStep = JSU.Step
			FROM #Tmp_Jobs J
				INNER JOIN #Tmp_JobStepsToUpdate JSU
				ON J.Job = JSU.Job
			WHERE J.Invalid = 0
			
			Set @message = 'Updated step ' + Cast(@jobStep as varchar(9)) + ' for job ' + CAST (@job as varchar(9)) + ' in T_Job_Steps, copying metadata from T_Job_Steps_History'
		End
		
		If @myRowCount > 1
		Begin
			Set @message = 'Updated ' + Cast(@myRowCount as varchar(9)) + ' job steps in T_Job_Steps, copying metadata from T_Job_Steps_History'
		End

		UPDATE #Tmp_Jobs
		SET [Comment] = 'Metadata updated'
		FROM #Tmp_Jobs J
			INNER JOIN #Tmp_JobStepsToUpdate JSU
			ON J.Job = JSU.Job
		WHERE J.Invalid = 0

	End -- </a>

	---------------------------------------------------
	-- Show job steps that were updated, or would be updated, or that cannot be updated
	---------------------------------------------------
	--
	SELECT J.Job,
		   J.UpdateRequired,
		   J.Invalid,
		   J.[Comment],
		   JS.Dataset,
		   JS.Step, JS.Tool,
		   JS.StateName, JS.State,
		   JS.Start, JS.Finish,
		   JS.Input_Folder, JS.Output_Folder,
		   JS.Processor,
		   JS.Tool_Version_ID, JS.Tool_Version,
		   JS.Completion_Code, JS.Completion_Message,
		   JS.Evaluation_Code, JS.Evaluation_Message
	FROM #Tmp_JobStepsToUpdate JSU
	     INNER JOIN V_Job_Steps JS
	       ON JSU.Job = JS.Job AND
	          JSU.Step = JS.Step
	     RIGHT OUTER JOIN #Tmp_Jobs J
	       ON J.Job = JSU.Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	If @message <> ''
		SELECT @message as Message
		
	return @myError

GO
