/****** Object:  StoredProcedure [dbo].[SynchronizeJobStatsWithDMS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SynchronizeJobStatsWithDMS
/****************************************************
**
**	Desc: 
**		Makes sure the job start/end times defined in T_Jobs match those in DMS
**		Only processes jobs with a state of 4 or 5 in T_Jobs
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			02/27/2010 mem - Initial version
**    
*****************************************************/
(
	@JobListToProcess varchar(max) = '',			-- Jobs to process; if blank, then will process all jobs in T_Jobs
	@InfoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs	
	---------------------------------------------------
	Set @JobListToProcess = IsNull(@JobListToProcess, '')
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @message = ''
	
	
	---------------------------------------------------
	-- Table to hold jobs to process
	---------------------------------------------------
	CREATE TABLE #Tmp_JobsToProcess (
		Job int
	)

	CREATE CLUSTERED INDEX #IX_Tmp_JobsToProcess_Job ON #Tmp_JobsToProcess (Job)

	---------------------------------------------------
	-- Populate #Tmp_JobsToProcess
	---------------------------------------------------
	--
	If @JobListToProcess = ''
		INSERT INTO #Tmp_JobsToProcess (Job)
		SELECT T_Jobs.Job
		FROM T_Jobs
		WHERE T_Jobs.State IN (4,5)
	Else
		INSERT INTO #Tmp_JobsToProcess (Job)
		SELECT T_Jobs.Job
		FROM T_Jobs
			INNER JOIN ( SELECT Value AS Job
						FROM dbo.udfParseDelimitedIntegerList ( @JobListToProcess, ',' ) 
						) ValueQ
			ON T_Jobs.Job = ValueQ.Job
		WHERE T_Jobs.State IN (4,5)
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	Set @message = 'Validating start/finish times for ' + Convert(varchar(12), @myRowCount) + ' job'
	
	If @myRowCount <> 1
		Set @message = @message + 's'

	---------------------------------------------------
	-- Update jobs where the start or finish time differ
	---------------------------------------------------
	--
	If @InfoOnly <> 0
		SELECT T_Jobs.Job,
		       Target.AJ_Start AS Start,
		       T_Jobs.Start AS StartNew,
		       Target.AJ_Finish AS Finish,
		       T_Jobs.Finish AS FinishNew,
		       Target.AJ_ProcessingTimeMinutes AS ProcTimeMinutes,
		       JobProcTime.ProcessingTimeMinutes AS ProcTimeMinutesNew,
		       Abs(DateDiff(SECOND, AJ_Start, T_Jobs.Start)) AS StartDiffSeconds,
		       Abs(DateDiff(SECOND, AJ_Finish, T_Jobs.Finish)) AS FinishDiffSeconds,
		       Convert(decimal(9,2), Abs(IsNull(Target.AJ_ProcessingTimeMinutes, 0) - JobProcTime.ProcessingTimeMinutes)) AS ProcTimeDiffMinutes
		FROM T_Jobs
		     INNER JOIN S_DMS_T_Analysis_Job Target
		       ON T_Jobs.Job = Target.AJ_JobID
		     INNER JOIN #Tmp_JobsToProcess JTP
		       ON T_Jobs.Job = JTP.Job
		     INNER JOIN V_Job_Processing_Time JobProcTime
		       ON T_Jobs.Job = JobProcTime.Job
		WHERE Abs(DateDiff(SECOND, IsNull(AJ_Start, '1/1/2000'), T_Jobs.Start)) > 1 OR
		      Abs(DateDiff(SECOND, IsNull(AJ_Finish, '1/1/2000'), T_Jobs.Finish)) > 1 OR
		      Abs(IsNull(Target.AJ_ProcessingTimeMinutes, 0) - JobProcTime.ProcessingTimeMinutes) > 0.1
		ORDER BY T_Jobs.Job

	Else
	Begin
		UPDATE S_DMS_T_Analysis_Job
		SET AJ_Start = T_Jobs.Start,
		    AJ_Finish = T_Jobs.Finish,
		    AJ_ProcessingTimeMinutes = JobProcTime.ProcessingTimeMinutes
		FROM T_Jobs
		     INNER JOIN S_DMS_T_Analysis_Job Target
		       ON T_Jobs.Job = Target.AJ_JobID
		     INNER JOIN #Tmp_JobsToProcess JTP
		       ON T_Jobs.Job = JTP.Job
		     INNER JOIN V_Job_Processing_Time JobProcTime
		       ON T_Jobs.Job = JobProcTime.Job
		WHERE Abs(DateDiff(SECOND, IsNull(AJ_Start, '1/1/2000'), T_Jobs.Start)) > 1 OR
		      Abs(DateDiff(SECOND, IsNull(AJ_Finish, '1/1/2000'), T_Jobs.Finish)) > 1 OR
		      Abs(IsNull(Target.AJ_ProcessingTimeMinutes, 0) - JobProcTime.ProcessingTimeMinutes) > 0.1
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	    
		Set @message = @message + '; Updated ' + Convert(varchar(12), @myRowCount) + ' job'
		
		If @myRowCount <> 1
			Set @message = @message + 's'
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	Print @message
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SynchronizeJobStatsWithDMS] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SynchronizeJobStatsWithDMS] TO [Limited_Table_Write] AS [dbo]
GO
