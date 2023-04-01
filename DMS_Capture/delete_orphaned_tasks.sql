/****** Object:  StoredProcedure [dbo].[delete_orphaned_tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_orphaned_tasks]
/****************************************************
**
**  Desc:
**      Delete jobs in state 0 where the dataset no longer exists in DMS
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/22/2019 mem - Initial version
**          02/02/2023 bcg - Changed from V_Job_Steps to V_Task_Steps
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @infoOnly tinyint = 1,
    @message varchar(512)='' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Find orphaned jobs
    ---------------------------------------------------
    --

    Create Table #Tmp_JobsToDelete (
        Job Int Not Null,
        HasDependencies Tinyint Not null
    )

    Create Clustered Index #IX_Tmp_JobsToDelete_Job On #Tmp_JobsToDelete(Job)

    INSERT INTO #Tmp_JobsToDelete ( Job, HasDependencies )
    SELECT J.Job, 0
    FROM T_Tasks J
         LEFT OUTER JOIN S_DMS_T_Dataset DS
           ON J.Dataset_ID = DS.Dataset_ID
    WHERE J.State = 0 AND
          J.Imported < DateAdd(day, -5, GetDate()) AND
          DS.Dataset_ID IS NULL

    ---------------------------------------------------
    -- Remove any jobs that have data in T_Task_Steps, T_Task_Step_Dependencies, or T_Task_Parameters
    ---------------------------------------------------

    UPDATE #Tmp_JobsToDelete
    SET HasDependencies = 1
    FROM #Tmp_JobsToDelete Target
         INNER JOIN T_Task_Steps JS
           ON Target.Job = JS.Job

    UPDATE #Tmp_JobsToDelete
    SET HasDependencies = 1
    FROM #Tmp_JobsToDelete Target
         INNER JOIN T_Task_Step_Dependencies D
           ON Target.Job = D.Job

    UPDATE #Tmp_JobsToDelete
    SET HasDependencies = 1
    FROM #Tmp_JobsToDelete Target
         INNER JOIN T_Task_Parameters P
           ON Target.Job = P.Job

    If @infoOnly > 0
    Begin
        ---------------------------------------------------
        -- Preview the jobs
        ---------------------------------------------------
        --
        SELECT D.HasDependencies, T.*
        FROM V_Tasks T
             INNER JOIN #Tmp_JobsToDelete D
               ON T.job = D.Job
        ORDER BY T.job

    End
    Else
    Begin -- <a>

        ---------------------------------------------------
        -- Delete each job individually (so that we can log the dataset name and ID in T_Log_Entries)
        ---------------------------------------------------
        --

        Declare @continue Tinyint = 1
        Declare @job Int = 0
        Declare @dataset Varchar(128)
        Declare @datasetId Int
        Declare @scriptName Varchar(64)
        Declare @logMessage varchar(512)
        Declare @jobsDeleted Int = 0

        While @continue > 0
        Begin -- <b>
            SELECT TOP 1 @job = Job
            FROM #Tmp_JobsToDelete
            WHERE Job > @job And HasDependencies = 0
            ORDER BY Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin -- <c>
                SELECT @dataset = Dataset,
                       @datasetId = Dataset_ID,
                       @scriptName = Script
                FROM T_Tasks
                WHERE Job = @job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                DELETE FROM T_Tasks
                WHERE Job = @job

                Set @logMessage = 'Deleted orphaned ' + @scriptName + ' job ' + Cast(@job As Varchar(12)) + ' for dataset ' + @dataset + ' since no longer defined in DMS'

                Exec post_log_entry 'Normal', @logMessage, 'delete_orphaned_tasks'

                Set @jobsDeleted = @jobsDeleted + 1
            End -- </c>
        End -- </b>

        If @jobsDeleted > 0
        Begin
            Set @message = 'Deleted ' + Cast(@jobsDeleted As Varchar(12)) + ' orphaned job(s)'
        End

   End -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
