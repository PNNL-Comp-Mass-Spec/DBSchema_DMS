/****** Object:  StoredProcedure [dbo].[UpdateJobProgress] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateJobProgress
/****************************************************
**
**	Desc: 
**		Updates column Progress in table T_Analysis_Job
**		Note that a progress of -1 is used for failed jobs
**		Jobs in state 1=New or 8=Holding will have a progress of 0
**
**		Set @mostRecentDays and @job to zero to update all jobs
**
**	Auth:	mem
**	Date:	09/01/2016 mem - Initial version
**			10/30/2017 mem - Consider long-running job steps when computing Runtime_Predicted_Minutes
**						   - Set progress to 0 for inactive jobs (state 13)
**    
*****************************************************/
(
	@mostRecentDays int = 32,	-- Used to select jobs to update; matches jobs created or changed within the given number of days
	@job int = 0,				-- Specific job number to update; when non-zero, @mostRecentDays is ignored
	@infoOnly tinyint = 0
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @Job = IsNull(@Job, 0)
	Set @mostRecentDays = IsNull(@mostRecentDays, 0)
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	-----------------------------------------
	-- Create some temporary tables
	-----------------------------------------
	
	CREATE TABLE #Tmp_JobsToUpdate (
		Job int not null,
		State int not null,
		Progress_Old real null,
		Progress_New real null,
		Steps int null,
		StepsCompleted int null,
		CurrentRuntime_Minutes real null,
		Runtime_Predicted_Minutes real null,
		ETA_Minutes real null
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_JobsToUpdate_Job ON #Tmp_JobsToUpdate (Job)
	CREATE INDEX #IX_Tmp_JobsToUpdate_State ON #Tmp_JobsToUpdate (State)
	
	-----------------------------------------
	-- Find the jobs to update
	-----------------------------------------

	If IsNull(@job, 0) <> 0
	Begin
		If Not Exists (SELECT * FROM T_Analysis_Job WHERE AJ_JobId = @job)
		Begin
			Print 'Job not found ' + Cast(@job as varchar(12))
			Goto Done
		End
		
		INSERT INTO #Tmp_JobsToUpdate (Job, State, Progress_Old)
		SELECT AJ_JobID, AJ_StateID, Progress
		FROM T_Analysis_Job
		WHERE AJ_JobID = @Job
	End
	Else
	Begin
		If @mostRecentDays <= 0
		Begin
			INSERT INTO #Tmp_JobsToUpdate (Job, State, Progress_Old)
			SELECT AJ_JobID, AJ_StateID, Progress
			FROM T_Analysis_Job
		End
		Else
		Begin
			Declare @DateThreshold datetime = DateAdd(day, -@mostRecentDays, GetDate())
			
			INSERT INTO #Tmp_JobsToUpdate (Job, State, Progress_Old)
			SELECT AJ_JobID, AJ_StateID, Progress
			FROM T_Analysis_Job
			WHERE AJ_Created >= @DateThreshold OR 
			      AJ_Start >= @DateThreshold
		End
	End
	
	-----------------------------------------
	-- Update progress and ETA for failed jobs
	-- This logic is also used by trigger trig_u_AnalysisJob
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Progress_New = -1,
	    ETA_Minutes = Null
	WHERE State = 5
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	-----------------------------------------
	-- Update progress and ETA for new, holding, inactive, or Special Proc. Waiting jobs
	-- This logic is also used by trigger trig_u_AnalysisJob
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Progress_New = 0,
	    ETA_Minutes = Null
	WHERE State In (1, 8, 13, 19)
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	-----------------------------------------
	-- Update progress and ETA for completed jobs
	-- This logic is also used by trigger trig_u_AnalysisJob
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Progress_New = 100,
	    ETA_Minutes = 0
	WHERE State In (4, 7, 14)
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	
	-----------------------------------------
	-- Determine the incremental progress for running jobs
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Progress_New = Source.Progress_Overall,
	    Steps = Source.Steps,
	    StepsCompleted = Source.StepsCompleted,
	    CurrentRuntime_Minutes = Source.TotalRuntime_Minutes
	FROM #Tmp_JobsToUpdate Target
	     INNER JOIN ( SELECT ProgressQ.Job,
	                         ProgressQ.Steps,
	                         ProgressQ.StepsCompleted,
	                         ProgressQ.WeightedProgressSum / WeightSumQ.WeightSum AS Progress_Overall,
	                         ProgressQ.TotalRuntime_Minutes
	                  FROM ( SELECT JS.Job,
	                                COUNT(*) AS Steps,
	                                SUM(CASE WHEN JS.State IN (3, 5) THEN 1 ELSE 0 END) AS StepsCompleted,
	                                SUM(CASE WHEN JS.State = 3 THEN 0 
	                                         ELSE JS.Job_Progress * Tools.AvgRuntime_Minutes 
	                                    END) AS WeightedProgressSum,
	                                SUM(RunTime_Minutes) AS TotalRuntime_Minutes
	                         FROM S_V_Pipeline_Job_Steps JS
	                              INNER JOIN S_T_Pipeline_Step_Tools Tools
	                                ON JS.Tool = Tools.Name
	                              INNER JOIN ( SELECT Job 
	                                           FROM #Tmp_JobsToUpdate 
	                                           WHERE State = 2
	                                         ) JTU ON JS.Job = JTU.Job
	                         GROUP BY JS.Job 
	                       ) ProgressQ
	                       INNER JOIN ( SELECT JS.Job,
	                                           SUM(Tools.AvgRuntime_Minutes) AS WeightSum
	                                    FROM S_V_Pipeline_Job_Steps JS
	                                         INNER JOIN S_T_Pipeline_Step_Tools Tools
	                                           ON JS.Tool = Tools.Name
	                                         INNER JOIN ( SELECT Job 
	                                                      FROM #Tmp_JobsToUpdate 
	                                                      WHERE State = 2
	                                                    ) JTU ON JS.Job = JTU.Job
	                                    WHERE JS.State <> 3
	                                    GROUP BY JS.Job 
	                                  ) WeightSumQ
	                         ON ProgressQ.Job = WeightSumQ.Job AND
	                            WeightSumQ.WeightSum > 0 
	                       ) Source
	       ON Source.Job = Target.Job
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error

	-----------------------------------------
	-- Compute Runtime_Predicted_Minutes
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Runtime_Predicted_Minutes = CurrentRuntime_Minutes / (Progress_New / 100.0)
	WHERE Progress_New > 0 AND
	      CurrentRuntime_Minutes > 0
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error


	-----------------------------------------
	-- Look for jobs with an active job step that has been running for over 30 minutes
	-- and has a longer Runtime_Predicted_Minutes value than the one estimated using all of the job steps
	--
	-- The estimated value was computed by weighting on AvgRuntime_Minutes, but if a single step
	-- is taking a long time, there is no way the overall job will finish earlier than that step will finish;
	--
	-- If this is the case, we update Runtime_Predicted_Minutes to match the predicted runtime of that job step
	-- and compute a new overall job progress
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Runtime_Predicted_Minutes = RunningStepsQ.RunTime_Predicted_Minutes,
	    Progress_New = CASE WHEN RunningStepsQ.Runtime_Predicted_Minutes > 0 
	                        THEN CurrentRuntime_Minutes * 100.0 / RunningStepsQ.Runtime_Predicted_Minutes
	                        ELSE Progress_New
	                   END
	FROM #Tmp_JobsToUpdate Target
	     INNER JOIN ( SELECT JS.Job,
	                         Max(JS.RunTime_Predicted_Hours * 60) AS RunTime_Predicted_Minutes
	                  FROM S_V_Pipeline_Job_Steps JS
	                       INNER JOIN ( SELECT Job
	                                    FROM #Tmp_JobsToUpdate
	                                    WHERE State = 2 ) JTU
	                         ON JS.Job = JTU.Job
	                  WHERE JS.RunTime_Minutes > 30 AND
	                        JS.State IN (4, 9)		-- Running or Running_Remote
	                  GROUP BY JS.Job 
	                ) RunningStepsQ
	       ON Target.Job = RunningStepsQ.Job
	WHERE RunningStepsQ.RunTime_Predicted_Minutes > Target.Runtime_Predicted_Minutes
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error


	-----------------------------------------
	-- Compute the approximate time remaining for the job to finish
	-- We tack on 0.5 minutes for each uncompleted step, to account for the state machine aspect of the DMS_Pipeline database
	-----------------------------------------
	--
    UPDATE #Tmp_JobsToUpdate
    SET ETA_Minutes = Runtime_Predicted_Minutes - CurrentRuntime_Minutes + (Steps - StepsCompleted) * 0.5
    FROM #Tmp_JobsToUpdate Target
    WHERE Progress_New > 0
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error


	If @infoOnly <> 0
	Begin
		-----------------------------------------
		-- Preview updated progress
		-----------------------------------------
		
		If @infoOnly = 1
		Begin
			-- Summarize the changes
			--
			SELECT State,
			       Count(*) AS Jobs,
			       Sum(CASE
			               WHEN IsNull(Progress_Old, -10) <> IsNull(Progress_New, -5) THEN 1
			               ELSE 0
			           END) AS Changed_Jobs,
			       Min(Progress_New) AS Min_NewProgress,
			       Max(Progress_New) AS Max_NewProgress
			FROM #Tmp_JobsToUpdate
			GROUP BY State
			ORDER BY State
		End
		Else
		Begin
			-- Show all rows in #Tmp_JobsToUpdate
			--
			SELECT *,
			       CASE
			           WHEN IsNull(Progress_Old, 0) <> IsNull(Progress_New, 0) THEN 1
			           ELSE 0
			       END AS Progress_Changed
			FROM #Tmp_JobsToUpdate
			ORDER BY Job

		End
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	End
	Else
	Begin
		-----------------------------------------
		-- Update the progress
		-----------------------------------------
		--		
		UPDATE T_Analysis_Job
		SET Progress = Src.Progress_New,
		    ETA_Minutes = Src.ETA_Minutes
		FROM T_Analysis_Job Target
		     INNER JOIN #Tmp_JobsToUpdate Src
		       ON Target.AJ_JobID = Src.Job
		WHERE Target.Progress IS NULL AND NOT Src.Progress_New IS NULL OR
		      IsNull(Target.Progress, 0) <> IsNull(Src.Progress_New, 0) OR
		      Target.AJ_StateID IN (4,7,14) AND (Target.Progress IS NULL Or Target.ETA_Minutes IS NULL)
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		-- If @myRowCount > 0
		-- 	 Print 'Updated progress for ' + Cast(@myRowCount as varchar(12)) + ' jobs'

	End

	
Done:

	Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobProgress] TO [DDL_Viewer] AS [dbo]
GO
