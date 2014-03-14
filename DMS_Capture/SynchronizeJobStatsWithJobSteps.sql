/****** Object:  StoredProcedure [dbo].[SynchronizeJobStatsWithJobSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SynchronizeJobStatsWithJobSteps
/****************************************************
**
**  Desc:	Makes sure the job stats (start and finish)
**			agree with the job steps for the job
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**			01/22/2010 mem - Initial version
**			03/10/2014 mem - Fixed logic related to @CompletedJobsOnly
**
*****************************************************/
(
	@infoOnly tinyint=1,
	@CompletedJobsOnly tinyint = 0,
	@message varchar(512)='' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	---------------------------------------------------
	-- Validate the inputs; clear the outputs
	---------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''

	CREATE TABLE #TmpJobsToUpdate (
		Job int,
		StartNew DateTime Null,
		FinishNew DateTime Null
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_TmpJobsToUpdate ON #TmpJobsToUpdate (Job)
	
	---------------------------------------------------
	-- Find jobs that need to be updated
	---------------------------------------------------
	
	INSERT INTO #TmpJobsToUpdate ( Job )
	SELECT J.job
	FROM T_Jobs J
	     INNER JOIN T_Job_Steps JS
	       ON J.Job = JS.Job
	WHERE (J.State = 4 And @CompletedJobsOnly <> 0 OR @CompletedJobsOnly = 0) AND
	      J.Finish < JS.Finish
	GROUP BY J.job
	UNION
	SELECT J.Job
	FROM T_Jobs J
	     INNER JOIN T_Job_Steps JS
	       ON J.Job = JS.Job
	WHERE (J.State = 4 And @CompletedJobsOnly <> 0 OR @CompletedJobsOnly = 0) AND
	      J.Start > JS.Start
	GROUP BY J.Job


	UPDATE #TmpJobsToUpdate
	SET StartNew = SourceQ.Step_Start,
	    FinishNew = SourceQ.Step_Finish
	FROM #TmpJobsToUpdate
	     INNER JOIN ( SELECT J.Job,
	                         MIN(JS.Start) AS Step_Start,
	                         MAX(JS.Finish) AS Step_Finish
	                  FROM T_Jobs J
	                       INNER JOIN T_Job_Steps JS
	                         ON J.Job = JS.Job
	                  WHERE J.Job IN ( SELECT Job
	                                   FROM #TmpJobsToUpdate )
	                  GROUP BY J.Job 
	                ) SourceQ
	       ON #TmpJobsToUpdate.Job = SourceQ.Job


	If @InfoOnly <> 0
		SELECT J.Job,
		       J.State,
		       J.Start,
		       J.Finish,
		       JTU.StartNew,
		       JTU.FinishNew
		FROM T_Jobs J
		     INNER JOIN #TmpJobsToUpdate JTU
		       ON J.Job = JTU.Job
    Else
    Begin
		---------------------------------------------------
		-- Update the Start/Finish times
		---------------------------------------------------
		
		UPDATE T_Jobs
		SET Start = JTU.StartNew,
		    Finish = JTU.FinishNew
		FROM T_Jobs J
		     INNER JOIN #TmpJobsToUpdate JTU
		       ON J.Job = JTU.Job
	End

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	--
	return @myError

GO
