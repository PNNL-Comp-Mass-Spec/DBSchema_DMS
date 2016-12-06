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
	-- Note:
	--   The following logic for updating Progress and ETA_Minutes
	--   based on Job State is also used in trigger trig_u_AnalysisJob
	-----------------------------------------
	
	-----------------------------------------
	-- Update progress and ETA for failed jobs
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Progress_New = -1,
	    ETA_Minutes = Null
	WHERE State In (5)	
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	
	-----------------------------------------
	-- Update progress and ETA for new jobs, holding jobs, or Special Proc. Waiting jobs
	-----------------------------------------
	--
	UPDATE #Tmp_JobsToUpdate
	SET Progress_New = 0,
	    ETA_Minutes = Null
	WHERE State In (1,8,19)
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
	WHERE State In (4,7,14)
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
	                                SUM(CASE WHEN state IN (3, 5) THEN 1 ELSE 0 END) AS StepsCompleted,
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
	-- Compute the approximate time remaining for the job to finish
	-- We tack on 0.5 minutes for each uncompleted step, to account for the state machine aspect of the DMS_Pipeline database
	-----------------------------------------
	--
    UPDATE #Tmp_JobsToUpdate
    SET ETA_Minutes = StatsQ.Runtime_Predicted_Minutes - StatsQ.CurrentRuntime_Minutes + (Steps - StepsCompleted) * 0.5
    FROM #Tmp_JobsToUpdate Target
         INNER JOIN ( SELECT Job,
                             CurrentRuntime_Minutes,
                             CurrentRuntime_Minutes / (Progress_New / 100.0) AS Runtime_Predicted_Minutes
                      FROM #Tmp_JobsToUpdate
                      WHERE Progress_New > 0 AND
                            CurrentRuntime_Minutes > 0 ) StatsQ
           ON Target.Job = StatsQ.Job
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
