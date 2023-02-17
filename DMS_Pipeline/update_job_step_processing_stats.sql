/****** Object:  StoredProcedure [dbo].[UpdateJobStepProcessingStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateJobStepProcessingStats]
/****************************************************
**
**  Desc: 
**		Appends new entries to T_Job_Step_Processing_Stats,
**		showing details of running job steps
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters: 
**
**  Auth:   mem
**          11/23/2015 mem - initial release
**          02/06/2023 bcg - Update after view column rename
**    
*****************************************************/
(
	@MinimumTimeIntervalMinutes integer = 4,						-- Set this to 0 to force the addition of new data to T_Job_Step_Processing_Stats
	@MinimumTimeIntervalMinutesForIdenticalStats integer = 60,		-- This controls how often identical stats will get added to T_Job_Step_Processing_Stats
	@message varchar(128) = '' OUTPUT,
	@InfoOnly tinyint = 0
)
AS
	Set NoCount On

	declare @myRowCount int
	declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	declare @TimeIntervalLastUpdateMinutes real
	declare @TimeIntervalIdenticalStatsMinutes real
	Set @TimeIntervalLastUpdateMinutes = 0
	Set @TimeIntervalIdenticalStatsMinutes = 0
	
	Declare @MostRecentPostingTime smalldatetime
	Declare @UpdateTable tinyint = 1
	
	CREATE TABLE #TmpJobStepProcessingStats (
		Job int NOT NULL,
		Step int NOT NULL,
		Processor varchar(128) NULL,
		RunTime_Minutes decimal(9, 1) NULL,
		Job_Progress real NULL,
		RunTime_Predicted_Hours decimal(9, 2) NULL,
		ProgRunner_CoreUsage real NULL,
		CPU_Load tinyint NULL,
		Actual_CPU_Load tinyint
	)
	
	
	-----------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------
	
	Set @message = ''
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	
	Set @MostRecentPostingTime = Null
	
	-----------------------------------------------------
	-- Lookup the most recent posting time
	-----------------------------------------------------
	--
	SELECT @MostRecentPostingTime = MAX(Entered)
	FROM T_Job_Step_Processing_Stats
	--
	SELECT @myError = @@error, @myRowCount = @@RowCount
	
	If IsNull(@MinimumTimeIntervalMinutes, 0) = 0 Or @MostRecentPostingTime Is Null
		Set @UpdateTable = 1
	Else
	Begin
		Set @TimeIntervalLastUpdateMinutes = DateDiff(second, @MostRecentPostingTime, GetDate()) / 60.0
		
		If @TimeIntervalLastUpdateMinutes >= @MinimumTimeIntervalMinutes
			Set @UpdateTable = 1
		else
			Set @UpdateTable = 0
	End
	
	If @UpdateTable = 1 Or @InfoOnly <> 0
	Begin
		-----------------------------------------------------
		-- Cache the new stats
		-----------------------------------------------------
		--
		INSERT INTO #TmpJobStepProcessingStats( Job,
		                                        Step,
		                                        Processor,
		                                        RunTime_Minutes,
		                                        Job_Progress,
		                                        RunTime_Predicted_Hours,
		                                        ProgRunner_CoreUsage,
		                                        CPU_Load,
		                                        Actual_CPU_Load )
		SELECT Job,
		       Step,
		       Processor,
		       RunTime_Minutes,
		       Job_Progress,
		       RunTime_Predicted_Hours,
		       Prog_Runner_Core_Usage AS ProgRunner_CoreUsage,
		       CPU_Load,
		       Actual_CPU_Load
		FROM V_Job_Steps
		WHERE (State = 4)
		--
		SELECT @myError = @@error, @myRowCount = @@RowCount
		
		If @InfoOnly <> 0
		Begin
			SELECT *
			FROM #TmpJobStepProcessingStats
			ORDER BY Job, Step
		End
		Else				
		Begin
			INSERT INTO T_Job_Step_Processing_Stats( Entered,
			                                         Job,
			                                         Step,
			                                         Processor,
			                                         RunTime_Minutes,
			                                         Job_Progress,
			                                         RunTime_Predicted_Hours,
			                                         ProgRunner_CoreUsage,
			                          CPU_Load,
			                                         Actual_CPU_Load )
			SELECT CAST(GETDATE() AS smalldatetime) Entered,
			       Job,
			       Step,
			       Processor,
			       RunTime_Minutes,
			       Job_Progress,
			       RunTime_Predicted_Hours,
			       ProgRunner_CoreUsage,
			       CPU_Load,
			       Actual_CPU_Load
			FROM #TmpJobStepProcessingStats
			--
			SELECT @myError = @@error, @myRowCount = @@RowCount
			
			Set @message = 'Appended ' + convert(varchar(9), @myRowCount) + ' rows to the Job Step Processing Stats table'
		End

	End
	Else
	Begin
		Set @message = 'Update skipped since last update was ' + convert(varchar(9), Round(@TimeIntervalLastUpdateMinutes, 1)) + ' minutes ago'
	End
	
Done:

	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobStepProcessingStats] TO [DDL_Viewer] AS [dbo]
GO
