/****** Object:  StoredProcedure [dbo].[CloneAnalysisJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CloneAnalysisJobs]
/****************************************************
**
**  Desc:
**      Clone a series of related analysis jobs to create new jobs
**      with a new parameter file, new settings file, and/or new protein collection list
**
**      The source jobs must all have the same parameter file and settings file (this is a safety feature)
**      The source jobs do not have to use the same protein collection
**
**      If @newProteinCollectionList is empty, each new job will have the same protein collection as the old job
**      If @newProteinCollectionList is not empty, all new jobs will have the same protein collection
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/12/2016 mem - Initial Release
**          07/19/2016 mem - Add parameter @allowDuplicateJob
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/12/2018 mem - Send @maxLength to AppendToText
**          07/29/2022 mem - Use Coalesce instead of IsNull
**
*****************************************************/
(
    @sourceJobs varchar(4000),                       -- Comma-separated list of jobs to copy
    @newParamFileName varchar(255) = '',
    @newSettingsFileName varchar(255) = '',
    @newProteinCollectionList varchar(2000) = '',
    @supersedeOldJob tinyint = 0,                    -- When 1, change the state of old jobs to 14
    @updateOldJobComment tinyint = 1,                -- When 1, add the new job number to the old job comment
    @allowDuplicateJob tinyint = 0,                  -- When 1, allow the new jobs to be duplicates of the old jobs (useful for testing a new version of a tool or updated .UIMF)
    @infoOnly tinyint = 1,
    @message varchar(256) = '' output
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @result int
    Declare @newJobIdStart int
    Declare @jobCount int
    Declare @jobCountCompare int

    Declare @mostCommonParamFile varchar(255)
    Declare @mostCommonSettingsFile varchar(255)

    Declare @errorMessage varchar(512)


    BEGIN TRY

        -----------------------------------------
        -- Validate the inputs
        -----------------------------------------

        Set @sourceJobs = Coalesce(@sourceJobs, '')
        Set @newParamFileName = LTrim(RTrim(Coalesce(@newParamFileName, '')))
        Set @newSettingsFileName = LTrim(RTrim(Coalesce(@newSettingsFileName, '')))
        Set @newProteinCollectionList = LTrim(RTrim(Coalesce(@newProteinCollectionList, '')))

        Set @supersedeOldJob = Coalesce(@supersedeOldJob, 0)
        Set @updateOldJobComment = Coalesce(@updateOldJobComment, 1)
        Set @infoOnly = Coalesce(@infoOnly, 1)

        Set @message = ''

        If @sourceJobs = ''
        Begin
            Set @message = '@sourceJobs cannot both be empty'
            Goto Done
        End

        If @newProteinCollectionList <> ''
        Begin
            -- Validate @newProteinCollectionList

            exec @result = S_ValidateAnalysisJobProteinParameters
                                @organismName = 'None',
                                @ownerPRN = 'H09090911',
                                @organismDBFileName = 'na',
                                @protCollNameList = @newProteinCollectionList,
                                @protCollOptionsList = 'seq_direction=forward,filetype=fasta',
                                @message = @message OUTPUT

            if @result <> 0
            begin
                If Coalesce(@message, '') = ''
                    Set @message = 'Protein collection list validation error, result code ' + Cast(@result as varchar(9))

                Goto Done
            end

        End

        -----------------------------------------
        -- Create some temporary tables
        -----------------------------------------
        --
        CREATE TABLE #Tmp_SourceJobs (
            JobId int NOT NULL,
            Valid tinyint NOT NULL,
            StateID int NOT NULL,
            RowNum int NOT NULL
        )

        CREATE TABLE #Tmp_NewJobInfo(
            JobId_Old int NOT NULL,
            JobId_New int NOT NULL,
            AJ_batchID int NOT NULL,
            AJ_priority int NOT NULL,
            AJ_analysisToolID int NOT NULL,
            AJ_parmFileName varchar(255) NOT NULL,
            AJ_settingsFileName varchar(255) NULL,
            AJ_organismDBName varchar(128) NULL,
            AJ_organismID int NOT NULL,
            AJ_datasetID int NOT NULL,
            AJ_comment varchar(255) NULL,
            AJ_owner varchar(64) NULL,
            AJ_proteinCollectionList varchar(2000) NULL,
            AJ_proteinOptionsList varchar(256) NOT NULL,
            AJ_requestID int NOT NULL,
            AJ_propagationMode smallint NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_NewJobInfo ON #Tmp_NewJobInfo (JobId_New)

        -----------------------------------------
        -- Find the source jobs
        -----------------------------------------
        --
        INSERT INTO #Tmp_SourceJobs (JobId, Valid, StateID, RowNum)
        SELECT Value, 0 as Valid, 0 AS StateID, Row_Number() Over (Order By Value) as RowNum
        FROM dbo.udfParseDelimitedIntegerList(@sourceJobs, ',')
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If Not Exists (SELECT * FROM #Tmp_SourceJobs)
        Begin
            Set @message = '@sourceJobs did not have any valid Job IDs: ' + @sourceJobs
            Goto Done
        End

        -----------------------------------------
        -- Validate the source job IDs
        -----------------------------------------
        --
        UPDATE #Tmp_SourceJobs
        SET Valid = 1,
            StateID = J.AJ_StateID
        FROM #Tmp_SourceJobs
             INNER JOIN T_Analysis_Job J
               ON #Tmp_SourceJobs.JobID = J.AJ_JobID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If Exists (SELECT * FROM #Tmp_SourceJobs WHERE Valid = 0)
        Begin
            Set @message = 'One or more Job IDs are invalid'
            Select *
            FROM #Tmp_SourceJobs
            Order By JobId

            Goto Done
        End

        If Exists (SELECT * FROM #Tmp_SourceJobs WHERE NOT StateID IN (4, 14))
        Begin
            Set @message = 'One or more Job IDs are not in state 4 or 14'

            SELECT *
            FROM #Tmp_SourceJobs
            Order By StateID, JobId

            Goto Done
        End

        -----------------------------------------
        -- Count the source jobs
        -----------------------------------------
        --
        SELECT @jobCount = COUNT(*)
        FROM #Tmp_SourceJobs

        -----------------------------------------
        -- Validate that all the source jobs have the same parameter file
        -----------------------------------------
        --
        SELECT TOP 1 @mostCommonParamFile = AJ_parmFileName,
                     @jobCountCompare = NumJobs
        FROM ( SELECT J.AJ_parmFileName AS AJ_parmFileName,
                      COUNT(*) AS NumJobs
               FROM #Tmp_SourceJobs
                    INNER JOIN T_Analysis_Job J
                      ON #Tmp_SourceJobs.JobID = J.AJ_JobID
               GROUP BY J.AJ_parmFileName ) StatsQ
        ORDER BY NumJobs DESC
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @jobCountCompare < @jobCount
        Begin
            Set @message = 'The source jobs must all have the same parameter file'

            SELECT JobId,
                   Valid,
                   J.AJ_parmFileName,
                   J.AJ_settingsFileName,
                   CASE
       WHEN J.AJ_parmFileName = @mostCommonParamFile THEN ''
                       ELSE 'Mismatched param file'
                   END AS Warning
            FROM #Tmp_SourceJobs
                 INNER JOIN T_Analysis_Job J
           ON #Tmp_SourceJobs.JobID = J.AJ_JobID
            ORDER BY CASE WHEN J.AJ_parmFileName = @mostCommonParamFile THEN 1 ELSE 0 END, J.AJ_JobID

            Goto Done
        End

        -----------------------------------------
        -- Validate that all the source jobs have the same settings file
        -----------------------------------------
        --
        SELECT TOP 1 @mostCommonSettingsFile = AJ_settingsFileName,
                     @jobCountCompare = NumJobs
        FROM ( SELECT J.AJ_settingsFileName AS AJ_settingsFileName,
                      COUNT(*) AS NumJobs
               FROM #Tmp_SourceJobs
                    INNER JOIN T_Analysis_Job J
                      ON #Tmp_SourceJobs.JobID = J.AJ_JobID
               GROUP BY J.AJ_settingsFileName ) StatsQ
        ORDER BY NumJobs DESC
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @jobCountCompare < @jobCount
        Begin
            Set @message = 'The source jobs must all have the same settings file'

            SELECT JobId,
                   Valid,
                   J.AJ_parmFileName,
                   J.AJ_settingsFileName,
                   CASE
                       WHEN J.AJ_settingsFileName = @mostCommonSettingsFile THEN ''
                       ELSE 'Mismatched settings file'
                   END AS Warning
            FROM #Tmp_SourceJobs
                 INNER JOIN T_Analysis_Job J
                   ON #Tmp_SourceJobs.JobID = J.AJ_JobID
            ORDER BY CASE WHEN J.AJ_settingsFileName = @mostCommonSettingsFile THEN 1 ELSE 0 END, J.AJ_JobID

            Goto Done
        End

        -----------------------------------------
        -- If @newProteinCollectionList is not empty,
        -- make sure that it was not in use by any of the old jobs
        -----------------------------------------
        --
        If @newProteinCollectionList <> ''
        Begin
            If Exists ( SELECT *
                        FROM #Tmp_SourceJobs
                             INNER JOIN T_Analysis_Job J
                               ON #Tmp_SourceJobs.JobID = J.AJ_JobID
                        WHERE J.AJ_proteinCollectionList = @newProteinCollectionList )
            Begin
                Set @message = 'ProteinCollectionList was used by one or more of the existing jobs; not cloning the jobs: ' + @newProteinCollectionList
                Goto Done
            End
        End

        -----------------------------------------
        -- Make sure that something is changing
        -----------------------------------------
        --
        If @newParamFileName = '' And @newSettingsFileName = '' And @newProteinCollectionList = ''
        Begin
            Set @message = '@newParamFileName, @newSettingsFileName, and @newProteinCollectionList cannot all be empty'
            Goto Done
        End
        Else
        Begin
            If @allowDuplicateJob = 0
            Begin
                If @newParamFileName <> '' And @mostCommonParamFile = @newParamFileName
                Begin
                    Set @message = 'The new parameter file name matches the old name; not cloning the jobs: ' + @newParamFileName
                    Goto Done
                End

                If @newSettingsFileName <> '' And @mostCommonSettingsFile = @newSettingsFileName
                Begin
                    Set @message = 'The new settings file name matches the old name; not cloning the jobs: ' + @newSettingsFileName
                    Goto Done
                End
            End
        End

        -----------------------------------------
        -- Start a transaction
        -----------------------------------------
        --
        Declare @CloneJobs varchar(24) = 'Clone jobs'

        Begin Tran @CloneJobs

        -----------------------------------------
        -- Determine the starting JobID for the new jobs
        -----------------------------------------
        --

        If @infoOnly = 0
        Begin
            -- Reserve a block of Job Ids
            -- This procedure populates temporary table #TmpNewJobIDs

            CREATE TABLE #TmpNewJobIDs (
                ID int NOT NULL
            )

            EXEC GetNewJobIDBlock @JobCount = @jobCount, @note = 'CloneAnalysisJobs'

            SELECT @newJobIdStart = Min(Id)
            FROM #TmpNewJobIDs

            DROP TABLE #TmpNewJobIDs
        END
        ELSE
        Begin
            -- Pretend that the new Jobs will start at job 100,000,000
            --
            Set @newJobIdStart = 100000000
        End

        -----------------------------------------
        -- Populate #Tmp_NewJobInfo with the new job info
        -----------------------------------------
        --
        INSERT INTO #Tmp_NewJobInfo( JobId_Old,
                                     JobId_New,
                                     AJ_batchID,
                                     AJ_priority,
                                     AJ_analysisToolID,
                                     AJ_parmFileName,
                                     AJ_settingsFileName,
                                     AJ_organismDBName,
                                     AJ_organismID,
                                     AJ_datasetID,
                                     AJ_comment,
                                     AJ_owner,
                                     AJ_proteinCollectionList,
                                     AJ_proteinOptionsList,
                                     AJ_requestID,
                                     AJ_propagationMode )
        SELECT SrcJobs.JobId,
               @newJobIdStart + SrcJobs.RowNum AS JobId_New,
               0 AS AJ_batchID,
               J.AJ_priority,
               J.AJ_analysisToolID,
               CASE
                   WHEN Coalesce(@newParamFileName, '') = '' THEN J.AJ_parmFileName
                   ELSE @newParamFileName
               END AS AJ_parmFileName,
               CASE
                   WHEN Coalesce(@newSettingsFileName, '') = '' THEN J.AJ_settingsFileName
                   ELSE @newSettingsFileName
               END AS AJ_settingsFileName,
               J.AJ_organismDBName,
               J.AJ_organismID,
               J.AJ_datasetID,
               'Rerun of job ' + CAST(J.AJ_jobID AS varchar(9)) AS AJ_comment,
               J.AJ_owner,
               CASE
                   WHEN Coalesce(@newProteinCollectionList, '') = '' THEN J.AJ_proteinCollectionList
                   ELSE @newProteinCollectionList
               END AS AJ_proteinCollectionList,
               J.AJ_proteinOptionsList,
               J.AJ_requestID,
               J.AJ_propagationMode
        FROM T_Analysis_Job J
             INNER JOIN #Tmp_SourceJobs SrcJobs
               ON J.AJ_jobID = SrcJobs.JobId
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        IF @infoOnly = 0
        BEGIN

            -----------------------------------------
            -- Make the new jobs
            -----------------------------------------
            --
            INSERT INTO T_Analysis_Job (
                AJ_JobId, AJ_batchID, AJ_priority, AJ_Created, AJ_analysisToolID, AJ_parmFileName, AJ_settingsFileName, AJ_organismDBName,
                AJ_organismID, AJ_datasetID, AJ_comment, AJ_owner, AJ_StateID, AJ_proteinCollectionList, AJ_proteinOptionsList,
                AJ_requestID, AJ_propagationMode)
            SELECT
                JobId_New, AJ_batchID, AJ_priority, GetDate(), AJ_analysisToolID, AJ_parmFileName, AJ_settingsFileName, AJ_organismDBName,
                AJ_organismID, AJ_datasetID, AJ_comment, AJ_owner, 1 AS AJ_StateID, AJ_proteinCollectionList, AJ_proteinOptionsList,
                AJ_requestID, AJ_propagationMode
            FROM #Tmp_NewJobInfo
            ORDER BY JobId_New
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount


            If @supersedeOldJob > 0 Or @updateOldJobComment > 0
            Begin
                Declare @action varchar(24)

                If @supersedeOldJob = 0
                    Set @action = 'compare to job'
                Else
                    Set @action = 'superseded by job'

                UPDATE T_Analysis_Job
                SET AJ_Comment = CASE
                                     WHEN @updateOldJobComment = 0 THEN Target.AJ_Comment
                                     ELSE dbo.AppendToText(Target.AJ_Comment, @action + ' ' + Cast(Src.JobId_New AS varchar(9)), 0, '; ', 512)
                                 END,
                    AJ_StateID = CASE
                                     WHEN @supersedeOldJob = 0 THEN Target.AJ_StateID
                                     ELSE 14
                                 END
                FROM T_Analysis_Job Target
                     INNER JOIN #Tmp_NewJobInfo Src
                       ON Target.AJ_JobID = Src.JobId_Old
            End

        END
        ELSE
        BEGIN
            SELECT *
            FROM #Tmp_NewJobInfo
            ORDER BY JobId_New
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        Commit Tran


    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @errorMessage output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'CloneAnalysisJobs'
    END CATCH

Done:

    If @message <> ''
    Begin
        Select @message as Message
    End

    If @errorMessage <> ''
    Begin
        Select @errorMessage as ErrorMessage
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CloneAnalysisJobs] TO [DDL_Viewer] AS [dbo]
GO
