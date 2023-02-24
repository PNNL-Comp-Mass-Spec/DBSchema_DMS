/****** Object:  StoredProcedure [dbo].[create_predefined_analysis_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_predefined_analysis_jobs]
/****************************************************
**
**  Desc: Schedules analysis jobs for dataset according to defaults
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/29/2005 grk - Supersedes "ScheduleDefaultAnalyses"
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased sized of param file name
**          06/01/2006 grk - Fixed calling sequence to add_update_analysis_job
**          03/15/2007 mem - Updated call to add_update_analysis_job (Ticket #394)
**                         - Replaced processor name with associated processor group (Ticket #388)
**          02/29/2008 mem - Added optional parameter @callingUser; If provided, then will call alter_event_log_entry_user (Ticket #644)
**          04/11/2008 mem - Now passing @RaiseErrorMessages to evaluate_predefined_analysis_rules
**          05/14/2009 mem - Added parameters @AnalysisToolNameFilter, @ExcludeDatasetsNotReleased, and @infoOnly
**          07/22/2009 mem - Improved error reporting for non-zero return values from evaluate_predefined_analysis_rules
**          07/12/2010 mem - Expanded protein Collection fields and variables to varchar(4000)
**          08/26/2010 grk - This was cloned from schedule_predefined_analysis_jobs; added try-catch error handling
**          08/26/2010 mem - Added output parameter @JobsCreated
**          02/16/2011 mem - Added support for Propagation Mode (aka Export Mode)
**          04/11/2011 mem - Updated call to add_update_analysis_job
**          04/26/2011 mem - Now sending @PreventDuplicatesIgnoresNoExport = 0 to add_update_analysis_job
**          05/03/2012 mem - Added support for the Special Processing field
**          08/02/2013 mem - Removed extra semicolon in status message
**          06/24/2015 mem - Now passing @infoOnly to add_update_analysis_job
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/21/2016 mem - Log errors in post_log_entry
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          08/29/2018 mem - Tabs to spaces
**          03/31/2021 mem - Expand @organismName and @organismDBName to varchar(128)
**          06/14/2022 mem - Send procedure name to post_log_entry
**          06/30/2022 mem - Rename parameter file column
**          06/30/2022 mem - Rename parameter file argument
**          01/27/2023 mem - Rename dataset argument to @datasetName
**                         - Rename columns in temp table #JX
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(128),
    @callingUser varchar(128) = '',
    @analysisToolNameFilter varchar(128) = '',      -- Optional: if not blank, then only considers predefines that match the given tool name (can contain wildcards)
    @excludeDatasetsNotReleased tinyint = 1,        -- When non-zero, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
    @preventDuplicateJobs tinyint = 1,              -- When non-zero, will not create new jobs that duplicate old jobs
    @infoOnly tinyint = 0,
    @message VARCHAR(max) output,
    @jobsCreated int = 0 output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @ErrorMessage varchar(512)
    Declare @NewMessage varchar(512)
    Declare @logMessage varchar(512)

    Declare @CreateJob tinyint = 1
    Declare @JobFailCount int = 0
    Declare @JobFailErrorCode int = 0

    Set @AnalysisToolNameFilter = IsNull(@AnalysisToolNameFilter, '')
    Set @ExcludeDatasetsNotReleased = IsNull(@ExcludeDatasetsNotReleased, 1)
    Set @PreventDuplicateJobs = IsNull(@PreventDuplicateJobs, 1)
    Set @infoOnly = IsNull(@infoOnly, 0)

    BEGIN TRY

    ---------------------------------------------------
    -- Temporary job holding table to receive created jobs
    -- This table is populated in evaluate_predefined_analysis_rules
    ---------------------------------------------------

    CREATE TABLE #JX (
        predefine_id int,
        dataset varchar(128),
        priority varchar(8),
        analysisToolName varchar(64),
        paramFileName varchar(255),
        settingsFileName varchar(128),
        organismDBName varchar(128),
        organismName varchar(128),
        proteinCollectionList varchar(4000),
        proteinOptionsList varchar(256),
        ownerUsername varchar(128),
        comment varchar(128),
        associatedProcessorGroup varchar(64),
        numJobs int,
        propagationMode tinyint,
        specialProcessing varchar(512),
        ID int IDENTITY (1, 1) NOT NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Could not create temporary table'
        RAISERROR (@message, 11, 10)
    End

    ---------------------------------------------------
    -- Populate the job holding table (#JX)
    ---------------------------------------------------
    Declare @result int

    exec @result = evaluate_predefined_analysis_rules @datasetName, 'Export Jobs', @message output, @RaiseErrorMessages=0, @ExcludeDatasetsNotReleased=@ExcludeDatasetsNotReleased
    --
    If @result <> 0
    Begin
        Set @ErrorMessage = 'evaluate_predefined_analysis_rules returned error code ' + Convert(varchar(12), @result)

        If Not IsNull(@message, '') = ''
            Set @ErrorMessage = @ErrorMessage + '; ' + @message

        Set @message = @ErrorMessage
        RAISERROR (@message, 11, 11)
    End

    ---------------------------------------------------
    -- Cycle through the job holding table and
    -- make jobs for each entry
    ---------------------------------------------------

    Declare @instrumentClass varchar(32)
    Declare @priority int
    Declare @analysisToolName varchar(64)
    Declare @paramFileName varchar(255)
    Declare @settingsFileName varchar(255)
    Declare @organismName varchar(128)
    Declare @organismDBName varchar(128)
    Declare @proteinCollectionList varchar(4000)
    Declare @proteinOptionsList varchar(256)
    Declare @comment varchar(128)
    Declare @propagationMode tinyint
    Declare @propagationModeText varchar(24)
    Declare @specialProcessing varchar(512)

    Declare @job varchar(32)
    Declare @ownerUsername varchar(32)

    Declare @associatedProcessorGroup varchar(64)
    Set @associatedProcessorGroup = ''

    -- keep track of how many jobs have been scheduled
    --
    Set @jobsCreated = 0

    Declare @done tinyint
    Set @done = 0

    Declare @currID int
    Set @currID = 0

    While @done = 0 and @myError = 0
    Begin -- <a>
        ---------------------------------------------------
        -- get parameters for next job in table
        ---------------------------------------------------
        SELECT TOP 1
            @priority = priority,
            @analysisToolName = analysisToolName,
            @paramFileName = paramFileName,
            @settingsFileName = settingsFileName,
            @organismDBName = organismDBName,
            @organismName = organismName,
            @proteinCollectionList = proteinCollectionList,
            @proteinOptionsList = proteinOptionsList,
            @ownerUsername = ownerUsername,
            @comment = comment,
            @associatedProcessorGroup = associatedProcessorGroup,
            @propagationMode = propagationMode,
            @specialProcessing = specialProcessing,
            @currID = ID
        FROM #JX
        WHERE ID > @currID
        ORDER BY ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Evaluate terminating conditions
        ---------------------------------------------------
        --
        If @myError <> 0 OR @myRowCount <> 1
        Begin
            Set @done = 1
        End
        Else
        Begin -- <b>

            If @AnalysisToolNameFilter = ''
            Begin
                Set @CreateJob = 1
            End
            Else
            Begin
                If @AnalysisToolName Like @AnalysisToolNameFilter
                Begin
                    Set @CreateJob = 1
                End
                Else
                Begin
                    Set @CreateJob = 0
                End
            End

            If IsNull(@propagationMode, 0) = 0
            Begin
                Set @propagationModeText = 'Export'
            End
            Else
            Begin
                Set @propagationModeText = 'No Export'
            End

            If @CreateJob <> 0
            Begin -- <c>

                If @infoOnly <> 0
                Begin
                    Print ''
                    Print 'Call add_update_analysis_job for dataset ' + @datasetName + ' and tool ' + @analysisToolName + '; param file: ' + IsNull(@paramFileName, '') + '; settings file: ' + IsNull(@settingsFileName, '')
                End

                ---------------------------------------------------
                -- create the job
                ---------------------------------------------------
                execute @result = add_update_analysis_job
                            @datasetName = @datasetName,
                            @priority = @priority,
                            @toolName = @analysisToolName,
                            @paramFileName = @paramFileName,
                            @settingsFileName = @settingsFileName,
                            @organismName = @organismName,
                            @protCollNameList = @proteinCollectionList,
                            @protCollOptionsList = @proteinOptionsList,
                            @organismDBName = @organismDBName,
                            @ownerUsername = @ownerUsername,
                            @comment = @comment,
                            @associatedProcessorGroup = @associatedProcessorGroup,
                            @propagationMode = @propagationModeText,
                            @stateName = 'new',
                            @job = @job output,
                            @mode = 'add',
                            @message = @NewMessage output,
                            @callingUser = @callingUser,
                            @PreventDuplicateJobs = @PreventDuplicateJobs,
                            @PreventDuplicatesIgnoresNoExport = 0,
                            @specialProcessing = @specialProcessing,
                            @SpecialProcessingWaitUntilReady = 1,
                            @infoOnly = @infoOnly

                -- If there was an error creating the job, remember it
                -- otherwise bump the job count
                --
                If @result = 0
                Begin
                    If @infoOnly = 0
                    Begin
                        Set @jobsCreated = @jobsCreated + 1
                    End
                End
                Else
                Begin -- <d>
                    If @message = ''
                    Begin
                        Set @message = @NewMessage
                    End
                    Else
                    Begin
                        Set @message = @message + '; ' + @NewMessage
                    End

                    -- ResultCode 52500 means a duplicate job exists; that error can be ignored
                    If @result <> 52500
                    Begin -- <e>
                        -- Append the @result ID to @message
                        -- Increment @JobFailCount, but keep trying to create the other predefined jobs for this dataset
                        Set @JobFailCount = @JobFailCount + 1
                        If @JobFailErrorCode = 0
                            Set @JobFailErrorCode = @result

                        Set @message = @message + ' [' + convert(varchar(12), @result) + ']'

                        Set @logMessage = @NewMessage

                        If CharIndex(@datasetName, @logMessage) < 1
                        Begin
                            Set @logMessage = @logMessage + '; Dataset ' + @datasetName + ', '
                        End
                        Else
                        Begin
                            Set @logMessage = @logMessage + ';'
                        End

                        Set @logMessage = @logMessage + @analysisToolName

                        exec post_log_entry 'Error', @logMessage, 'create_predefined_analysis_jobs'
                    End -- </e>

                End -- </d>

            End -- </c>
        End -- </b>

    End -- </b>

    ---------------------------------------------------
    -- Construct the summary message
    ---------------------------------------------------
    --
    Set @NewMessage = 'Created ' + convert(varchar(12), @jobsCreated) + ' job'
    If @jobsCreated <> 1
        Set @NewMessage = @NewMessage + 's'

    If @message <> ''
    Begin
        -- @message might look like this: Dataset rating (-10) does not allow creation of jobs: 47538_Pls_FF_IGT_23_25Aug10_Andromeda_10-07-10
        -- If it does, update @message to remove the dataset name

        Set @message = Replace(@message, 'does not allow creation of jobs: ' + @datasetName, 'does not allow creation of jobs')

        Set @NewMessage = @NewMessage + '; ' + @message
    End

    Set @message = @NewMessage

    If @JobFailCount > 0 and @myError = 0
    Begin
        If @JobFailErrorCode <> 0
        Begin
            Set @myError = @JobFailErrorCode
        End
        Else
        Begin
            Set @myError = 2
        End
    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        Exec post_log_entry 'Error', @message, 'create_predefined_analysis_jobs'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_predefined_analysis_jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[create_predefined_analysis_jobs] TO [Limited_Table_Write] AS [dbo]
GO
