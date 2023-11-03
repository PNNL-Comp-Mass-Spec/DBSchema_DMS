/****** Object:  StoredProcedure [dbo].[reset_failed_myemsl_uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reset_failed_myemsl_uploads]
/****************************************************
**
**  Desc:
**      Looks for failed Dataset Archive or Archive Update tasks with known error messages
**      Resets the capture tasks to try again if @infoOnly = 0
**
**  Auth:   mem
**  Date:   08/01/2016 mem - Initial version
**          01/26/2017 mem - Add parameters @maxJobsToReset and @jobListOverride
**                         - Check for Completion_Message "Exception checking archive status"
**                         - Expand @message to varchar(4000)
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          07/13/2017 mem - Add parameter @resetHoldoffMinutes
**                           Change exception messages to reflect the new MyEMSL API
**          07/20/2017 mem - Store the upload error message in T_MyEMSL_Upload_Resets
**                         - Reset steps with message 'Connection aborted.', BadStatusLine("''",)
**          08/01/2017 mem - Reset steps with message 'Connection aborted.', error(32, 'Broken pipe')
**          12/15/2017 mem - Reset steps with message 'ingest/backend/tasks.py'
**          03/07/2018 mem - Do not reset the same job/subfolder ingest task more than once
**          02/02/2023 bcg - Changed from V_Job_Steps to V_Task_Steps
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          11/02/2023 bcg - Reset steps with message 'pacifica/ingest/tasks.py'
**
*****************************************************/
(
    @infoOnly tinyint = 0,                      -- 1 to preview the changes
    @maxJobsToReset int = 0,
    @jobListOverride varchar(4000) = '',        -- Comma-separated list of jobs to reset.  Jobs must have a failed step in T_Task_Steps
    @resetHoldoffMinutes real = 15,             -- Holdoff time to apply to column Finish
    @message varchar(4000) = '' output
)
AS
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
        Set @resetHoldoffMinutes = IsNull(@resetHoldoffMinutes, 15)
        Set @message = ''

        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------
        --

        CREATE TABLE #Tmp_FailedJobs (
            Job int,
            Dataset_ID int,
            Subfolder varchar(128) NULL,
            [Error_Message] varchar(256) NULL,
            SkipReset tinyint Null,
            SkipReason varchar(128) NULL
        )

        -----------------------------------------------------------
        -- Look for failed capture task jobs
        -----------------------------------------------------------

        INSERT INTO #Tmp_FailedJobs( Job, Dataset_ID, Subfolder, [Error_Message], SkipReset )
        SELECT Job, Dataset_ID, IsNull(Output_Folder, Input_Folder), Max(Completion_Message), 0 AS SkipReset
        FROM V_Task_Steps
        WHERE Tool = 'ArchiveVerify' AND
              State = 6 AND
              (Completion_Message LIKE '%ConnectionTimeout%' OR
               Completion_Message LIKE '%Connection reset by peer%' OR
               Completion_Message LIKE '%Internal Server Error%' OR
               Completion_Message LIKE '%Connection aborted%BadStatusLine%' OR
               Completion_Message LIKE '%Connection aborted%Broken pipe%' OR
               Completion_Message LIKE '%ingest/backend/tasks.py%' OR
               Completion_Message LIKE '%pacifica/ingest/tasks.py%') AND
              Job_State = 5 AND
              Finish < DateAdd(minute, -@resetHoldoffMinutes, GetDate())
        GROUP BY Job, Dataset_ID, Output_Folder, Input_Folder
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @jobListOverride <> ''
        Begin
            INSERT INTO #Tmp_FailedJobs( Job, Dataset_ID, Subfolder, [Error_Message], SkipReset )
            SELECT DISTINCT Value, TS.Dataset_ID, TS.Output_Folder, TS.Completion_Message, 0 AS SkipReset
            FROM dbo.parse_delimited_integer_list ( @jobListOverride, ',' ) SrcJobs
                 INNER JOIN V_Task_Steps TS
                   ON SrcJobs.VALUE = TS.Job
                 LEFT OUTER JOIN #Tmp_FailedJobs Target
                   ON TS.Job = Target.Job
            WHERE TS.Tool LIKE '%archive%' AND
                  TS.State = 6 AND
                  Target.Job Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        If Not Exists (SELECT * FROM #Tmp_FailedJobs)
        Begin
            If @infoOnly > 0
                SELECT 'No failed jobs were found' AS Message

            Goto Done
        End

        -----------------------------------------------------------
        -- Flag any capture task jobs that have failed twice for the same subfolder
        -- pushing the same number of files each time
        -----------------------------------------------------------

        UPDATE #Tmp_FailedJobs
        SET SkipReset = 1,
            SkipReason = 'Upload has failed two or more times'
        FROM #Tmp_FailedJobs Target
             INNER JOIN ( SELECT U.Job,
                                 U.SubFolder,
                                 U.FileCountNew,
                                 U.FileCountUpdated,
                                 Count(*) AS Attempts
                          FROM T_MyEMSL_Uploads AS U
                               INNER JOIN #Tmp_FailedJobs
                                 ON U.Job = #Tmp_FailedJobs.Job AND
                                    U.Subfolder = #Tmp_FailedJobs.Subfolder
                          WHERE U.Verified = 0
                          GROUP BY U.Job, U.SubFolder, U.FileCountNew, U.FileCountUpdated
                        ) AttemptQ
               ON Target.Job = AttemptQ.Job AND
                  Target.Subfolder = AttemptQ.SubFolder
        WHERE AttemptQ.Attempts > 1
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If Exists (Select * From #Tmp_FailedJobs Where SkipReset = 1)
        Begin -- <a>
            -- Post a log entry about jobs that we are not resetting
            -- Limit the logging to once every 24 hours

            Declare @skippedJob int = 0
            Declare @skippedSubfolder varchar(128)
            Declare @continue tinyint = 1
            Declare @logMessage varchar(256)

            While @continue > 0
            Begin -- <b>
                SELECT TOP 1 @skippedJob = Job,
                             @skippedSubfolder = Subfolder
                FROM #Tmp_FailedJobs
                WHERE SkipReset = 1 AND Job > @skippedJob
                ORDER BY Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @continue = 0
                Else
                Begin -- <c>
                    Set @logMessage = 'Skipping auto-reset of MyEMSL upload for job ' + Cast(@skippedJob As varchar(9))
                    If Len(@skippedSubfolder) > 0
                    Begin
                        Set @logMessage = @logMessage + ', subfolder ' + @skippedSubfolder
                    End
                    Set @logMessage = @logMessage + ' since the upload has already failed 2 or more times'

                    If @infoOnly = 0
                        Exec post_log_entry 'Error', @logMessage, 'reset_failed_myemsl_uploads', 24
                    Else
                        Print @logMessage

                End -- </c>
            End -- </b>

        End -- </a>

        -----------------------------------------------------------
        -- Flag any capture task jobs that have a DatasetArchive or ArchiveUpdate step in state 7 (Holding)
        -----------------------------------------------------------

        UPDATE #Tmp_FailedJobs
        SET SkipReset = 2,
            SkipReason = JS.Tool + ' tool is in state 7 (holding)'
        FROM #Tmp_FailedJobs Target
             INNER JOIN T_Task_Steps JS
               ON Target.Job = JS.Job AND
                  Target.Subfolder = JS.Output_Folder_Name
        WHERE JS.Tool IN ('ArchiveUpdate', 'DatasetArchive') AND
              JS.State = 7
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -----------------------------------------------------------
        -- Possibly limit the number of capture task jobs to reset
        -----------------------------------------------------------
        --

        Declare @jobCountAtStart int

        SELECT @jobCountAtStart = Count(*)
        FROM #Tmp_FailedJobs
        WHERE SkipReset = 0

        If @maxJobsToReset > 0 And @jobCountAtStart > @maxJobsToReset
        Begin

            DELETE #Tmp_FailedJobs
            WHERE SkipReset = 0 AND
                  NOT Job IN ( SELECT TOP ( @maxJobsToReset ) Job
                               FROM #Tmp_FailedJobs
                               WHERE SkipReset = 0
                               ORDER BY Job )

            Declare @verb varchar(16)
            If @infoOnly = 0
                Set @verb = 'Resetting '
            Else
                Set @verb = 'Would reset '

            Select @verb + Cast(@maxJobsToReset as varchar(9)) + ' out of ' + Cast(@jobCountAtStart as varchar(9)) + ' candidate jobs' as Reset_Message

        End

        If Exists (SELECT * FROM #Tmp_FailedJobs WHERE SkipReset = 0)
        Begin
            -----------------------------------------------------------
            -- Construct a comma-separated list of capture task jobs then call retry_myemsl_upload
            -----------------------------------------------------------
            --
            Declare @JobList varchar(max) = null

            SELECT @JobList = Coalesce(@JobList + ',' + Cast(Job as varchar(9)), Cast(Job as varchar(9)))
            FROM #Tmp_FailedJobs
            WHERE SkipReset = 0
            ORDER BY Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            exec @myError = retry_myemsl_upload @Jobs = @JobList, @infoOnly = @infoOnly, @message = @message

            -----------------------------------------------------------
            -- Post a log entry if any capture task jobs were reset
            -- Posting as an error so that it shows up in the daily error log
            -----------------------------------------------------------

            If @infoOnly = 0
            Begin
                Declare @jobCount int

                SELECT @jobCount = COUNT(*)
                FROM #Tmp_FailedJobs
                WHERE SkipReset = 0

                Set @message = 'Warning: Retrying MyEMSL upload for ' + dbo.check_plural(@jobCount, 'job ', 'jobs ') + @jobList + '; for details, see T_MyEMSL_Upload_Resets'

                exec post_log_entry 'Error', @message, 'reset_failed_myemsl_uploads'

                SELECT @message AS Message

                INSERT INTO T_MyEMSL_Upload_Resets (Job, Dataset_ID, Subfolder, Error_Message)
                SELECT Job, Dataset_ID, Subfolder, Error_Message
                FROM #Tmp_FailedJobs
                WHERE SkipReset = 0

            End
        End

        If @infoOnly <> 0
        Begin
            -- Preview the capture task jobs in #Tmp_FailedJobs
            SELECT *
            FROM #Tmp_FailedJobs
            ORDER BY Job, Subfolder
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'reset_failed_myemsl_uploads'
    END CATCH

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[reset_failed_myemsl_uploads] TO [DDL_Viewer] AS [dbo]
GO
