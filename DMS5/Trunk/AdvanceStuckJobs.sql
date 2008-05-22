/****** Object:  StoredProcedure [dbo].[AdvanceStuckJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AdvanceStuckJobs
/****************************************************
**
**	Desc:	Looks for for Jobs in state 2 or 17
**			Calls AdvanceStuckJobIfComplete for each
**
**			Use @infoOnly = 1 to preview updates
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	04/29/2008 (Ticket:672)
**			05/03/2008 mem - Updated to show all jobs in state 2 or 17, even if no jobs are potentially stuck
**    
*****************************************************/
(
	@JobListOverride varchar(2048) = '',
	@JobStartHoldoffMinutes int = 360,				-- Time since job started; minimum value is 30 minutes
	@JobCompleteHoldoffMinutes int = 60,			-- Time since AnalysisSummary.txt file was last written; minimum value is 10 minutes
	@message varchar(512) = '' output,
	@infoOnly tinyint = 1
)
As
	Set nocount on
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @Job int
	Declare @JobCount int
	Declare @JobText varchar(32)
	Declare @Continue tinyint
	
	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------

	Set @JobListOverride = IsNull(@JobListOverride, '')
	
	Set @JobStartHoldoffMinutes = IsNull(@JobStartHoldoffMinutes, 360)
	If @JobStartHoldoffMinutes < 30
		Set @JobStartHoldoffMinutes = 30

	Set @JobCompleteHoldoffMinutes = IsNull(@JobCompleteHoldoffMinutes, 60)
	If @JobCompleteHoldoffMinutes < 10
		Set @JobCompleteHoldoffMinutes = 10

	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)

	------------------------------------------------
	-- Create the temporary table to hold the jobs
	------------------------------------------------
	CREATE TABLE #TmpJobListToProcess (
		Job int NOT NULL
	)
	
	If Len(@JobListOverride) > 0
	Begin
		------------------------------------------------
		-- Populate #TmpJobListToProcess with the jobs in @JobListOverride
		------------------------------------------------
		--
		INSERT INTO #TmpJobListToProcess (Job)
		SELECT AJ.AJ_jobID
		FROM T_Analysis_Job AJ INNER JOIN
			 (SELECT Convert(int, Item) AS Job
			  FROM dbo.MakeTableFromListDelim(@JobListOverride, ',')
			 ) JobListQ ON AJ.AJ_JobID = JobListQ.Job
		WHERE AJ_StateID IN (2, 17)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @JobCount = @myRowCount
		If @JobCount = 1
			Set @JobText = 'job'
		Else
			Set @JobText = 'jobs'
			
		Set @Message = 'Populated #TmpJobListToProcess table with ' + Convert(varchar(12), @myRowCount) + ' ' + @JobText + ' from @JobListOverride'
	End
	Else
	Begin		
		------------------------------------------------
		-- Populate #TmpJobListToProcess with jobs in state 2 or 17
		-- that started over @JobStartHoldoffMinutes minutes ago
		------------------------------------------------
		--
		INSERT INTO #TmpJobListToProcess (Job)
		SELECT AJ_jobID
		FROM T_Analysis_Job AJ
		WHERE AJ_StateID = 2 AND(DATEDIFF(minute, AJ_start, GETDATE()) >= @JobStartHoldoffMinutes) OR
			  AJ_StateID = 17 AND(DATEDIFF(minute, AJ_Finish, GETDATE()) >= @JobStartHoldoffMinutes)
		ORDER BY AJ_JobID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		Set @JobCount = @myRowCount
		If @JobCount = 1
			Set @JobText = 'job'
		Else
			Set @JobText = 'jobs'
		
		Set @Message = 'Found ' + Convert(varchar(12), @myRowCount) + ' ' + @JobText + ' in T_Analysis_Job that have a state of 2 or 17 and started (or finished) over ' + Convert(varchar(12), @JobStartHoldoffMinutes) + ' minutes ago'
	End	

	If @InfoOnly <> 0
	Begin 
		SELECT *
		FROM ( SELECT Job,
					AJ.AJ_Start AS Job_Start,
					AJ.AJ_Finish AS Job_Finish,
					AJ_AssignedProcessorName AS Processor,
					CASE
						WHEN AJ.AJ_Finish IS NULL OR
							AJ.AJ_Start >= IsNull(AJ.AJ_Finish, AJ.AJ_Start) THEN 
							Round(DateDiff(MINUTE, AJ.AJ_Start, GetDate()) / 60.0, 1)
						ELSE 
							Round(DateDiff(MINUTE, AJ.AJ_Finish, GetDate()) / 60.0, 1)
					END AS Elapsed_Time_Hours,
					Stuck,
					AnTool.AJT_toolName AS Analysis_Tool,
					SPath.SP_vol_name_client AS Storage_Server,
					DS.Dataset_Num AS Dataset
			FROM (	SELECT AJ.AJ_JobID AS Job, 
						 1 AS Stuck
					FROM #TmpJobListToProcess JL
						INNER JOIN T_Analysis_Job AJ
							ON JL.Job = AJ.AJ_JobID
					UNION
					SELECT AJ.AJ_JobID AS Job,
						   0 AS Stuck
					FROM T_Analysis_Job AJ
						 LEFT OUTER JOIN #TmpJobListToProcess JL
							ON JL.Job = AJ.AJ_JobID
					WHERE AJ.AJ_StateID IN (2, 17) AND
						  JL.Job IS NULL 
					) LookupQ
					INNER JOIN T_Analysis_Job AJ
					 ON LookupQ.Job = AJ.AJ_JobID
					INNER JOIN T_Dataset DS
					 ON AJ.AJ_DatasetID = DS.Dataset_ID
					INNER JOIN T_Storage_Path SPath
					 ON DS.DS_storage_path_ID = SPath.SP_path_ID 
					INNER JOIN T_Analysis_Tool AnTool
					 ON AJ.AJ_AnalysisToolID = AnTool.AJT_ToolID
			) StatsQ
		ORDER BY Elapsed_Time_Hours Desc
	
	End

	If @JobCount = 0
		SELECT @Message as Message
	
	If @JobCount = 0
		Goto Done

	------------------------------------------------
	-- Process the jobs in #TmpJobListToProcess
	------------------------------------------------
	
	Set @Job = 0
	
	Set @Continue = 1
	While @Continue = 1
	Begin
		SELECT TOP 1 @Job = Job
		FROM #TmpJobListToProcess
		WHERE Job > @Job
		ORDER BY Job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
			Set @Continue = 0
		Else
		Begin
			Exec @myError = AdvanceStuckJobIfComplete @Job, @JobCompleteHoldoffMinutes, @message = @message output, @infoOnly = @infoOnly
			
			If @myError <> 0
			Begin
				If Len(IsNull(@message, '')) = 0
					Set @Message = 'Error calling AdvanceStuckJobIfComplete for Job ' + Convert(varchar(19), @Job)
				
				Set @Continue = 0
			End
		End
	End
		
Done:
	return @myError

GO
GRANT ALTER ON [dbo].[AdvanceStuckJobs] TO [D3L243]
GO
GRANT EXECUTE ON [dbo].[AdvanceStuckJobs] TO [D3L243]
GO
GRANT EXECUTE ON [dbo].[AdvanceStuckJobs] TO [PNL\D3M578]
GO
