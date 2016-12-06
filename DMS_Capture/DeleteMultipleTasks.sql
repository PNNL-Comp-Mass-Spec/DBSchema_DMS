/****** Object:  StoredProcedure [dbo].[DeleteMultipleTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DeleteMultipleTasks
/****************************************************
**
**	Desc:
**		Deletes entries from appropriate tables
**		for all jobs in given list
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	06/03/2010 grk - Initial release 
**			09/11/2012 mem - Renamed from DeleteMultipleJobs to DeleteMultipleTasks
**			09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**			02/23/2016 mem - Add set XACT_ABORT on
**			03/24/2016 mem - Switch to using udfParseDelimitedIntegerList to parse the list of jobs
**
*****************************************************/
(
    @jobList varchar(max),
	@callingUser varchar(128) = '',
	@message varchar(512)='' output
)
As
	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	BEGIN TRY

		---------------------------------------------------
		-- Create and populate a temporary table
		---------------------------------------------------
		CREATE TABLE #JOBS (
			Job INT
		)
		--
		INSERT INTO #JOBS (Job)
		SELECT Value
		FROM dbo.udfParseDelimitedIntegerList(@jobList, ',')
		ORDER BY Value

		---------------------------------------------------
		-- Start a transaction
		---------------------------------------------------
		--
		declare @transName varchar(32)
		set @transName = 'DeleteMultipleJobs'
		begin transaction @transName

		---------------------------------------------------
		-- Delete job dependencies
		---------------------------------------------------
		--
		DELETE FROM T_Job_Step_Dependencies
		WHERE (Job IN (SELECT Job FROM #JOBS))

   		---------------------------------------------------
		-- delete job parameters
		---------------------------------------------------
		--
		DELETE FROM T_Job_Parameters
		WHERE Job IN (SELECT Job FROM #JOBS)

		---------------------------------------------------
		-- Delete job steps
		---------------------------------------------------
		--
		DELETE FROM T_Job_Steps
		WHERE Job IN (SELECT Job FROM #JOBS)

   		---------------------------------------------------
		-- Delete jobs
		---------------------------------------------------
		--
		DELETE FROM T_Jobs
		WHERE Job IN (SELECT Job FROM #JOBS)

		---------------------------------------------------
		-- Commit the transaction
		---------------------------------------------------
		--
 		commit transaction @transName

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

	END CATCH

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteMultipleTasks] TO [DDL_Viewer] AS [dbo]
GO
