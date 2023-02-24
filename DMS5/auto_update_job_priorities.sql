/****** Object:  StoredProcedure [dbo].[auto_update_job_priorities] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[auto_update_job_priorities]
/****************************************************
**
**  Desc:
**      Look for groups of jobs with the default priority (3)
**      and possibly auto-update them to priority 4
**
**      The reason for doing this is to allow certain managesr
**      to preferentially process jobs with priorities 1 through 3
**      and predefined jobs, plus manually created small batches of jobs
**      will have priority 3
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/04/2017 mem - Initial version
**          07/29/2022 mem - No longer filter out null parameter file or settings file names since neither column allows null values
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @infoOnly tinyint = 1,
    @message varchar(128) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @activeStepThreshold int = 25
    Declare @longRunningThreshold int = 10

    ----------------------------------------------
    -- Validate the Inputs
    ----------------------------------------------
    --
    Set @infoOnly = Coalesce(@infoOnly, 0)
    Set @message = ''

    ----------------------------------------------
    -- Create temporary tables
    ----------------------------------------------
    --
    CREATE TABLE #Tmp_ProteinCollectionJobs (
        ParamFile varchar(255) NOT NULL,
        SettingsFile varchar(255) NOT NULL,
        ProteinCollectionList varchar(2000) NOT NULL
    )

    CREATE TABLE #Tmp_LegacyOrgDBJobs (
        ParamFile varchar(255) NOT NULL,
        SettingsFile varchar(255) NOT NULL,
        OrganismDBName varchar(128) NOT NULL,
    )

    CREATE TABLE #Tmp_Batches (
        BatchID int NOT NULL
    )

    CREATE TABLE #Tmp_JobsToUpdate (
        Job int NOT NULL,
        Old_Priority smallint NOT NULL,
        New_Priority smallint NOT NULL,
        Ignored tinyint NOT NULL,
        Source varchar(256) NULL
    )

    CREATE CLUSTERED INDEX #IX_Tmp_DatasetsToUpdate ON #Tmp_JobsToUpdate (Job)

    ----------------------------------------------
    -- Find candidate jobs to update
    ----------------------------------------------

    -- Active jobs with similar settings (using protein collections)
    --
    INSERT INTO #Tmp_ProteinCollectionJobs (ParamFile, SettingsFile, ProteinCollectionList)
    SELECT AJ_parmFileName,
           AJ_settingsFileName,
           AJ_proteinCollectionList
    FROM T_Analysis_Job
    WHERE AJ_StateID IN (1, 2) AND
          AJ_priority = 3 AND
          AJ_batchID > 0 AND
          AJ_organismDBName = 'na' AND
          NOT AJ_proteinCollectionList IS NULL
    GROUP BY AJ_parmFileName, AJ_settingsFileName, AJ_proteinCollectionList
    HAVING COUNT(*) > @activeStepThreshold
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    -- Active jobs with similar settings (using organism DBs)
    --
    INSERT INTO #Tmp_LegacyOrgDBJobs (ParamFile, SettingsFile, OrganismDBName)
    SELECT AJ_parmFileName,
           AJ_settingsFileName,
           AJ_organismDBName
    FROM T_Analysis_Job
    WHERE AJ_StateID IN (1, 2) AND
          AJ_priority = 3 AND
          AJ_batchID > 0 AND
          AJ_organismDBName <> 'na' AND
          NOT AJ_organismDBName IS NULL
    GROUP BY AJ_parmFileName, AJ_settingsFileName, AJ_organismDBName
    HAVING COUNT(*) > @activeStepThreshold
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    -- Batches with active, long-running jobs
    --
    INSERT INTO #Tmp_Batches(BatchID)
    SELECT J.AJ_batchID
    FROM T_Analysis_Job J
         INNER JOIN S_V_Pipeline_Job_Steps JS
           ON J.AJ_jobID = JS.Job
    WHERE JS.State = 4 AND
          J.AJ_priority = 3 AND
          JS.RunTime_Minutes > 180 AND
          AJ_batchID > 0
    GROUP BY J.AJ_batchID
    HAVING (COUNT(*) > @longRunningThreshold)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ----------------------------------------------
    -- Add candidate jobs to #Tmp_JobsToUpdate
    ----------------------------------------------
    --
    INSERT INTO #Tmp_JobsToUpdate (Job, Old_Priority, New_Priority, Ignored, Source)
    SELECT Job, 0 AS Old_Priority, 0 AS New_Priority, 0 AS Ignored, Min(Source)
    FROM (
        SELECT J.AJ_JobID AS Job,
               'Over ' + CAST(@activeStepThreshold as varchar(9)) + ' active job steps, protein collection based' AS Source
        FROM T_Analysis_Job J
                INNER JOIN #Tmp_ProteinCollectionJobs Src
                ON J.AJ_parmFileName = Src.ParamFile AND
                    J.AJ_settingsFileName = Src.SettingsFile AND
                    J.AJ_proteinCollectionList = Src.ProteinCollectionList
        UNION
        SELECT J.AJ_JobID AS Job,
               'Over ' + CAST(@activeStepThreshold as varchar(9)) + ' active job steps, organism DB based' AS Source
        FROM T_Analysis_Job J
                INNER JOIN #Tmp_LegacyOrgDBJobs Src
                ON J.AJ_parmFileName = Src.ParamFile AND
                    J.AJ_settingsFileName = Src.SettingsFile AND
                    J.AJ_organismDBName = Src.OrganismDBName
        UNION
        SELECT J.AJ_JobID AS Job, 'Over ' + CAST(@longRunningThreshold as varchar(9)) + ' long running job steps (by batch)' AS Source
        FROM T_Analysis_Job J
                INNER JOIN #Tmp_Batches Src
                ON J.AJ_batchID = Src.BatchID
        ) UnionQ
    GROUP BY Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    -- Update the old/new priority columns
    --
    UPDATE #Tmp_JobsToUpdate
    SET Old_Priority = Cast(J.AJ_Priority AS smallint),
        New_Priority = 4
    FROM #Tmp_JobsToUpdate U
         INNER JOIN T_Analysis_Job J
           ON J.AJ_JobID = U.Job

    -- Ignore any jobs that are already in T_Analysis_Job_Priority_Updates
    --
    UPDATE #Tmp_JobsToUpdate
    SET Ignored = 1
    FROM #Tmp_JobsToUpdate J
         INNER JOIN T_Analysis_Job_Priority_Updates JPU
           ON J.Job = JPU.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    If @infoOnly <> 0
    Begin
        ----------------------------------------------
        -- Preview the results
        ----------------------------------------------

        If Not Exists (SELECT * FROM #Tmp_JobsToUpdate)
        Begin
            Set @message = 'No candidate jobs (or ignored jobs) were found'
            SELECT @message AS Message
        End
        Else
        Begin
            SELECT DS.Dataset_Num AS Dataset,
                   J.AJ_JobID AS Job,
                   J.AJ_RequestID AS RequestID,
                   J.AJ_batchID AS BatchID,
                   J.AJ_Priority AS Priority,
                   U.Ignored,
                   J.AJ_parmFileName,
                   J.AJ_settingsFileName,
                   J.AJ_proteinCollectionList AS ProteinCollectionList,
                   J.AJ_organismDBName AS OrganismDBName,
                   U.Source
            FROM T_Analysis_Job J
                 INNER JOIN #Tmp_JobsToUpdate U
                   ON J.AJ_JobID = U.Job
                 INNER JOIN T_Dataset DS
                   ON J.AJ_DatasetID = DS.Dataset_ID
            ORDER BY J.AJ_batchID, J.AJ_JobID
        End
    End
    Else
    Begin
        ----------------------------------------------
        -- Update job priorities
        ----------------------------------------------

        If Not Exists (SELECT * FROM #Tmp_JobsToUpdate WHERE Ignored = 0)
        Begin
            Set @message = 'No candidate jobs were found'
        End
        Else
        Begin
            INSERT INTO T_Analysis_Job_Priority_Updates( Job,
                                                         Old_Priority,
                                                         New_Priority,
                                                         [Comment],
                                                         Entered )
            SELECT U.Job,
                   U.Old_Priority,
                   U.New_Priority,
                   U.Source,
                   GetDate()
            FROM #Tmp_JobsToUpdate U
            WHERE U.Ignored = 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            UPDATE T_Analysis_Job
            SET AJ_Priority = U.New_Priority
            FROM T_Analysis_Job J
                INNER JOIN #Tmp_JobsToUpdate U
                ON J.AJ_JobID = U.Job
            WHERE U.Ignored = 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @message = 'Updated job priority for ' + Cast(@myRowCount as varchar(9)) + ' long running ' + dbo.check_plural(@myRowCount, 'job', 'jobs')

            Exec post_log_entry 'Normal', @message, 'auto_update_job_priorities'
        End

        Print @message

    End

    return @myError

GO
