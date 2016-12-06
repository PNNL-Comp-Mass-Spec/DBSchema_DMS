/****** Object:  StoredProcedure [dbo].[ResetFailedMyEMSLUploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ResetFailedMyEMSLUploads
/****************************************************
**
**	Desc:	Looks for failed Dataset Archive or Archive Update jobs with
**          known error messages. Reset the job to try again if @infoOnly = 0
**
**	Auth:	mem
**	Date:	08/01/2016 mem - Initial version
**    
*****************************************************/
(
	@infoOnly tinyint = 0,								-- 1 to preview the changes
	@message varchar(512) = '' output
)
As

	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	BEGIN TRY 
	
		-----------------------------------------------------------
		-- Validate the inputs
		-----------------------------------------------------------
		--
		Set @infoOnly = IsNull(@infoOnly, 0)
		Set @message = ''
		
		-----------------------------------------------------------
		-- Create the temporary tables
		-----------------------------------------------------------
		--

		CREATE TABLE #Tmp_FailedJobs (
			Job int
		)
			
		-----------------------------------------------------------
		-- Look for failed jobs
		-----------------------------------------------------------

		INSERT INTO #Tmp_FailedJobs( Job )
		SELECT DISTINCT Job
		FROM V_Job_Steps
		WHERE Tool = 'ArchiveVerify' AND
		      State = 6 AND
		      Completion_Message LIKE '%Input/output error%' AND
		      Job_State = 5
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

        If Not Exists (Select * From #Tmp_FailedJobs)
        Begin
            If @infoOnly > 0
                Select 'No failed jobs were found' as Message
                
            Goto Done
        End
        
		-----------------------------------------------------------
		-- Construct a comma-separated list of jobs then call RetryMyEMSLUpload
		-----------------------------------------------------------
		--
		Declare @JobList varchar(max) = null
    	
		SELECT @JobList = Coalesce(@JobList + ',' + Cast(Job as varchar(9)), Cast(Job as varchar(9)))
		FROM #Tmp_FailedJobs
		ORDER BY Job
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


        exec @myError = RetryMyEMSLUpload @Jobs = @JobList, @infoOnly = @infoOnly, @message = ''
        
		-----------------------------------------------------------
		-- Post a log entry if any jobs were reset
		-- Posting as an error so that it shows up in the daily error log
		-----------------------------------------------------------
		--
        If @infoOnly = 0
        Begin
            Declare @jobCount int
            
            SELECT @jobCount = COUNT(*)
            FROM #Tmp_FailedJobs
            
            Set @message = 'Warning: Retrying MyEMSL upload for ' + dbo.CheckPlural(@jobCount, 'job ', 'jobs ') + @jobList
            
            exec PostLogEntry 'Error', @message, 'ResetFailedMyEMSLUploads'
        End
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ResetFailedMyEMSLUploads] TO [DDL_Viewer] AS [dbo]
GO
