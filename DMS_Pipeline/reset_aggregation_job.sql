/****** Object:  StoredProcedure [dbo].[reset_aggregation_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reset_aggregation_job]
/****************************************************
**
**  Desc:   Resets an aggregation job
**
**          Case 1:
**          If the job is complete (state 4), then renames the Output_Folder and resets all steps
**
            Case 2:
**          If the job has one or more failed steps, then leaves the Output Folder name unchanged but resets the failed steps
**
**  Auth:   mem
**  Date:   03/06/2013 mem - Initial version
**          03/07/2013 mem - Now only updating failed job steps when not resetting the entire job
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**
*****************************************************/
(
    @job int,                                           -- Job that needs to be rerun, including re-generating the shared results
    @infoOnly tinyint = 1,                              -- 1 to preview the changes
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @Dataset varchar(128) = ''
    Declare @JobState int
    Declare @Script varchar(64)

    Declare @JobText varchar(12) = ''

    Declare @ResetTran varchar(25) = 'Reset Job'

    BEGIN TRY

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    Set @Job = IsNull(@Job, 0)
    Set @InfoOnly = IsNull(@InfoOnly, 0)
    Set @message = ''
    Set @JobText = Convert(varchar(12), @Job)

    If @Job = 0
    Begin
        set @message = 'Job number not supplied'
        print @message
        RAISERROR (@message, 11, 17)
    End

    -----------------------------------------------------------
    -- Make sure the job exists and is an aggregation job
    -----------------------------------------------------------

    If Not Exists (SELECT * FROM T_Jobs WHERE Job = @Job)
    Begin
        Set @message = 'Job not found in T_Jobs: ' + @JobText
        print @message
        RAISERROR (@message, 11, 18)
    End

    SELECT @Dataset = Dataset,
           @JobState = State,
           @Script = Script
    FROM T_Jobs
    WHERE Job = @Job

    If IsNull(@Dataset, '') <> 'Aggregation'
    Begin
        Set @message = 'Job is not an aggregation job; reset this job by updating its state in DMS5: ' + @JobText
        print @message
        RAISERROR (@message, 11, 18)
    End

    -- See if we have any failed job steps
    If Exists (SELECT * FROM T_Job_Steps WHERE Job = @Job AND State = 6)
    Begin
        -- Override @JobState
        Set @JobState = 5
    End

    If @JobState = 5 AND Not Exists (SELECT * FROM T_Job_Steps WHERE Job = @Job AND State IN (6,7))
    Begin
        Set @message = 'Job ' + @JobText + ' is marked as failed (State=5 in T_Jobs) yet there are no failed or holding job steps; the job cannot be reset at this time'
        print @message
        RAISERROR (@message, 11, 19)
    End

    If Exists (SELECT * FROM T_Job_Steps WHERE Job = @Job AND State = 4)
    Begin
        Set @message = 'Job ' + @JobText + ' has running steps (state=4); the job cannot be reset while steps are running'
        print @message
        RAISERROR (@message, 11, 19)
    End

    If Not @JobState IN (4,5)
    Begin
        Set @message = 'Job ' + @JobText + ' is not complete or failed; the job cannot be reset at this time'
        print @message
        RAISERROR (@message, 11, 20)
    End

    If @JobState = 4
    Begin
        -- Job is complete; give the job a new results folder name and reset it

        Declare @tag varchar(8)
        Declare @resultsFolderName varchar(128)
        Declare @FolderLikeClause varchar(24)

        SELECT @tag = Results_Tag
        FROM T_Scripts
        WHERE (Script = @Script)

        -- Temporary table #Jobs must exist

        CREATE TABLE #Jobs (
            Job int NULL,
            Results_Folder_Name varchar(64) NULL
        )

        INSERT INTO #Jobs (Job) Values (@Job)

        Exec create_results_folder_name @Job, @tag, @resultsFolderName output, @message output

        print @resultsFolderName

        Set @FolderLikeClause = @Tag + '%'

        If @InfoOnly <> 0
        Begin
            -- Show job steps
            SELECT Job, Step, Output_Folder_Name as Output_Folder_Old, @resultsFolderName as Output_Folder_New
            FROM T_Job_Steps
            WHERE Job = @Job And (State <> 1 OR Input_Folder_Name Like @FolderLikeClause OR  Output_Folder_Name Like @FolderLikeClause)
            ORDER BY Step

            -- Show dependencies
            SELECT *,
                    CASE
                        WHEN Evaluated <> 0 OR
                            Triggered <> 0 THEN 'Dependency will be reset'
                        ELSE ''
                    END AS Message
            FROM T_Job_Step_Dependencies
            WHERE (Job = @Job)
            ORDER BY Step

        End
        Else
        Begin

            Begin Tran @ResetTran

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

            UPDATE T_Job_Steps
            SET Input_Folder_Name = @resultsFolderName
            WHERE Job = @Job AND Input_Folder_Name Like @FolderLikeClause

            UPDATE T_Job_Steps
            SET Output_Folder_Name = @resultsFolderName
            WHERE Job = @Job AND Output_Folder_Name Like @FolderLikeClause

            UPDATE T_Jobs
            SET State = 1, Results_Folder_Name =  @resultsFolderName
            WHERE Job = @Job AND State <> 1

            Commit Tran @ResetTran
        End

    End

    If @JobState = 5
    Begin

        If @InfoOnly <> 0
        Begin
            -- Show job steps that would be reset
            SELECT Job,
                   Step,
                   State AS State_Current,
                   1 AS State_New
            FROM T_Job_Steps
            WHERE Job = @Job AND
                  State IN (6, 7)
            ORDER BY Step

            -- Show dependencies
            SELECT *,
                   CASE
                       WHEN JS.State IN (6, 7) AND
                            (Evaluated <> 0 OR
                             Triggered <> 0) THEN 'Dependency will be reset'
                       ELSE ''
                   END AS Message
            FROM T_Job_Step_Dependencies JSD
                 INNER JOIN T_Job_Steps JS
                   ON JSD.Step = JS.Step AND
                      JSD.Job = JS.Job
            WHERE JSD.Job = @Job
            ORDER BY JSD.Step

        End
        Else
        Begin

            Begin Tran @ResetTran

            -- Reset dependencies
            UPDATE T_Job_Step_Dependencies
            SET Evaluated = 0,
                Triggered = 0
            FROM T_Job_Step_Dependencies JSD
                 INNER JOIN T_Job_Steps JS
                   ON JSD.Job = JS.Job AND
                      JSD.Step = JS.Step
            WHERE JSD.Job = @Job AND
                  JS.State IN (6, 7)

            UPDATE T_Job_Steps
            SET State = 1,                  -- 1=Waiting
                Tool_Version_ID = 1,        -- 1=Unknown
                Next_Try = GetDate(),
                Remote_Info_ID = 1          -- 1=Unknown
            WHERE Job = @Job AND State IN (6, 7) And State <> 1

            UPDATE T_Jobs
            SET State = 2
            WHERE Job = @Job AND State <> 2

            Commit Tran @ResetTran
        End

    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output
        Print @message

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'reset_aggregation_job'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[reset_aggregation_job] TO [DDL_Viewer] AS [dbo]
GO
