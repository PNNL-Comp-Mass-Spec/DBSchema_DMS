/****** Object:  StoredProcedure [dbo].[UpdateDependentSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDependentSteps
/****************************************************
**
**	Desc: 
**    Examine all dependencies for steps in "Waiting" state
**    and update the state of steps for which all dependencies
**    have been satisfied
**
**    The updated state can be affected by conditions on
**    conditional dependencies and by whether or not the
**    step tool produces shared results
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**			05/06/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			01/09/2009 mem - Optimized performance by switching to a temp table with an indexed column 
**							 that specifies the order to process the job steps (http://prismtrac.pnl.gov/trac/ticket/713)
**			01/30/2009 grk - Modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**			03/18/2009 mem - Now checking T_Job_Steps_History for completed shared result steps if no match is found in T_Job_Steps
**			06/01/2009 mem - Added parameter @MaxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**			06/03/2009 mem - Added parameter @LoopingUpdateInterval
**			10/30/2009 grk - Modified skip logic to not pass through folder for DTARefinery tool (temporary ugly hack)
**			02/15/2010 mem - added some additional debug statements to be shown when @infoOnly is non-zero
**			07/01/2010 mem - Updated DTARefinery skip logic to name the tool DTA_Refinery
**			05/25/2011 mem - Now using the Priority column from T_Jobs
**			12/20/2011 mem - Now updating T_Job_Steps.Dependencies if the dependency count listed is lower than that defined in T_Job_Step_Dependencies 
**			09/17/2014 mem - Updated output_folder_name logic to recognize tool Mz_Refinery
**    
*****************************************************/
(
	@message varchar(512) = '' output,
	@numStepsSkipped int = 0 output,
	@infoOnly tinyint = 0,
	@MaxJobsToProcess int = 0,
	@LoopingUpdateInterval int = 5		-- Seconds between detailed logging while looping through the dependencies
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	set @numStepsSkipped = 0
	set @infoOnly = IsNull(@infoOnly, 0)
	
	declare @newState tinyint
	--
	declare @Job int
	declare @Step int
	declare @Tool varchar(64)
	declare @Total int
	declare @Evaluated int
	declare @Triggered int
	declare @Shared int
	declare @Signature int
	--
	declare @done int
	declare @ProcessingOrder int
	
	declare @Dataset varchar(128)
	declare @DatasetID int
	declare @outputFolderName varchar(128)

	declare @CandidateStepCount int
	declare @numStepsUpdated int
	set @numStepsUpdated = 0

	declare @numCompleted int
	declare @numPending int
	
	declare @StartTime datetime
	declare @LastLogTime datetime
	declare @StatusMessage varchar(512)	

	Declare @RowCountToProcess int
	Declare @RowsProcessed int
	
	Declare @msg varchar(128)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	set @message = ''
	Set @MaxJobsToProcess = IsNull(@MaxJobsToProcess, 0)

	Set @StartTime = GetDate()
	Set @LoopingUpdateInterval = IsNull(@LoopingUpdateInterval, 5)
	If @LoopingUpdateInterval < 2
		Set @LoopingUpdateInterval = 2
	
	---------------------------------------------------
	-- Temp table to hold scratch list of step dependencies
	---------------------------------------------------
	CREATE TABLE #T_Tmp_Steplist (
		Job int,
		Step int,
		Tool varchar(64),
		Priority int,								-- Holds Job priority
		Total int,
		Evaluated int,
		Triggered int,
		Shared int,
		Signature int,
		EntryID int identity(1,1) NOT NULL,
		Output_Folder_Name varchar(128) NULL,
		ProcessingOrder int NULL					-- We will populate this column after the #T_Tmp_Steplist table gets populated
	)

	CREATE INDEX [IX_StepList_ProcessingOrder] ON #T_Tmp_Steplist (ProcessingOrder, Job)
	
	---------------------------------------------------
	-- Bump up the value for Dependencies in T_Job_Steps if it is too low
	-- This will happen if new rows are manually added to T_Job_Step_Dependencies
	---------------------------------------------------
	--
	UPDATE T_Job_Steps
	SET Dependencies = CompareQ.Actual_Dependencies
	FROM T_Job_Steps JS
	     INNER JOIN ( SELECT Job_ID,
	                         Step_Number,
	                         COUNT(*) AS Actual_Dependencies
	                  FROM T_Job_Step_Dependencies
	                  WHERE Job_ID IN ( SELECT Job FROM T_Job_Steps WHERE State = 1 )
	                  GROUP BY Job_ID, Step_Number 
	                ) CompareQ
	       ON JS.Job = CompareQ.Job_ID AND
	          JS.Step_Number = CompareQ.Step_Number AND
	          JS.Dependencies < CompareQ.Actual_Dependencies
	WHERE JS.State = 1
	-- 
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating T_Job_Steps.Dependencies'
		goto Done
	end
	
	---------------------------------------------------
	-- get summary of dependencies for steps 
	-- in "Waiting" state and add to scratch list
	---------------------------------------------------
	--
	INSERT INTO #T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Shared, Signature, Output_Folder_Name)
	SELECT JSD.Job_ID AS Job,
	       JSD.Step_Number AS Step,
	       JS.Step_Tool AS Tool,
	       J.Priority,
	       JS.Dependencies AS Total,
	       SUM(JSD.Evaluated) AS Evaluated,
	       SUM(JSD.Triggered) AS Triggered,
	       JS.Shared_Result_Version AS Shared,
	       JS.Signature AS Signature,
	       JS.Output_Folder_Name
	FROM T_Job_Steps JS
	     INNER JOIN T_Job_Step_Dependencies JSD
	       ON JSD.Job_ID = JS.Job AND
	          JSD.Step_Number = JS.Step_Number
	     INNER JOIN T_Jobs J
	       ON JS.Job = J.Job
	WHERE (JS.State = 1)
	GROUP BY JSD.Job_ID, JSD.Step_Number, JS.Dependencies, 
	         JS.Shared_Result_Version, JS.Signature, 
	         J.Priority, JS.Step_Tool, JS.Output_Folder_Name
	HAVING JS.Dependencies = SUM(JSD.Evaluated)
	-- 
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting step dependencies'
		goto Done
	end
	
	Set @CandidateStepCount = @myRowCount

	---------------------------------------------------
	-- add waiting steps that have no dependencies
	-- to scratch list
	---------------------------------------------------
	--
	INSERT INTO #T_Tmp_Steplist (Job, Step, Tool, Priority, Total, Evaluated, Triggered, Shared, Signature, Output_Folder_Name)
	SELECT JS.Job,
	       JS.Step_Number AS Step,
	       JS.Step_Tool AS Tool,
	       J.Priority,
	       JS.Dependencies AS Total,			-- This will always be zero in this query
	       0 AS Evaluated,
	       0 AS Triggered,
	       JS.Shared_Result_Version AS Shared,
	       JS.Signature AS Signature,
	       JS.Output_Folder_Name
	FROM T_Job_Steps JS
	     INNER JOIN T_Jobs J
	       ON JS.Job = J.Job
	WHERE JS.State = 1 AND
	      JS.Dependencies = 0
	-- 
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting steps without dependencies'
		goto Done
	end

	Set @CandidateStepCount = @CandidateStepCount + @myRowCount
	
	If @CandidateStepCount = 0
		Goto Done					-- Nothing to do; jump to the end
		
	---------------------------------------------------
	-- Populate the ProcessingOrder column in #T_Tmp_Steplist
	-- Sorting by Priority so that shared steps will tend to be enabled for higher priority jobs first
	---------------------------------------------------
	--
	UPDATE #T_Tmp_Steplist
	SET ProcessingOrder = LookupQ.ProcessingOrder
	FROM #T_Tmp_Steplist TargetQ
		INNER JOIN ( SELECT EntryID,
							Row_Number() OVER ( ORDER BY Priority, Job ) AS ProcessingOrder
					FROM #T_Tmp_Steplist ) LookupQ
		ON TargetQ.EntryID = LookupQ.EntryID
	-- 
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	
	If @infoOnly <> 0
		SELECT *
		FROM #T_Tmp_Steplist
		ORDER BY ProcessingOrder

	---------------------------------------------------
	-- Loop through steps in scratch list
	-- check state of their dependencies,
	-- and update their state, as appropriate
	---------------------------------------------------

	SELECT @RowCountToProcess = COUNT(*)
	FROM #T_Tmp_Steplist
	--
	Set @RowCountToProcess = IsNull(@RowCountToProcess, 0)

	set @done = 0
	set @ProcessingOrder = -1
	set @RowsProcessed = 0
	set @LastLogTime = GetDate()
	--
	while @done = 0
	begin --<a>
		---------------------------------------------------
		-- get next step in scratch list
		---------------------------------------------------
		--
		SELECT TOP 1
			@job = Job,
			@Step = Step,
			@Tool = Tool,
			@Total = Total,
			@Evaluated = Evaluated,
			@Triggered = Triggered,
			@Shared = Shared,
			@Signature = Signature,
			@outputFolderName = Output_Folder_Name,
			@ProcessingOrder = ProcessingOrder
		FROM
			#T_Tmp_Steplist
		WHERE ProcessingOrder > @ProcessingOrder
		ORDER BY ProcessingOrder
		-- 
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error getting next step in list'
			goto Done
		end

		---------------------------------------------------
		-- No more rows were returned; we are done
		---------------------------------------------------
		if @myRowCount = 0
			set @done = 1
		else
		---------------------------------------------------
		-- Job step obtained, process it
		---------------------------------------------------
		begin --<b>
			---------------------------------------------------
			-- if all dependencies for the step are evaluated, 
			-- the step's state may be changed
			---------------------------------------------------
			--
			if @Evaluated = @total
			begin --<c>
				--
				---------------------------------------------------
				-- get information from parent job 
				---------------------------------------------------
				--
				SELECT 
					@Dataset = Dataset,
					@DatasetID = Dataset_ID
				FROM T_Jobs
				WHERE Job = @job

				---------------------------------------------------
				-- if any conditional dependencies were triggered, 
				-- new state will be "Skipped"
				-- otherwise, new state will be "Enabled"
				---------------------------------------------------
				--
				if @Triggered = 0
					set @newState = 2 -- "Enabled"
				else
					set @newState = 3 -- "Skipped

				set @numCompleted = 0
				set @numPending = 0

				---------------------------------------------------
				-- if step has shared results, state change may be affected
				---------------------------------------------------
				if @Shared <> 0
				begin --<d>
					--
					-- Any standing shared results that match?
					--
					SELECT 
					  @numCompleted = COUNT(*)
					FROM
						T_Shared_Results
					WHERE
						Results_Name = @outputFolderName
					--
					if @numCompleted = 0
					begin --<h>
						-- how many current matching shared results steps are in which states? 
						--
						SELECT 
							@numCompleted = ISNULL(SUM(CASE WHEN State = 5 THEN 1 ELSE 0 END), 0),
							@numPending   = ISNULL(SUM(CASE WHEN State in (2,4) THEN 1 ELSE 0 END), 0)
						FROM   
							T_Job_Steps
						WHERE 
							Output_Folder_Name = @outputFolderName AND
							NOT Output_Folder_Name IS NULL AND
							State in (2,4,5)
						
						if @numCompleted = 0
						Begin
							-- Also check T_Job_Steps_History for completed, matching shared results steps
							-- Old, completed jobs are removed from T_Jobs after a set number of days, meaning it's possible
							--  that the only record of a completed, matching shared results step will be in T_Job_Steps_History
							SELECT 
								@numCompleted = COUNT(*)
							FROM   
								T_Job_Steps_History
							WHERE 
								Output_Folder_Name = @outputFolderName AND
								NOT Output_Folder_Name IS NULL AND
								State = 5
								
						End
						
						--
						-- if there were any completed shared results not already in 
						-- standing shared results table, make entry in shared results
						--
						if @numCompleted > 0
						begin
							If @infoOnly <> 0
								Print 'Insert "' + @outputFolderName + '" into T_Shared_Results'
							Else
								INSERT INTO T_Shared_Results
									(Results_Name)
								VALUES
									(@outputFolderName)						
						end
					end --<h>

					-- Skip if another step has already created the shared results
					-- Otherwise, continue waiting if another step is making the shared results 
					--  (the other step will either succeed or fail, and then this step's action will be re-evaluated)
					--
					if @numCompleted > 0
						set @newState = 3 -- "Skipped"
					else 
					begin
						if @numPending > 0
							set @newState = 1 -- "Waiting"
					end
					
				end --<d>

				If @infoOnly <> 0
				Begin
					Set @msg = 'Job ' + Convert(varchar(12), @job) + ', step ' + Convert(varchar(12), @Step) + ', @outputFolderName ' + @outputFolderName
					
					Set @msg = @msg + ', @numCompleted ' + Convert(varchar(12), @numCompleted) + ', @numPending ' + Convert(varchar(12), @numPending) + ', @newState ' + Convert(varchar(12), @newState)
					Print @msg
				End
				
				---------------------------------------------------
				-- if step state needs to be changed, update step
				---------------------------------------------------
				--
				if @newState <> 1
				begin --<e>
				
					---------------------------------------------------
					-- update step state and output folder name
					-- (input folder name is passed through if step is skipped, 
					--  unless the tool is DTA_Refinery or Mz_Refinery, then the folder name is
					--  NOT passed through if the tool is skipped)
					---------------------------------------------------
					--
					If @infoOnly <> 0
						Print 'Update State in T_Job_Steps for job ' + Convert(varchar(12), @Job) + ', step ' + convert(varchar(12), @Step) + ' from 1 to ' + Convert(varchar(12), @newState)
					Else
					Begin
						-- This query updates the state to @newState
						-- It may also update Output_Folder_Name; here's the logic:
							-- If the new state is not 3 (skipped), then will leave Output_Folder_Name unchanged
							-- If the new state is 3, then change Output_Folder_Name to be Input_Folder_Name, but only if:
							--  a. the step tool is not DTA_Refinery or Mz_Refinery and 
							--  b. the Input_Folder_Name is not blank (this check is needed when the first step of a job 
							--     is skipped; that step will always have a blank Input_Folder_Name, and we don't want
							--     the Output_Folder_Name to get blank'd out)
						--
						UPDATE T_Job_Steps
						SET State = @newState,
						    Output_Folder_Name = CASE
						                             WHEN (@newState = 3 AND
						                                   ISNULL(Input_Folder_Name, '') <> '' AND
						                                   Step_Tool Not In ('Mz_Refinery', 'DTA_Refinery')) THEN Input_Folder_Name
						                             ELSE Output_Folder_Name
						                         END
						WHERE Job = @Job AND
						      Step_Number = @Step AND
						      State = 1		-- Assure that we only update steps in state 1=waiting
						-- 
						SELECT @myError = @@error, @myRowCount = @@rowcount
						--
						if @myError <> 0
						begin
							set @message = 'Error updating step state'
							goto Done
						end
					End

					Set @numStepsUpdated = @numStepsUpdated + 1
					
					-- bump @numStepsSkipped for each step skipped
					if @newState = 3
						set @numStepsSkipped = @numStepsSkipped + 1
				end --<e>
	
			end --<c>
		
			Set @RowsProcessed = @RowsProcessed + 1
		end --<b>
		
		If DateDiff(second, @LastLogTime, GetDate()) >= @LoopingUpdateInterval
		Begin
			Set @StatusMessage = '... Updating dependent steps: ' + Convert(varchar(12), @RowsProcessed) + ' / ' + Convert(varchar(12), @RowCountToProcess)
			exec PostLogEntry 'Progress', @StatusMessage, 'UpdateDependentSteps'
			Set @LastLogTime = GetDate()
		End

		If @MaxJobsToProcess > 0
		Begin
			SELECT @myRowCount = COUNT(DISTINCT Job)
			FROM #T_Tmp_Steplist
			WHERE ProcessingOrder <= @ProcessingOrder
			
			If IsNull(@myRowCount, 0) >= @MaxJobsToProcess
				Set @done = 1
		End
		
	end --<a>	

	If @infoOnly <> 0
	Begin
		Print 'Steps updated: ' + Convert(varchar(12), @numStepsUpdated)
		Print 'Steps set to state 3 (skipped): ' + Convert(varchar(12), @numStepsSkipped)
	End
		
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	DROP TABLE #T_Tmp_Steplist
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDependentSteps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDependentSteps] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDependentSteps] TO [PNL\D3M580] AS [dbo]
GO
