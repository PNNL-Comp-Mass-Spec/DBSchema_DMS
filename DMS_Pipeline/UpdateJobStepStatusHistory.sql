/****** Object:  StoredProcedure [dbo].[UpdateJobStepStatusHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateJobStepStatusHistory
/****************************************************
**
**	Desc: 
**		Appends new entries to T_Job_Step_Status_History,
**		summarizing the number of job steps in each state
**      in T_Job_Steps
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: mem
**		Date: 12/05/2008
**    
*****************************************************/
(
	@MinimumTimeIntervalMinutes integer = 60,						-- Set this to 0 to force the addition of new data to T_Job_Step_Status_History
	@MinimumTimeIntervalMinutesForIdenticalStats integer = 355,		-- This controls how often identical stats will get added to T_Job_Step_Status_History
	@message varchar(128) = '' OUTPUT,
	@InfoOnly tinyint = 0
)
AS
	Set NoCount On

	declare @myRowCount int
	declare @myError int
	set @myRowCount = 0
	set @myError = 0
	
	declare @TimeIntervalLastUpdateMinutes real
	declare @TimeIntervalIdenticalStatsMinutes real
	Set @TimeIntervalLastUpdateMinutes = 0
	Set @TimeIntervalIdenticalStatsMinutes = 0
	
	Declare @NewStatCount int
	Declare @IdenticalStatCount int
	
	declare @UpdateTable tinyint
	Set @UpdateTable = 1
	
	Declare @MostRecentPostingTime datetime
	
	CREATE TABLE #TmpJobStepStatusHistory (
		Posting_Time datetime NOT NULL,
		Step_Tool varchar(64) NOT NULL,
		State tinyint NOT NULL,
		Step_Count int NOT NULL
	)
	
	
	-----------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------
	
	set @message = ''
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	
	Set @MostRecentPostingTime = Null
	
	-----------------------------------------------------
	-- Lookup the most recent posting time
	-----------------------------------------------------
	--
	SELECT @MostRecentPostingTime = MAX(Posting_Time)
	FROM T_Job_Step_Status_History
	--
	SELECT @myError = @@error, @myRowCount = @@RowCount
	
	If IsNull(@MinimumTimeIntervalMinutes, 0) = 0 Or @MostRecentPostingTime Is Null
		set @UpdateTable = 1
	Else
	Begin
		Set @TimeIntervalLastUpdateMinutes = DateDiff(second, @MostRecentPostingTime, GetDate()) / 60.0
		
		If @TimeIntervalLastUpdateMinutes >= @MinimumTimeIntervalMinutes
			set @UpdateTable = 1
		else
			set @UpdateTable = 0
	End
	
	if @UpdateTable = 1
	Begin
		-----------------------------------------------------
		-- Compute the new stats
		-----------------------------------------------------
		INSERT INTO #TmpJobStepStatusHistory  (Posting_Time, Step_Tool, State, Step_Count)
		SELECT GetDate() as Posting_Time, Step_Tool, State, COUNT(*) AS Step_Count
		FROM T_Job_Steps
		GROUP BY Step_Tool, State
		--
		SELECT @myError = @@error, @myRowCount = @@RowCount
		
		Set @NewStatCount = @myRowCount
		
		-----------------------------------------------------
		-- See if the stats match the most recent stats entered in the table
		-----------------------------------------------------
		
		Set @IdenticalStatCount = 0
		SELECT @IdenticalStatCount = COUNT(*)
		FROM #TmpJobStepStatusHistory NewStats
		     INNER JOIN ( SELECT Step_Tool,
		                         State,
		                         Step_Count
		                  FROM T_Job_Step_Status_History
		                  WHERE Posting_Time = @MostRecentPostingTime 
		                ) RecentStats
		       ON NewStats.Step_Tool = RecentStats.Step_Tool AND
		          NewStats.State = RecentStats.State AND
		          NewStats.Step_Count = RecentStats.Step_Count
		--
		SELECT @myError = @@error, @myRowCount = @@RowCount

		If @IdenticalStatCount = @NewStatCount
		Begin
			-----------------------------------------------------
			-- All of the stats match
			-- Only make new entries to T_Job_Step_Status_History if @MinimumTimeIntervalMinutesForIdenticalStats minutes have elapsed
			-----------------------------------------------------
			
			Set @TimeIntervalIdenticalStatsMinutes = DateDiff(second, @MostRecentPostingTime, GetDate()) / 60.0
			
			If @TimeIntervalIdenticalStatsMinutes >= @MinimumTimeIntervalMinutesForIdenticalStats
				set @UpdateTable = 1
			else
				set @UpdateTable = 0
		End


		If @UpdateTable = 1
		Begin
			If @InfoOnly <> 0
				SELECT Posting_Time, Step_Tool, State, Step_Count
				FROM #TmpJobStepStatusHistory
				ORDER BY Step_Tool, State
			Else				
			Begin
				INSERT INTO T_Job_Step_Status_History  (Posting_Time, Step_Tool, State, Step_Count)
				SELECT Posting_Time, Step_Tool, State, Step_Count
				FROM #TmpJobStepStatusHistory
				ORDER BY Step_Tool, State
				--
				SELECT @myError = @@error, @myRowCount = @@RowCount
				
				set @message = 'Appended ' + convert(varchar(9), @myRowCount) + ' rows to the Job Step Status History table'
			End
		End
		Else
			set @message = 'Update skipped since last update was ' + convert(varchar(9), Round(@TimeIntervalIdenticalStatsMinutes, 1)) + ' minutes ago and the stats are still identical'
		
	End
	else
		set @message = 'Update skipped since last update was ' + convert(varchar(9), Round(@TimeIntervalLastUpdateMinutes, 1)) + ' minutes ago'
	
Done:

	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobStepStatusHistory] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobStepStatusHistory] TO [PNL\D3M578] AS [dbo]
GO
