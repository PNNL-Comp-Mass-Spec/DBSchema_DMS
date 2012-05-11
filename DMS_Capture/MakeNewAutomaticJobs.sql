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
**	09/11/2009 -- initial release (http://prismtrac.pnl.gov/trac/ticket/746)
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
	
	INSERT  INTO T_Jobs
			( Script,
			  Dataset,
			  Dataset_ID,
			  Comment		
			)
	-- jobs that are complete for which jobs for the same script and dataset don't already exist
	SELECT
	  T_Automatic_Jobs.Script_For_New_Job AS Script,
	  T_Jobs_1.Dataset,
	  T_Jobs_1.Dataset_ID,
	  'Created from Job ' + CONVERT(VARCHAR(12), T_Jobs_1.Job) AS Comment
	FROM
	  T_Jobs AS T_Jobs_1
	  INNER JOIN T_Automatic_Jobs ON T_Jobs_1.Script = T_Automatic_Jobs.Script_For_Completed_Job
	WHERE
	  NOT EXISTS ( SELECT
					*
				   FROM
					dbo.T_Jobs
				   WHERE
					Script = Script_For_New_Job
					AND Dataset = T_Jobs_1.Dataset )
	  AND ( State = 3 )
GO
