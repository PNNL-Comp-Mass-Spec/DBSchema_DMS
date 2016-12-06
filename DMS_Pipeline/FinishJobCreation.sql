/****** Object:  StoredProcedure [dbo].[FinishJobCreation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FinishJobCreation
/****************************************************
**
**	Desc: 
**  Perform a mixed bag of operations on the jobs
**  in the temporary tables to finalize them before
**  copying to the main database tables
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	01/31/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**			03/06/2009 grk - added code for: Special="Job_Results"
**			07/31/2009 mem - Now filtering by job in the subquery that looks for job steps with flag Special="Job_Results" (necessary when #Job_Steps contains more than one job)
**			03/21/2011 mem - Added support for Special="ExtractSourceJobFromComment"
**			03/22/2011 mem - Now calling AddUpdateJobParameterTempTable
**			04/04/2011 mem - Removed SourceJob code since needs to occur after T_Job_Parameters has been updated for this job
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**    
*****************************************************/
(
	@job int,
	@message varchar(512) output,
	@DebugMode tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- update step dependency count
	---------------------------------------------------
	--
	UPDATE #Job_Steps
	SET Dependencies = T.dependencies
	FROM #Job_Steps
	     INNER JOIN ( SELECT Step_Number,
	                         COUNT(*) AS dependencies
	                  FROM #Job_Step_Dependencies
	                  WHERE (Job = @job)
	                  GROUP BY Step_Number 
	                ) AS T
	       ON T.Step_Number = #Job_Steps.Step_Number
	WHERE #Job_Steps.Job = @job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating job step dependency count'
		goto Done
	end

	---------------------------------------------------
	-- Initialize the input folder to an empty string
	-- for steps that have no dependencies 
	---------------------------------------------------
	--
	UPDATE #Job_Steps
	SET Input_Folder_Name = ''
	FROM #Job_Steps
	WHERE Job = @job AND
	      Dependencies = 0
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error setting default input folder names'
		goto Done
	end

	---------------------------------------------------
	-- Set results folder name for the job to be that of
	--  the output folder for any step designated as
	--  Special="Job_Results"
	-- 
	-- This will only affect jobs that have a step with
	--  the Special_Instructions = 'Job_Results' attribute
	--
	-- Scripts MSXML_Gen and DTA_Gen use this since they
	--   produce a shared results folder, yet we also want
	--   the results folder for the job to show the shared results folder name
	---------------------------------------------------
	--
	UPDATE #Jobs
	SET Results_Folder_Name = TZ.Output_Folder_Name
	FROM #Jobs INNER JOIN
		(
			SELECT TOP 1 Job, Output_Folder_Name
			FROM #Job_Steps
			WHERE Job = @job AND
			      Special_Instructions = 'Job_Results'
			ORDER BY Step_Number
		) TZ ON #Jobs.Job = TZ.Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- set job to initialized state ("New")
	---------------------------------------------------
	--
	UPDATE #Jobs
	SET State = 1
	WHERE Job = @job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating job state'
		goto Done
	end

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[FinishJobCreation] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FinishJobCreation] TO [Limited_Table_Write] AS [dbo]
GO
