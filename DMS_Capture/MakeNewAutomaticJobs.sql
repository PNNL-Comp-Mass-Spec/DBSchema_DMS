/****** Object:  StoredProcedure [dbo].[MakeNewAutomaticJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeNewAutomaticJobs
/****************************************************
**
**	Desc: 
**    create new jobs for jobs that are complete
**    that have scripts that have entries in the 
**    automatic job creation table
**	
** 
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	09/11/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/26/2017 mem - Add support for column Enabled in T_Automatic_Jobs
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) output,
	@MaxJobsToProcess int = 0,
	@LoopingUpdateInterval int = 5		-- Seconds between detailed logging while looping through the dependencies
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	-- Find jobs that are complete for which jobs for the same script and dataset don't already exist
	--
	INSERT INTO T_Jobs
			( Script,
			  Dataset,
			  Dataset_ID,
			  Comment		
			)
	SELECT AJ.Script_For_New_Job AS Script,
	       J.Dataset,
	       J.Dataset_ID,
	       'Created from Job ' + CONVERT(varchar(12), J.Job) AS [Comment]
	FROM T_Jobs AS J
	     INNER JOIN T_Automatic_Jobs AJ
	       ON J.Script = AJ.Script_For_Completed_Job AND
	          AJ.Enabled = 1
	WHERE (J.State = 3) AND 
	      NOT EXISTS ( SELECT *
	                   FROM dbo.T_Jobs
	                   WHERE Script = Script_For_New_Job AND
	                         Dataset = J.Dataset )
	      

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNewAutomaticJobs] TO [DDL_Viewer] AS [dbo]
GO
