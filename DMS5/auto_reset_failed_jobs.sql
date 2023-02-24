/****** Object:  StoredProcedure [dbo].[AutoResetFailedJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AutoResetFailedJobs]
/****************************************************
**
**  Desc:
**      Looks for recently failed jobs
**      Examines the reason for the failure and will auto-reset under certain conditions
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/30/2010 mem - Initial Version
**          10/01/2010 mem - Added call to PostLogEntry when changing ManagerErrorCleanupMode for a processor
**          02/16/2012 mem - Fixed major bug that reset the state for all steps of a job to state 2, rather than only resetting the state for the running step
**                         - Fixed bug finding jobs that are running, but started over 60 minutes ago and for which the processor is reporting Stopped_Error in T_Processor_Status
**          07/25/2013 mem - Now auto-updating the settings file for MSGF+ jobs that report a comment similar to "MSGF+ skipped 99.2% of the spectra because they did not appear centroided"
**                         - Now auto-resetting MSGF+ jobs that report "Not enough free memory"
**          07/31/2013 mem - Now auto-updating the settings file for MSGF+ jobs that contain the text "None of the spectra are centroided; unable to process with MSGF+" in the comment
**                         - Now auto-resetting jobs that report "Exception generating OrgDb file"
**          04/17/2014 mem - Updated check for "None of the spectra are centroided" to be more generic
**          09/09/2014 mem - Changed DataExtractor and MSGF retries to 2
**                         - Now auto-resetting MSAlign jobs that report "Not enough free memory"
**          10/27/2014 mem - Now watching for "None of the spectra are centroided" from DTA_Refinery
**          03/27/2015 mem - Now auto-resetting ICR2LS jobs up to 15 times
**                         - Added parameter @StepToolFilter
**          11/19/2015 mem - Preventing retry of jobs with a failed DataExtractor job with a message like "7.7% of the peptides have a mass error over 6.0 Da"
**          11/19/2015 mem - Now auto-resetting jobs with a DataExtractor step reporting "Not enough free memory"
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/12/2016 mem - Now using a synonym when calling S_SetManagerErrorCleanupMode in the Manager_Control database
**          09/02/2016 mem - Switch the archive server path from \\a2 to \\adms
**          01/18/2017 mem - Auto-reset Bruker_DA_Export jobs up to 2 times
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/21/2017 mem - Add check for "An unexpected network error occurred"
**          09/05/2017 mem - Check for Mz_Refinery reporting Not enough free memory
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**
*****************************************************/
(
    @WindowHours int = 12,                -- Will look for jobs that failed within @WindowHours hours of the present time
    @infoOnly tinyint = 1,
    @StepToolFilter varchar(32) = '',    -- Optional Step Tool to filter on (must be an exact match to a tool name in T_Job_Steps)
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @Job int
    Declare @StepNumber int
    Declare @StepTool varchar(64)
    Declare @JobState int
    Declare @StepState int
    Declare @Processor varchar(128)
    Declare @Comment varchar(750)
    Declare @SettingsFile varchar(255)
    Declare @AnalysisTool varchar(64)

    Declare @NewJobState int
    Declare @NewComment varchar(750)
    Declare @NewSettingsFile varchar(255)
    Declare @SkipInfo varchar(255)

    Declare @continue tinyint

    Declare @RetryJob tinyint
    Declare @SetProcessorAutoRecover tinyint
    Declare @SettingsFileChanged tinyint

    Declare @RetryCount int
    Declare @MatchIndex int
    Declare @MatchIndexLast int
    Declare @PoundIndex int

    Declare @RetryText varchar(512)
    Declare @RetryCountText varchar(32)

    Declare @ResetReason varchar(64)
    Declare @LogMessage varchar(512)

    BEGIN TRY

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------
        --

        Set @WindowHours = Coalesce(@WindowHours, 12)
        If @WindowHours < 2
            Set @WindowHours = 2

        Set @infoOnly = Coalesce(@infoOnly, 0)

        Set @StepToolFilter = Coalesce(@StepToolFilter, '')

        Set @message = ''

        CREATE TABLE #Tmp_FailedJobs (
            Job int NOT NULL,
            Step_Number int NOT NULL,
            Step_Tool varchar(64) NOT NULL,
            Job_State int NOT NULL,
            Step_State int NOT NULL,
            Processor varchar(128) NOT NULL,
            Comment varchar(750) NOT NULL,
            Job_Finish datetime Null,
            Settings_File varchar(255) NOT NULL,
            AnalysisTool varchar(64) NOT NULL,
            NewJobState int null,
            NewStepState int null,
            NewComment varchar(750) null,
            NewSettingsFile varchar(255) null,
            ResetJob tinyint not null default 0,
            RerunAllJobSteps tinyint not null default 0
        )

        ---------------------------------------------------
        -- Populate a temporary table with jobs that failed within the last @WindowHours hours
        ---------------------------------------------------
        --
        INSERT INTO #Tmp_FailedJobs (Job, Step_Number, Step_Tool, Job_State, Step_State,
           Processor, Comment, Job_Finish, Settings_File, AnalysisTool)
        SELECT J.AJ_jobID AS Job,
               JS.Step_Number,
               JS.Step_Tool,
               J.AJ_StateID AS Job_State,
               JS.State AS Step_State,
               Coalesce(JS.Processor, '') AS Processor,
               Coalesce(J.AJ_comment, '') AS Comment,
               Coalesce(J.AJ_finish, J.AJ_Start) as Job_Finish,
               J.AJ_settingsFileName,
               Tool.AJT_toolName
        FROM T_Analysis_Job J
             INNER JOIN DMS_Pipeline.dbo.T_Job_Steps JS
         ON J.AJ_jobID = JS.Job
             INNER JOIN T_Analysis_Tool Tool
               ON J.AJ_analysisToolID = Tool.AJT_toolID
        WHERE J.AJ_StateID = 5 AND
              Coalesce(J.AJ_finish, J.AJ_Start) >= DATEADD(hour, -@WindowHours, GETDATE()) AND
              JS.State = 6 AND
              (@StepToolFilter = '' OR JS.Step_Tool = @StepToolFilter)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        ---------------------------------------------------
        -- Next look for job steps that are running, but started over 60 minutes ago and for which
        -- the processor is reporting Stopped_Error in T_Processor_Status
        ---------------------------------------------------
        --
        INSERT INTO #Tmp_FailedJobs (Job, Step_Number, Step_Tool, Job_State, Step_State,
                                     Processor, Comment, Job_Finish, Settings_File, AnalysisTool)
        SELECT J.AJ_jobID AS Job,
               JS.Step_Number,
               JS.Step_Tool,
               J.AJ_StateID AS Job_State,
               JS.State AS Step_State,
               Coalesce(JS.Processor, '') AS Processor,
               Coalesce(J.AJ_comment, '') AS Comment,
               Coalesce(J.AJ_finish, J.AJ_Start) as Job_Finish,
               J.AJ_settingsFileName,
               Tool.AJT_toolName
        FROM T_Analysis_Job J
             INNER JOIN DMS_Pipeline.dbo.T_Job_Steps JS
               ON J.AJ_jobID = JS.Job
             INNER JOIN DMS_Pipeline.dbo.T_Processor_Status ProcStatus
               ON JS.Processor = ProcStatus.Processor_Name
             INNER JOIN T_Analysis_Tool Tool
               ON J.AJ_analysisToolID = Tool.AJT_toolID
        WHERE (J.AJ_StateID = 2) AND
              (JS.State = 4) AND
              (ProcStatus.Mgr_Status = 'Stopped Error') AND
              (JS.Start <= DATEADD(hour, -1, GETDATE())) AND
              ProcStatus.Status_Date > DATEADD(minute, -30, GetDate())
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        IF EXISTS (SELECT * FROM #Tmp_FailedJobs)
        Begin -- <a>
            -- Step through the jobs and reset them if appropriate

            Set @Job = 0
            Set @continue = 1

            While @continue = 1
            Begin -- <b>

                SELECT TOP 1 @Job = Job,
                             @StepNumber = Step_Number,
                             @StepTool = Step_Tool,                -- Step tool name
                             @JobState = Job_State,
                             @StepState = Step_State,
                             @Processor = Processor,
                             @Comment = Comment,
                             @SettingsFile = Settings_File,
                             @AnalysisTool = AnalysisTool        -- Overall Job Analysis Tool Name
                FROM #Tmp_FailedJobs
                WHERE Job > @Job
                ORDER BY Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @continue = 0
                Else
                Begin -- <c>

                    Set @RetryJob = 0
                    Set @RetryCount = 0
                    Set @SetProcessorAutoRecover = 0
                    Set @SettingsFileChanged = 0
                    Set @NewSettingsFile = ''
                    Set @SkipInfo = ''

                    -- Examine the comment to determine if we've retried this job before
                    -- Need to find the last instance of '(retry'

                    Set @MatchIndexLast = 0
                    Set @MatchIndex = 999
                    While @MatchIndex > 0
                    Begin
                        Set @MatchIndex = CharIndex('(retry', @Comment, @MatchIndexLast+1)
                        If @MatchIndex > 0
                            Set @MatchIndexLast = @MatchIndex
                    End
                    Set @MatchIndex = @MatchIndexLast

                    If @MatchIndex = 0
                    Begin
                        -- Comment does not contain '(retry'
                        Set @NewComment = @Comment

                        If @NewComment LIKE '%;%'
                        Begin
                            -- Comment contains a semicolon
                            -- Remove the text after the semicolon
                            Set @MatchIndex = CharIndex(';', @NewComment)
                            If @MatchIndex > 1
                                Set @NewComment = SubString(@NewComment, 1, @MatchIndex-1)
                            Else
                                Set @NewComment = ''
                        End
                    End
                    Else
                    Begin
                        -- Comment contains '(retry'

                        If @MatchIndex > 1
                            Set @NewComment = SubString(@Comment, 1, @MatchIndex-1)
                        Else
                            Set @NewComment = ''

                        -- Determine the number of times the job has been retried
                        Set @RetryCount = 1
                        Set @RetryText = SubString(@Comment, @MatchIndex, Len(@Comment))

                        -- Find the closing parenthesis
                        Set @MatchIndex = CharIndex(')', @RetryText)
                        If @MatchIndex > 0
                        Begin
                            Set @PoundIndex = CharIndex('#', @RetryText)

                            If @PoundIndex > 0
                            Begin
                                If @MatchIndex - @PoundIndex - 1 > 0
                                Begin
                                    Set @RetryCountText = SubString(@RetryText, @PoundIndex+1, @MatchIndex - @PoundIndex - 1)
                                    Set @RetryCount = Coalesce(Try_Parse(@RetryCountText as int), @retryCount)
                                End
                            End
                        End
                    End

                    If @StepState = 6
                    Begin -- <failedJob>
                        -- Job step is failed and overall job is failed

                        If @RetryJob = 0 And @StepTool IN ('Decon2LS', 'MSGF', 'Bruker_DA_Export') And @RetryCount < 2
                            Set @RetryJob = 1

                        if @RetryJob = 0 and @StepTool = 'ICR2LS' And @RetryCount < 15
                            Set @RetryJob = 1

                        If @RetryJob = 0 And @StepTool = 'DataExtractor' And Not @Comment Like '%have a mass error over%' And @RetryCount < 2
                            Set @RetryJob = 1

                        If @RetryJob = 0 And @StepTool IN ('Sequest', 'MSGFPlus', 'XTandem', 'MSAlign') And @Comment Like '%Exception generating OrgDb file%' And @RetryCount < 2
                            Set @RetryJob = 1

                        If @RetryJob = 0 And (@StepTool LIKE 'MSGFPlus%' OR @StepTool = 'DTA_Refinery') And
                           (@Comment Like '%None of the spectra are centroided; unable to process%' OR
                            @Comment Like '%skipped % of the spectra because they did not appear centroided%' OR
                            @Comment Like '%skip % of the spectra because they do not appear centroided%'
                            )
                        Begin -- <nonCentroided>
                            -- MSGF+ job that failed due to too many profile-mode spectra
                            -- Auto-change the SettingsFile to a MSConvert version if possible.

                            Set @NewSettingsFile = ''

                            SELECT @NewSettingsFile = MSGFPlus_AutoCentroid
                            FROM T_Settings_Files
                            WHERE Analysis_Tool = @AnalysisTool AND
                                  File_Name = @SettingsFile AND
                                  Coalesce(MSGFPlus_AutoCentroid, '') <> ''

                            If Coalesce(@NewSettingsFile, '') <> ''
                            Begin

                                Set @RetryJob = 1
                                Set @SettingsFileChanged = 1

                                If @Comment Like '%None of the spectra are centroided; unable to process%'
                                    Set @SkipInfo = 'None of the spectra are centroided'
                                Else
                                Begin
                                    Set @MatchIndex = CharIndex('MSGF+ skipped', @Comment)
                                    If @MatchIndex > 0
                                        Set @SkipInfo = SubString(@Comment, @MatchIndex, Len(@Comment))
                                    Else
                                    Begin

                                        Set @MatchIndex = CharIndex('MSGF+ will likely skip', @Comment)
                                        If @MatchIndex > 0
                                            Set @SkipInfo = SubString(@Comment, @MatchIndex, Len(@Comment))
                                        Else
                                            Set @SkipInfo = 'MSGF+ skipped ??% of the spectra because they did not appear centroided'

                                    End
                                End
                            End
                        End -- </nonCentroided>

                        If @RetryJob = 0 And @StepTool IN ('MSGFPlus', 'MSGFPlus_IMS', 'MSAlign', 'MSAlign_Histone', 'DataExtractor', 'Mz_Refinery') And @Comment Like '%Not enough free memory%' And @RetryCount < 10
                        Begin
                            Print 'Reset ' + Cast(@Job as varchar(9))
                            Set @RetryJob = 1
                        End

                        If @RetryJob = 0 And @RetryCount < 5
                        Begin
                            -- Check for file copy errors from the Archive
                            If @Comment Like '%Error copying file \\adms%' Or
                               @Comment Like '%File not found: \\adms%' Or
                               @Comment Like '%Error copying %dta.zip%' Or
                               @Comment Like '%Source dataset file file not found%'
                                Set @RetryJob = 1

                        End

                        If @RetryJob = 0 And @RetryCount < 5
                        Begin
                            -- Check for network errors
                            If @Comment Like '%unexpected network error occurred%'
                                Set @RetryJob = 1

                        End
                    End -- </failedJob>

                    If @StepState = 4
                    Begin
                        -- Job is still running, but processor has an error (likely a flagfile)
                        -- This likely indicates an out-of-memory error

                        If @StepTool In ('DataExtractor', 'MSGF') And @RetryCount < 5
                            Set @RetryJob = 1

                        If @RetryJob = 1
                            Set @SetProcessorAutoRecover = 1
                    End

                    If @RetryJob = 1
                    Begin -- <retryJob>
                        Set @NewComment = RTrim(@NewComment)

                        If @SettingsFileChanged = 1
                        Begin
                            -- Note: do not append a semicolon because if the job fails again in the future, then the text after the semicolon may get auto-removed
                            If Len(@NewComment) > 0
                                Set @NewComment = @NewComment + ', '

                            Set @NewComment = @NewComment + 'Auto-switched settings file from ' + @SettingsFile + ' (' + @SkipInfo + ')'
                        End
                        Else
                        Begin
                            If Len(@NewComment) > 0
                                Set @NewComment = @NewComment + ' '

                            Set @NewComment = @NewComment + '(retry ' + @StepTool

                            Set @RetryCount = @RetryCount + 1
                            if @RetryCount = 1
                                Set @NewComment = @NewComment + ')'
                            Else
                                Set @NewComment = @NewComment + ' #' + Convert(varchar(2), @RetryCount) + ')'
                        End

                        If @StepState = 6
                        Begin
                            Set @NewJobState = 1

                            UPDATE #Tmp_FailedJobs
                            SET NewJobState = @NewJobState,
                                NewStepState = @StepState,
                                NewComment = @NewComment,
                                ResetJob = 1,
                                NewSettingsFile = @NewSettingsFile,
                                RerunAllJobSteps = @SettingsFileChanged
                            WHERE Job = @Job

                            Set @ResetReason = 'job step failed in the last ' + convert(varchar(12), @WindowHours) + ' hours'
                        End

                        If @StepState = 4
                        Begin
                            Set @NewJobState = @JobState

                            UPDATE #Tmp_FailedJobs
                            SET NewJobState = @NewJobState,
                                NewStepState = 2,
                                NewComment = @NewComment,
                               ResetJob = 1
                            WHERE Job = @Job

                            If @infoOnly = 0
                            Begin
                                -- Reset the step back to state 2=Enabled
                                UPDATE DMS_Pipeline.dbo.T_Job_Steps
                                SET State = 2
                                WHERE Job = @Job And Step_Number = @StepNumber
                            End

                            Set @ResetReason = 'job step in progress but manager reports "Stopped Error"'
                        End

                        If @infoOnly = 0
                        Begin

                            If @SettingsFileChanged = 1
                            Begin
                                -- The settings file for this job has changed, thus we must re-generate the job in the pipeline DB
                                -- Note that deletes auto-cascade from T_Jobs to T_Job_Steps, T_Job_Parameters, and T_Job_Step_Dependencies
                                --
                                DELETE FROM DMS_Pipeline.dbo.T_Jobs
                                WHERE Job = @Job

                                UPDATE T_Analysis_Job
                                SET AJ_settingsFileName = @NewSettingsFile
                                WHERE AJ_JobID = @Job

                            End

                            -- Update the JobState and Comment in T_Analysis_Job
                            UPDATE T_Analysis_Job
                            SET AJ_StateID = @NewJobState,
                                AJ_Comment = @NewComment
                            WHERE AJ_JobID = @Job

                            Set @LogMessage = 'Auto-reset job ' + Convert(varchar(12), @job) + '; ' + @ResetReason + '; ' + @NewComment

                            Exec PostLogEntry 'Warning', @LogMessage, 'AutoResetFailedJobs'
                        End

                        If @SetProcessorAutoRecover = 1
                        Begin
                            If @infoOnly = 0
                            Begin
                                Set @LogMessage = @Processor + ' reports "Stopped Error"; setting ManagerErrorCleanupMode to 1 in the Manager_Control DB'
                                Exec PostLogEntry 'Warning', @LogMessage, 'AutoResetFailedJobs'

                                -- Call ProteinSeqs.Manager_Control.dbo.SetManagerErrorCleanupMode
                                Exec S_SetManagerErrorCleanupMode @ManagerList = @Processor, @CleanupMode = 1
                            End
                            Else
                                print 'Exec S_SetManagerErrorCleanupMode @ManagerList = @Processor, @CleanupMode = 1'
                        End

                    End     -- </retryJob>
                End -- </c>


            End -- </b>


            If @infoOnly <> 0
                SELECT *
                FROM #Tmp_FailedJobs
                ORDER BY Job


        End -- </a>

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AutoResetFailedJobs'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AutoResetFailedJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AutoResetFailedJobs] TO [Limited_Table_Write] AS [dbo]
GO
