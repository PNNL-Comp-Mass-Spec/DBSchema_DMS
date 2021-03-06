/****** Object:  StoredProcedure [dbo].[MakeNewAutomaticJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MakeNewAutomaticJobs]
/****************************************************
**
**	Desc: 
**    Create new jobs for jobs that are complete
**    that have scripts that have entries in the 
**    automatic job creation table
**	
** 
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	09/11/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/26/2017 mem - Add support for column Enabled in T_Automatic_Jobs
**          01/29/2021 mem - Remove unused parameters
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) output
)
As
	Set nocount on
	
	Declare @myError int = 0
	Declare @myRowCount int = 0

	-- Find jobs that are complete for which jobs for the same script and dataset don't already exist

    -- In particular, after a DatasetArchive job finishes, create new SourceFileRename and MyEMSLVerify jobs 
    -- (since that relationship is defined in T_Automatic_Jobs)

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
