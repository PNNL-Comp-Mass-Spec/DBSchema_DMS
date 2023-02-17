/****** Object:  StoredProcedure [dbo].[reset_job_and_shared_results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reset_job_and_shared_results]
/****************************************************
**
**  Desc:   Resets a job, including updating the appropriate tables
**          so that any shared results for a job will get re-created
**
**
**  Auth:   mem
**          06/30/2010 mem - Initial version
**          11/18/2010 mem - Fixed bug resetting dependencies
**                           Added transaction
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          04/13/2012 mem - Now querying T_Job_Steps_History when looking for shared result folders
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,                                           -- Job that needs to be rerun, including re-generating the shared results
    @sharedResultFolderName varchar(128) = '',          -- If blank, then will be auto-determined for the given job
    @resetJob tinyint = 0,                              -- Will automatically reset the job if 1, otherwise, you must manually reset the job
    @infoOnly tinyint = 1,                              -- 1 to preview the changes
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @continue tinyint
    declare @EntryID int
    declare @OutputFolder varchar(128)
    Declare @RemoveJobsMessage varchar(512)
    Declare @JobMatch int

    Declare @ResetTran varchar(25) = 'Reset Job'

    BEGIN TRY

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    Set @Job = IsNull(@Job, 0)
    Set @SharedResultFolderName = IsNull(@SharedResultFolderName, '')
    Set @InfoOnly = IsNull(@InfoOnly, 0)
    Set @message = ''

    If @Job = 0
    Begin
        set @message = 'Job number not supplied'
        print @message
        RAISERROR (@message, 11, 17)
    End

    -----------------------------------------------------------
    -- Create the temporary tables
    -----------------------------------------------------------
    --

    CREATE TABLE #Tmp_SharedResultFolders (
        Entry_ID int Identity(1,1),
        Output_Folder varchar(128)
    )

    -- This table is used by remove_selected_jobs and must be named #SJL
    CREATE TABLE #SJL (
        Job INT,
        State INT
    )

    If @InfoOnly = 0
        Begin Tran @ResetTran


    If @SharedResultFolderName = ''
    Begin
        -----------------------------------------------------------
        -- Find the shared result folders for this job
        -----------------------------------------------------------
        --
        INSERT INTO #Tmp_SharedResultFolders( Output_Folder )
        SELECT DISTINCT Output_Folder_Name
        FROM T_Job_Steps
        WHERE (Job = @Job) AND
            (ISNULL(Signature, 0) > 0) AND
             NOT Output_Folder_Name IS NULL
        UNION
        SELECT DISTINCT Output_Folder_Name
        FROM T_Job_Steps_History
        WHERE (Job = @Job) AND
            (ISNULL(Signature, 0) > 0) AND
             NOT Output_Folder_Name IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        INSERT INTO #Tmp_SharedResultFolders( Output_Folder )
        VALUES (@SharedResultFolderName)
    End

    -----------------------------------------------------------
    -- Process each entry in #Tmp_SharedResultFolders
    -----------------------------------------------------------
    --

    Set @continue = 1
    Set @EntryID = 0

    While @continue = 1
    Begin -- <a>
        SELECT TOP 1 @EntryID = Entry_ID,
                     @OutputFolder = Output_Folder
        FROM #Tmp_SharedResultFolders
        WHERE Entry_ID > @EntryID
        ORDER BY Entry_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin -- <b>

            print 'Removing all records of output folder "' + @OutputFolder + '"'

            If @InfoOnly <> 0
            Begin -- <c1>
                SELECT 'Delete from T_Shared_Results' as Message, *
                FROM T_Shared_Results
                WHERE (Results_Name = @OutputFolder)

                SELECT 'Remove job from T_Jobs, but leave in T_Jobs_History' as Message,
                       V_Job_Steps.Job AS JobToRemoveFromTJobs,
                       T_Jobs.State AS Job_State
                FROM V_Job_Steps
                     INNER JOIN T_Jobs
                       ON V_Job_Steps.Job = T_Jobs.Job
                WHERE (V_Job_Steps.Output_Folder = @OutputFolder) AND
                      (V_Job_Steps.State = 5) AND
                      (T_Jobs.State = 4)

                SELECT 'Update T_Job_Steps_History' as Message, Output_Folder_Name, Output_Folder_Name + '_BAD' as Output_Folder_Name_New
                FROM T_Job_Steps_History
                WHERE (Output_Folder_Name = @OutputFolder) AND State = 5
            End -- </c1>
            Else
            Begin -- <c2>

                -- Remove from T_Shared_Results
                DELETE FROM T_Shared_Results
                WHERE (Results_Name = @OutputFolder)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount <> 0
                    Set @message = 'Removed ' + Convert(varchar(12), @myRowCount) + ' row(s) from T_Shared_Results'
                Else
                    Set @message = 'Match not found in T_Shared_Results'

                TRUNCATE TABLE #SJL

                -- Remove any completed jobs that had this output folder
                -- (the job details should already be in T_Job_Steps_History)
                INSERT INTO #SJL
                SELECT V_Job_Steps.Job AS JobToDelete, T_Jobs.State
                FROM V_Job_Steps INNER JOIN
                    T_Jobs ON V_Job_Steps.Job = T_Jobs.Job
                WHERE (V_Job_Steps.Output_Folder = @OutputFolder)
                    AND (V_Job_Steps.State = 5) AND (T_Jobs.State = 4)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount


                If Exists (SELECT * FROM #SJL)
                Begin
                    exec remove_selected_jobs @infoOnly=0, @message=@RemoveJobsMessage output, @LogDeletions=1

                    Set @message = @message + '; ' + @RemoveJobsMessage
                End

                -- Rename Output Folder in T_Job_Steps_History for any completed job steps
                UPDATE T_Job_Steps_History
                SET Output_Folder_Name = Output_Folder_Name + '_BAD'
                WHERE (Output_Folder_Name = @OutputFolder) AND State = 5
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount <> 0
                    Set @message = @message + '; Updated ' + Convert(varchar(12), @myRowCount) + ' row(s) in T_Job_Steps_History'
                Else
                    Set @message = @message + '; Match not found in T_Job_Steps_History'


                -- Look for any jobs that remain in T_Job_Steps and have completed steps with Output_Folder = @OutputFolder
                Set @myRowCount = 0
                SELECT @myRowCount = COUNT(Distinct Job)
                FROM V_Job_Steps
                WHERE (Output_Folder = @OutputFolder) AND
                      (State = 5)

                If @myRowCount > 0
                Begin -- <d>
                    SELECT Job, 'This job likely needs to have it''s Output_Folder field renamed to not be ' + @OutputFolder as Message
                    FROM V_Job_Steps
                    WHERE (Output_Folder = @OutputFolder) AND
                        (State = 5)

                    If @myRowCount = 1
                    Begin
                        SELECT @JobMatch = Job
                        FROM V_Job_Steps
                        WHERE (Output_Folder = @OutputFolder) AND (State = 5)

                        Set @message = @message + '; Job ' + Convert(varchar(12), @Job) + ' in T_Job_Steps likely needs to have it''s Output_Folder field renamed to not be ' + @OutputFolder
                    End
                    Else
                        Set @message = @message + '; ' + Convert(varchar(12), @myRowCount) + ' jobs in T_Job_Steps likely need to have their Output_Folder field renamed to not be ' + @OutputFolder
                End -- </d>

            End -- </c2>
        End -- </b>
    End -- </a>

    If @ResetJob <> 0
    Begin
        If @InfoOnly <> 0
        Begin
            -- Show dependencies
            SELECT *,
                   CASE
                       WHEN Evaluated <> 0 OR
                            Triggered <> 0 THEN 'Dependency will be reset'
                       ELSE ''
                   END AS Message
            FROM T_Job_Step_Dependencies
            WHERE (Job = @Job)

        End
        Else
        Begin
            -- Reset the job (but don't delete it from the tables, and don't use remove_selected_jobs since it would update T_Shared_Results)

            -- Reset dependencies
            UPDATE T_Job_Step_Dependencies
            SET Evaluated = 0, Triggered = 0
            WHERE (Job = @Job)

            UPDATE T_Job_Steps
            SET State = 1,                  -- 1=waiting
                Tool_Version_ID = 1,        -- 1=Unknown
                Next_Try = GetDate(),
                Remote_Info_ID = 1          -- 1=Unknown
            WHERE Job = @Job AND State <> 1

            UPDATE T_Jobs
            SET State = 1
            WHERE Job = @Job AND State <> 1

        End

    End

    If @InfoOnly = 0
        Commit Tran @ResetTran


    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'reset_job_and_shared_results'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[reset_job_and_shared_results] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[reset_job_and_shared_results] TO [Limited_Table_Write] AS [dbo]
GO
