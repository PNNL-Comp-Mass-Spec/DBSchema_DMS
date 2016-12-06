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
**			04/08/2011 mem - Now skipping the 'ImsDeMultiplex' step for datasets that end in '_inverse'
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**    
*****************************************************/
(
	@job int,
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- update step dependency count
	---------------------------------------------------
	--
	UPDATE #Job_Steps
	SET
		Dependencies = T.dependencies
	FROM   
		#Job_Steps INNER JOIN
		(
			SELECT   
			  Step_Number,
			  COUNT(*) AS dependencies
			FROM     
			  #Job_Step_Dependencies
			WHERE    (Job = @job)
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
	-- initialize input folder to dataset 
	-- for steps that have no dependencies 
	---------------------------------------------------
	--
	UPDATE #Job_Steps
	SET
		Input_Folder_Name = ''
	FROM   
		#Job_Steps
	WHERE
		Dependencies = 0 AND
		Job = @job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error setting default input folder names'
		goto Done
	end

	---------------------------------------------------
	-- Set results folder name for job to be that of
	--  the output folder for any step designated as
	--  Special="Job_Results"
	-- 
	-- This will only affect jobs that have a step with
	--  the Special_Instructions = 'Job_Results' attribute
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
	-- Skip the demultiplex step for datasets that end in _inverse
	-- These datasets have already been demultiplexed
	---------------------------------------------------
	--
	UPDATE #Job_Steps
	SET State = 3
	FROM #Job_Steps JS
	     INNER JOIN #Jobs J
	       ON JS.Job = J.Job
	WHERE J.Dataset LIKE '%[_]inverse' AND
	      JS.Step_Tool = 'ImsDeMultiplex'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	
	---------------------------------------------------
	-- set job to initialized state ("New")
	---------------------------------------------------
	--
	UPDATE #Jobs
	SET 
		State = 1
	WHERE 
		Job = @job
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
