/****** Object:  StoredProcedure [dbo].[RetryCaptureForDMSResetJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.RetryCaptureForDMSResetJobs
/****************************************************
**
**  Desc:	Retry capture for datasets that failed capture
**			but for which the dataset state in DMS is 1=New
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	mem
**  Date:	05/25/2011 mem - Initial version
**    
*****************************************************/
(
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	CREATE TABLE #SJL (
		Job int NOT NULL
	)
	
	---------------------------------------------------
	-- Look for jobs that are failed and have one or more failed step states
	--  but for which the dataset is present in V_DMS_Get_New_Datasets
	-- These are datasets that have been reset (either via the dataset detail report web page or manually)
	--  and we thus want to retry capture for these datasets
	---------------------------------------------------
	--
	INSERT INTO #SJL (Job)
	SELECT DISTINCT J.Job
	FROM V_DMS_Get_New_Datasets NewDS
	     INNER JOIN T_Jobs J
	       ON NewDS.Dataset_ID = J.Dataset_ID
	     INNER JOIN T_Job_Steps JS
	       ON J.Job = JS.Job
	WHERE (J.Script IN ('IMSDatasetCapture', 'DatasetCapture')) AND
	      (J.State = 5) AND
	      (JS.State = 6)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for DatasetCapture jobs to reset'
		goto Done
	end
	
	If @myRowCount = 0
	Begin
		set @message = 'No datasets were found needing to retry capture'
		goto Done		
	End
	
	-- Construct a comma-separated list of jobs
	
	Declare @jobList varchar(max)
	Set @jobList = ''
	
	SELECT @jobList = @jobList + Convert(varchar(12), Job) + ','
	FROM #SJL
	ORDER BY Job
	
	-- Remove the trailing comma
	If Len(@jobList) > 0
		Set @jobList = SubString(@jobList, 1, Len(@jobList)-1)
		
		
	If @infoOnly <> 0
	Begin
		SELECT *
		FROM T_Jobs
		WHERE Job IN ( SELECT Job
		               FROM #SJL )
		ORDER BY Job
		
		SELECT *
		FROM V_Job_Steps
		WHERE Job IN ( SELECT Job
		               FROM #SJL )
		ORDER BY Job, Step
		
		Print 'JobList: ' + @jobList		
	End
	Else
	Begin -- <a>
		
		-- Update the job parameters for each job
		exec UpdateParametersForJob @jobList, @message output
		
		-- Reset the job steps using RetrySelectedJobs
		-- Fail out any completed steps before performing the reset
		
		Declare @transName varchar(32) = 'RetryCaptureForDMSResetJobs'

		begin transaction @transName
		
		UPDATE T_Job_Steps
		SET State = 6
		WHERE State = 5 AND Job IN (SELECT Job FROM #SJL)
	
		EXEC @myError = RetrySelectedJobs @message output
		IF @myError <> 0
			rollback transaction @transName
		ELSE 
	 		commit transaction @transName
				
		-- Post a log entry that the job(s) have been reset
		If @JobList LIKE '%,%'
			Set @message = 'Reset dataset capture for jobs ' + @JobList
		Else
			Set @message = 'Reset dataset capture for job ' + @JobList
				
		exec PostLogEntry 'Normal', @message, 'RetryCaptureForDMSResetJobs'
		
	End -- </a>
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError
GO
