/****** Object:  StoredProcedure [dbo].[SetStepTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetStepTaskComplete
/****************************************************
**
**	Desc: 
**		Mark job step as complete
**		Also updates CPU and Memory info tracked by T_Machines
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**			05/07/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			06/17/2008 dac - Added default values for completionMessage, evaluationCode, and evaluationMessage
**			10/05/2009 mem - Now allowing for CPU_Load to be null in T_Job_Steps
**			10/17/2011 mem - Added column Memory_Usage_MB
**			09/25/2012 mem - Expanded @organismDBName to varchar(128)
**			09/09/2014 mem - Added support for completion code 16 (CLOSEOUT_FILE_NOT_IN_CACHE)
**			09/12/2014 mem - Added PBF_Gen as a valid tool for completion code 16
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**			               - Now looking up machine using T_Local_Processors
**			10/30/2014 mem - Added support for completion code 17 (CLOSEOUT_UNABLE_TO_USE_MZ_REFINERY)
**			03/11/2015 mem - Now updating Completion_Message when completion code 16 or 17 is encountered more than once in a 24 hour period
**			04/17/2015 mem - Now using Uses_All_Cores for determining the number of cores to add back to CPUs_Available 
**			11/18/2015 mem - Add Actual_CPU_Load
**			12/31/2015 mem - Added support for completion code 20 (CLOSEOUT_NO_DATA)
**			01/05/2016 mem - Tweak warning message for DeconTools results without data
**			06/17/2016 mem - Add missing space in log message
**			06/20/2016 mem - Include the completion code description in logged messages
**			12/02/2016 mem - Lookup step tools with shared results in T_Step_Tools when initializing @SharedResultStep
**
*****************************************************/
(
    @job int,
    @step int,
    @completionCode int,
    @completionMessage varchar(256) = '',
    @evaluationCode int = 0,
    @evaluationMessage varchar(256) = '',
	@organismDBName varchar(128) = ''
)
As
	Set nocount on
	
	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0
	
	Declare @message varchar(512)
	Set @message = ''
	
	---------------------------------------------------
	-- get current state of this job step
	---------------------------------------------------
	--
	Declare @processor varchar(64)
	Declare @state tinyint
	Declare @cpuLoad smallint
	Declare @MemoryUsageMB int
	Declare @machine varchar(64)
	Declare @stepTool varchar(64)
	--
	Set @processor = ''
	Set @state = 0
	Set @cpuLoad = 0
	Set @MemoryUsageMB = 0
	Set @machine = ''
	--
	SELECT @machine = LP.Machine,
	       @cpuLoad = CASE WHEN Tools.Uses_All_Cores > 0 AND JS.Actual_CPU_Load = JS.CPU_Load
						   THEN IsNull(M.Total_CPUs, 1)
						   ELSE IsNull(JS.Actual_CPU_Load, 1)
					  END,
	       @MemoryUsageMB = IsNull(JS.Memory_Usage_MB, 0),
	       @state = JS.State,
	       @processor = JS.Processor,
	       @stepTool = JS.Step_Tool
	FROM T_Job_Steps JS
	     INNER JOIN T_Local_Processors LP
	       ON LP.Processor_Name = JS.Processor
	     INNER JOIN T_Step_Tools Tools
	       ON Tools.Name = JS.Step_Tool
	     LEFT OUTER JOIN T_Machines M
	       ON LP.Machine = M.Machine
	WHERE JS.Job = @job AND
	      JS.Step_Number = @step
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		Set @message = 'Error getting machine name from T_Local_Processors using T_Job_Steps'
		Goto Done
	End
	--
	If IsNull(@machine, '') = ''
	Begin
		Set @myError = 66
		Set @message = 'Could not find machine name in T_Local_Processors using T_Job_Steps'
		Goto Done
	End
	--
	If @state <> 4
	Begin
		Set @myError = 67
		Set @message = 'Job step is not in correct state (4) to be completed'
		Goto Done
	End

	---------------------------------------------------
	-- Determine completion state
	---------------------------------------------------
	--
	Declare @stepState int
	Declare @resetSharedResultStep tinyint = 0
	Declare @handleSkippedStep tinyint = 0
	Declare @skipLCMSFeatureFinder tinyint = 0
	Declare @completionCodeDescription varchar(64) = 'Unknown completion reason'
	
	If @completionCode = 0
	Begin
		Set @stepState = 5 -- success
		Set @completionCodeDescription = 'Success'
	End
	Else
	Begin
		Set @stepState = 0
		
		If @completionCode = 16  -- CLOSEOUT_FILE_NOT_IN_CACHE
		Begin
			Set @stepState = 1 -- waiting
			Set @resetSharedResultStep = 1
			Set @completionCodeDescription = 'File not in cache'
		End
		
		If @completionCode = 17  -- CLOSEOUT_UNABLE_TO_USE_MZ_REFINERY
		Begin
			Set @stepState = 3 -- skipped
			Set @handleSkippedStep = 1
			Set @completionCodeDescription = 'Unable to use MZ_Refinery'
		End

		If @completionCode = 20  -- CLOSEOUT_NO_DATA
		Begin
			Set @completionCodeDescription = 'No Data'
			If @stepTool IN ('Decon2LS_V2')
			Begin
				-- Treat "No_data" results for DeconTools as a completed job step but skip the next step if it is LCMSFeatureFinder
				Set @stepState = 5 -- Complete
				Set @skipLCMSFeatureFinder = 1
				
				Set @message = 'Warning, job ' + Cast(@job as varchar(12)) + ' has no results in the DeconTools _isos.csv file; either it is a bad dataset or analysis parameters are incorrect'				
				Exec PostLogEntry 'Error', @message, 'SetStepTaskComplete'
			End
		End
		
		If @stepState = 0
		Begin
			Set @stepState = 6 -- fail
			Set @completionCodeDescription = 'General error'
		End
	End
	
	---------------------------------------------------
	-- Set up transaction parameters
	---------------------------------------------------
	--
	Declare @transName varchar(32)
	Set @transName = 'SetStepTaskComplete'
		
	-- Start transaction
	Begin transaction @transName

	---------------------------------------------------
	-- Update job step
	---------------------------------------------------
	--
	UPDATE T_Job_Steps
	Set    State = @stepState,
		   Finish = Getdate(),
		   Completion_Code = @completionCode,
		   Completion_Message = @completionMessage,
		   Evaluation_Code = @evaluationCode,
		   Evaluation_Message = @evaluationMessage
	WHERE Job = @job AND 
	      Step_Number = @step
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		rollback transaction @transName
		Set @message = 'Error updating step table'
		Goto Done
	End
	
	---------------------------------------------------
	-- Update machine loading for this job step's processor's machine
	---------------------------------------------------
	--
	UPDATE T_Machines
	Set CPUs_Available = CPUs_Available + @cpuLoad,
	    Memory_Available = Memory_Available + @MemoryUsageMB
	WHERE (Machine = @machine)

 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	If @myError <> 0
	Begin
		rollback transaction @transName
		Set @message = 'Error updating CPU loading'
		Goto Done
	End

	If @resetSharedResultStep <> 0
	Begin
		-- Reset the the DTA_Gen, DTA_Refinery, Mz_Refinery, MSXML_Gen, MSXML_Bruker, or PBF_Gen, ProMex step just upstream from this step
		
		Declare @SharedResultStep int = -1
		
		SELECT TOP 1 @SharedResultStep = Step_Number
		FROM T_Job_Steps
		WHERE Job = @job AND
		      Step_Number < @step AND
		      Step_Tool IN (SELECT [Name] FROM T_Step_Tools WHERE Shared_Result_Version > 0)
		ORDER BY Step_Number DESC

		If IsNull(@SharedResultStep, -1) < 0
		Begin
			Set @message = 'Job ' + Cast(@job as varchar(12)) + 
			               ' does not have a Mz_Refinery, MSXML_Gen, MSXML_Bruker, PBF_Gen, or ProMex step prior to step ' + Cast(@step as varchar(12)) + 
			               '; CompletionCode ' + Cast(@completionCode as varchar(12)) + ' (' + @completionCodeDescription + ') is invalid'

			Exec PostLogEntry 'Error', @message, 'SetStepTaskComplete'
			Goto CommitTran
		End
	
		Set @message = 'Re-running step ' + Cast(@SharedResultStep as varchar(12)) + ' for job ' + Cast(@job as varchar(12)) + 
		               ' because step ' + Cast(@step as varchar(12)) + 
		               ' reported completion code ' + Cast(@completionCode as varchar(12)) + ' (' + @completionCodeDescription + ')'
		               
		If Exists ( SELECT *
			        FROM T_Log_Entries
			        WHERE Message = @message And
			              type = 'Normal' And
			              posting_Time >= DateAdd(day, -1, GetDate()) 
			      )
		Begin
			Set @message = 'has already reported completion code ' + Cast(@completionCode as varchar(12)) + ' (' + @completionCodeDescription + ')' + 
			               ' within the last 24 hours'
			
			UPDATE T_Job_Steps
			SET State = 7,		-- Holding				
			    Completion_Message = dbo.AppendToText(Completion_Message, @message, 0, '; ')
			WHERE Job = @job AND
			      Step_Number = @step
			
			Set @message = 'Step ' + Cast(@step as varchar(12)) + ' in job ' + Cast(@job as varchar(12)) + ' ' + 
			               @message + '; will not reset step ' + Cast(@SharedResultStep as varchar(12)) + 
			               ' again because this likely represents a problem; this step is now in state "holding"'

			Exec PostLogEntry 'Error', @message, 'SetStepTaskComplete'
			
			Goto CommitTran
		End

		Exec PostLogEntry 'Normal', @message, 'SetStepTaskComplete'

		UPDATE T_Job_Steps
		Set State = 2,					-- 2=Enabled
			Tool_Version_ID = 1			-- 1=Unknown
		WHERE Job = @job AND 
			  Step_Number = @SharedResultStep And
			  State <> 4                -- Do not reset the step if it is already running

		UPDATE T_Job_Step_Dependencies
		SET Evaluated = 0,
			Triggered = 0
		WHERE Job = @job AND
			  Step_Number = @step

		UPDATE T_Job_Step_Dependencies
		SET Evaluated = 0,
			Triggered = 0
		WHERE Job = @job AND
			  Target_Step_Number = @SharedResultStep
			  
	End

	If @handleSkippedStep <> 0
	Begin
		-- This step was skipped
		-- Update T_Job_Step_Dependencies and T_Job_Steps
		
		Declare @newTargetStep int = -1
		Declare @nextStep int = -1
		
		SELECT @newTargetStep = Target_Step_Number
		FROM T_Job_Step_Dependencies
		WHERE Job = @job AND
		      Step_Number = @step

		SELECT @nextStep = Step_Number
		FROM T_Job_Step_Dependencies
		WHERE Job = @job AND
		      Target_Step_Number = @step AND
		      ISNULL(Condition_Test, '') <> 'Target_Skipped'

		If @newTargetStep > -1 And @newTargetStep > -1
		Begin
			UPDATE T_Job_Step_Dependencies
			SET Target_Step_Number = @newTargetStep
			WHERE Job = @job AND Step_Number = @nextStep
			
			set @message = 'Updated job step dependencies for job ' + Cast(@job as varchar(9)) + ' since step ' + Cast(@step as varchar(9)) + ' has been skipped'
			exec PostLogEntry 'Normal', @message, 'SetStepTaskComplete'
		End
		
	End
	
	If @skipLCMSFeatureFinder = 1
	Begin
		-- Skip any LCMSFeatureFinder for this job
		UPDATE T_Job_Steps
		SET State = 3
		WHERE Job = @job AND
		      Step_Tool = 'LCMSFeatureFinder'

	End
	
CommitTran:
	
	-- update was successful
	commit transaction @transName

	---------------------------------------------------
	-- Update fasta file name (If one passed in from the analysis tool manager)
	---------------------------------------------------
	--
	If IsNull(@organismDBName,'') <> ''
	Begin
		UPDATE T_Jobs
		Set Organism_DB_Name = @organismDBName
		WHERE Job = @job	
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			Set @message = 'Error updating organism DB name'
			Goto Done
		End
	End
		
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SetStepTaskComplete] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetStepTaskComplete] TO [svc-dms] AS [dbo]
GO
