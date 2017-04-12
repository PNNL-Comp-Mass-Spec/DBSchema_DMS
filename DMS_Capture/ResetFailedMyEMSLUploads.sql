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
**			01/26/2017 mem - Add parameters @maxJobsToReset and @jobListOverride
**			               - Check for Completion_Message "Exception checking archive status"
**			               - Expand @message to varchar(4000)
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**
*****************************************************/
(
	@infoOnly tinyint = 0,								-- 1 to preview the changes
	@maxJobsToReset int = 0,
	@jobListOverride varchar(4000) = '',				-- Comma-separated list of jobs to reset.  Jobs must have a failed step in T_Job_Steps
	@message varchar(4000) = '' output
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
		Set @maxJobsToReset = IsNull(@maxJobsToReset, 0)
		Set @jobListOverride = IsNull(@jobListOverride, '')
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
		      (Completion_Message LIKE '%Input/output error%' OR 
		       Completion_Message LIKE '%Exception checking archive status%') AND
		      Job_State = 5
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

        If @jobListOverride <> ''
        Begin
			INSERT INTO #Tmp_FailedJobs( Job )
			SELECT Distinct Value
			FROM dbo.udfParseDelimitedIntegerList ( @jobListOverride, ',' ) SrcJobs
			     INNER JOIN V_Job_Steps JS
			       ON SrcJobs.VALUE = JS.Job
			     LEFT OUTER JOIN #Tmp_FailedJobs Target
			       ON JS.Job = Target.Job
			WHERE JS.Tool LIKE '%archive%' AND
			      JS.State = 6 AND
			      Target.Job Is Null
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        If Not Exists (Select * From #Tmp_FailedJobs)
        Begin
            If @infoOnly > 0
                Select 'No failed jobs were found' as Message
                
            Goto Done
        End

        -----------------------------------------------------------
        -- Possibly limit the number of jobs to reset
        -----------------------------------------------------------
        --

		Declare @jobCountAtStart int
		
		Select @jobCountAtStart = Count(*) 
		FROM #Tmp_FailedJobs

        If @maxJobsToReset > 0 And @jobCountAtStart > @maxJobsToReset
        Begin
			
			DELETE #Tmp_FailedJobs
			WHERE NOT Job IN ( SELECT TOP ( @maxJobsToReset ) Job
			                   FROM #Tmp_FailedJobs
			                   ORDER BY Job )
			
			Declare @verb varchar(16)
			If @infoOnly = 0
				Set @verb = 'Resetting '
			Else
				Set @verb = 'Would reset '
			
			Select @verb + Cast(@maxJobsToReset as varchar(9)) + ' out of ' + Cast(@jobCountAtStart as varchar(9)) + ' candidate jobs' as Reset_Message

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
            
            Select @message as Message
        End
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'ResetFailedMyEMSLUploads'
	END CATCH

Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ResetFailedMyEMSLUploads] TO [DDL_Viewer] AS [dbo]
GO
