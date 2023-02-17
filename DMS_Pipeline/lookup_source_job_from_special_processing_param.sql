/****** Object:  StoredProcedure [dbo].[LookupSourceJobFromSpecialProcessingParam] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE LookupSourceJobFromSpecialProcessingParam
/****************************************************
**
**  Desc:   Looks up the source job defined for a new job
**          The calling procedure must create temporary table #Tmp_Source_Job_Folders
**
**      CREATE TABLE #Tmp_Source_Job_Folders (
**              Entry_ID int identity(1,1),
**              Job int NOT NULL,
**              Step int NOT NULL,
**              SourceJob int NULL,
**              SourceJobResultsFolder varchar(255) NULL,
**              SourceJob2 int NULL,
**              SourceJob2Dataset varchar(256) NULL,
**              SourceJob2FolderPath varchar(512) NULL,
**              SourceJob2FolderPathArchive varchar(512) NULL,
**              WarningMessage varchar(1024) NULL
**          )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/21/2011 mem - Initial Version
**          04/04/2011 mem - Updated to use the Special_Processing param instead of the job comment
**          04/20/2011 mem - Updated to support cases where @SpecialProcessingText contains ORDER BY
**          05/03/2012 mem - Now calling LookupSourceJobFromSpecialProcessingText to parse @SpecialProcessingText
**          05/04/2012 mem - Now passing @TagName and @AutoQueryUsed to LookupSourceJobFromSpecialProcessingText
**          07/12/2012 mem - Now looking up details for Job2 (if defined in the Special_Processing text)
**          07/13/2012 mem - Now storing SourceJob2Dataset in #Tmp_Source_Job_Folders
**          03/11/2013 mem - Now overriding @SourceJobResultsFolder if there is a problem determining the details for Job2
**          02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
    @message varchar(512)='' output,
    @PreviewSql tinyint = 0
)
As
    Set XACT_ABORT, nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @EntryID int
    Declare @Job int

    Declare @Dataset varchar(255)
    Declare @TagName varchar(12)
    Declare @SpecialProcessingText varchar(1024)

    Declare @SourceJob int
    Declare @AutoQueryUsed tinyint
    Declare @SourceJobResultsFolder varchar(255)
    Declare @SourceJobResultsFolderOverride varchar(255)
    Declare @SourceJobValid tinyint

    Declare @SourceJob2 int
    Declare @SourceJob2Dataset varchar(256)
    Declare @SourceJob2FolderPath varchar(512)
    Declare @SourceJob2FolderPathArchive varchar(512)

    Declare @AutoQuerySql nvarchar(2048)
    Declare @WarningMessage varchar(1024)
    Declare @LogMessage varchar(4096)

    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Set @message = IsNull(@message, '')
    Set @PreviewSql = IsNull(@PreviewSql, 0)

    ---------------------------------------------------
    -- Step through each entry in #Tmp_Source_Job_Folders
    ---------------------------------------------------

    Declare @continue tinyint
    Set @continue = 1
    Set @EntryID = 0
    Set @Job = 0

    While @Continue = 1 And @myError = 0
    Begin -- <a>
        SELECT TOP 1 @EntryID = Entry_ID,
                     @Job = Job
        FROM #Tmp_Source_Job_Folders
        WHERE Entry_ID > @EntryID
        ORDER BY Entry_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        IF @myRowCount = 0
            Set @Continue = 0
        Else
        Begin -- <b>

            Begin Try

                Set @CurrentLocation = 'Determining SourceJob for job ' + Convert(varchar(12), @Job)

                Set @Dataset = ''
                Set @SpecialProcessingText = ''
                Set @SourceJob = 0
                Set @AutoQueryUsed = 0
                Set @SourceJobResultsFolder = 'UnknownFolder_Invalid_SourceJob'
                Set @SourceJobResultsFolderOverride = ''
                Set @WarningMessage = ''
                Set @SourceJobValid = 0
                Set @AutoQuerySql = ''

                -------------------------------------------------
                -- Lookup the Dataset for this job
                -------------------------------------------------
                --
                SELECT @Dataset = Dataset
                FROM T_Jobs
                WHERE Job = @Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    -- Job not found
                    --
                    Set @WarningMessage = 'Job ' + Convert(varchar(12), @Job) +  ' not found in T_Jobs'
                End
                Else
                Begin

                    -- Lookup the Special_Processing parameter for this job
                    --
                    SELECT @SpecialProcessingText = Value
                    FROM dbo.GetJobParamTableLocal(@Job)
                    WHERE [Name] = 'Special_Processing'
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount = 0
                    Begin
                        Set @WarningMessage = 'Job ' + Convert(varchar(12), @Job) + ' does not have a Special_Processing entry in T_Job_Parameters'
                    End

                    If @WarningMessage = ''
                    Begin
                        If Not @SpecialProcessingText LIKE '%SourceJob:%'
                        Begin
                            Set @WarningMessage = 'Special_Processing parameter for job ' + Convert(varchar(12), @Job) + ' does not contain tag "SourceJob:0000" Or "SourceJob:Auto{Sql_Where_Clause}"'
                            execute PostLogEntry 'Debug', @WarningMessage, 'LookupSourceJobFromSpecialProcessingParam'
                        End
                    End
                End

                If @WarningMessage = ''
                Begin
                    Set @TagName = 'SourceJob'

                    Exec @myError = LookupSourceJobFromSpecialProcessingText
                                              @Job,
                                              @Dataset,
                                              @SpecialProcessingText,
                                              @TagName,
                                              @SourceJob=@SourceJob output,
                                              @AutoQueryUsed=@AutoQueryUsed output,
                                              @WarningMessage=@WarningMessage output,
                                              @PreviewSql = @PreviewSql,
                                              @AutoQuerySql = @AutoQuerySql output

                    If IsNull(@WarningMessage, '') <> ''
                    Begin
                        execute PostLogEntry 'Debug', @WarningMessage, 'LookupSourceJobFromSpecialProcessingParam'

                        -- Override @SourceJobResultsFolder with an error message; this will force the job to fail since the input folder will not be found
                        If @WarningMessage Like '%exception%'
                            Set @SourceJobResultsFolder = 'UnknownFolder_Exception_Determining_SourceJob'
                        Else
                        Begin
                            If @AutoQueryUsed <> 0
                                Set @SourceJobResultsFolder = 'UnknownFolder_AutoQuery_SourceJob_NoResults'
                        End
                    End

                End

                If @WarningMessage = ''
                Begin

                    -- Lookup the results folder for the source job
                    --
                    SELECT @SourceJobResultsFolder = IsNull([Results Folder], '')
                    FROM S_DMS_V_Analysis_Job_Info
                    WHERE Job = @SourceJob
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount = 0
                        Set @WarningMessage = 'Source Job ' + Convert(varchar(12), @Job) +  'not found in DMS'
                    Else
                        Set @SourceJobValid = 1
                End

                -- Store the results
                --
                UPDATE #Tmp_Source_Job_Folders
                SET SourceJob = @SourceJob,
                    SourceJobResultsFolder = @SourceJobResultsFolder,
                    SourceJob2 = NULL,
                    SourceJob2Dataset = NULL,
                    SourceJob2FolderPath = NULL,
                    SourceJob2FolderPathArchive = NULL,
                    WarningMessage = @WarningMessage
                WHERE Entry_ID = @EntryID


                -- Clear the warning message
                --
                Set @WarningMessage = ''
                Set @AutoQueryUsed = 0
                Set @SourceJob2 = 0
                Set @SourceJob2Dataset = ''
                Set @SourceJob2FolderPath = 'na'
                Set @SourceJob2FolderPathArchive = 'na'
                Set @AutoQuerySql = ''

                If @SourceJobValid = 1
                Begin

                    -------------------------------------------------
                    -- Check whether a 2nd source job is defined
                    -------------------------------------------------
                    --
                    Set @TagName = 'Job2'

                    Exec @myError = LookupSourceJobFromSpecialProcessingText
                                              @Job,
                                              @Dataset,
                                              @SpecialProcessingText,
                                              @TagName,
                                              @SourceJob=@SourceJob2 output,
                                              @AutoQueryUsed=@AutoQueryUsed output,
                                              @WarningMessage=@WarningMessage output,
                                              @PreviewSql = @PreviewSql,
                                              @AutoQuerySql = @AutoQuerySql output

                    If IsNull(@WarningMessage, '') <> ''
                    Begin
                        execute PostLogEntry 'Debug', @WarningMessage, 'LookupSourceJobFromSpecialProcessingParam'

                        -- Override @SourceJobResultsFolder with an error message; this will force the job to fail since the input folder will not be found
                        If @WarningMessage Like '%exception%'
                        Begin
                            Set @SourceJob2FolderPath = 'UnknownFolder_Exception_Determining_SourceJob2'
                            Set @SourceJobResultsFolderOverride =  @SourceJob2FolderPath
                        End
                        Else
                        Begin
                            If @AutoQueryUsed <> 0
                            Begin
                                Set @SourceJob2FolderPath = 'UnknownFolder_AutoQuery_SourceJob2_NoResults'
                                Set @SourceJobResultsFolderOverride =  @SourceJob2FolderPath
                            End
                        End
                    End

                End

                Set @SourceJob2 = IsNull(@SourceJob2, 0)

                If @SourceJob2 = @SourceJob
                Begin
                    Set @WarningMessage = 'Source Job 1 and Source Job 2 are identical (both ' + Convert(varchar(12), @SourceJob) + '); this is not allowed and likely indicates the Special Processing parameters for determining Job2 are incorrect'
                    Set @SourceJobResultsFolderOverride = 'UnknownFolder_Job1_and_Job2_are_both_' + Convert(varchar(12), @SourceJob)

                    Set @LogMessage = 'Auto-query used to lookup Job2 for job ' + Convert(varchar(12), @Job) + ': ' + IsNull(@AutoQuerySql, '')
                    exec PostLogEntry 'Debug', @LogMessage, 'LookupSourceJobFromSpecialProcessingParam'
                End

                If @SourceJob2 > 0 AND @WarningMessage = ''
                Begin

                    -- Lookup the results folder for @SourceJob2
                    --
                    SELECT @SourceJob2Dataset = Dataset,
                           @SourceJob2FolderPath = dbo.udfCombinePaths(dbo.udfCombinePaths([Dataset Storage Path], [Dataset]), [Results Folder]),
                           @SourceJob2FolderPathArchive = dbo.udfCombinePaths(dbo.udfCombinePaths([Archive Folder Path], [Dataset]), [Results Folder])
                    FROM S_DMS_V_Analysis_Job_Info
                    WHERE Job = @SourceJob2 And Not [Results Folder] Is Null
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount = 0
                        Set @WarningMessage = 'Source Job #2 ' + Convert(varchar(12), @SourceJob2) +  'not found in DMS, or has a null value for [Results Folder]'
                End

                If @SourceJob2 > 0 OR @WarningMessage <> ''
                Begin
                    -- Store the results
                    --
                    UPDATE #Tmp_Source_Job_Folders
                    SET SourceJob2 = @SourceJob2,
                        SourceJob2Dataset = @SourceJob2Dataset,
                        SourceJob2FolderPath = @SourceJob2FolderPath,
                        SourceJob2FolderPathArchive = @SourceJob2FolderPathArchive,
                        WarningMessage = @WarningMessage
                    WHERE Entry_ID = @EntryID
                END

                If @SourceJobResultsFolderOverride <> ''
                Begin
                    UPDATE #Tmp_Source_Job_Folders
                    SET SourceJobResultsFolder = @SourceJobResultsFolderOverride
                    WHERE Entry_ID = @EntryID
                End

            End Try
            Begin Catch
                -- Error caught; log the error, then continue with the next job
                Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'LookupSourceJobFromSpecialProcessingParam')

                exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                        @ErrorNum = @myError output, @message = @message output

                Set @SourceJobResultsFolder = 'UnknownFolder_Exception_Determining_SourceJob'
                If @WarningMessage = ''
                    Set @WarningMessage = 'Exception while determining SourceJob and/or results folder'

                UPDATE #Tmp_Source_Job_Folders
                SET SourceJob = @SourceJob,
                    SourceJobResultsFolder = @SourceJobResultsFolder,
                    WarningMessage = @WarningMessage
                WHERE Entry_ID = @EntryID

            End Catch

        End -- </b>

    End -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[LookupSourceJobFromSpecialProcessingParam] TO [DDL_Viewer] AS [dbo]
GO
