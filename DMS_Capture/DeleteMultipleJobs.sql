/****** Object:  StoredProcedure [dbo].[DeleteMultipleJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DeleteMultipleJobs
/****************************************************
**
**	Desc:
**	Deletes entries from appropriate tables
**  for all jobs in given list
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	06/03/2010 -- initial release 
**
*****************************************************/
(
    @jobList varchar(max),
	@callingUser varchar(128) = '',
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY

		---------------------------------------------------
		--
		---------------------------------------------------
		CREATE TABLE #JOBS (
			Job INT
		)
		--
		INSERT INTO #JOBS (Job) 
		SELECT Item FROM dbo.MakeTableFromList(@jobList)

		---------------------------------------------------
		--
		---------------------------------------------------
		--
		declare @transName varchar(32)
		set @transName = 'DeleteMultipleJobs'
		begin transaction @transName

		---------------------------------------------------
		-- delete job dependencies
		---------------------------------------------------
		--
		DELETE FROM T_Job_Step_Dependencies
		WHERE (Job_ID IN (SELECT Job FROM #JOBS))

   		---------------------------------------------------
		-- delete job parameters
		---------------------------------------------------
		--
		DELETE FROM T_Job_Parameters
		WHERE Job IN (SELECT Job FROM #JOBS)

		---------------------------------------------------
		-- delete job steps
		---------------------------------------------------
		--
		DELETE FROM T_Job_Steps
		WHERE Job IN (SELECT Job FROM #JOBS)

   		---------------------------------------------------
		-- delete jobs
		---------------------------------------------------
		--
		DELETE FROM T_Jobs
		WHERE Job IN (SELECT Job FROM #JOBS)

		---------------------------------------------------
		--
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
