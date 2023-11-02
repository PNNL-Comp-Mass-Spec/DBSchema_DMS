/****** Object:  StoredProcedure [dbo].[remove_old_tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[remove_old_tasks]
/****************************************************
**
**  Delete old capture task jobs by removing from T_Tasks, T_Task_Steps, etc.
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          09/12/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/21/2010 mem - Increased retention to 60 days for successful jobs
**                         - Now removing jobs with state Complete, Inactive, or Ignore
**          03/10/2014 mem - Added call to synchronize_task_stats_with_task_steps
**          01/23/2017 mem - Assure that jobs exist in the history before deleting from T_Tasks
**          08/17/2021 mem - When looking for completed or inactive jobs, use the Start time if Finish is null
**                         - Also look for jobs with state 14 = Failed, Ignore Job Step States
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**          11/02/2023 mem - Also remove capture task jobs with state 15 = Skipped
**
*****************************************************/
(
    @intervalDaysForSuccess real = 60,      -- Successful jobs must be this old to be deleted (0 -> no deletion)
    @intervalDaysForFail int = 135,         -- Failed jobs must be this old to be deleted (0 -> no deletion)
    @infoOnly tinyint = 0,
    @message varchar(512)='' output,
    @validateJobStepSuccess tinyint = 0
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @saveTime datetime = GetDate()

    ---------------------------------------------------
    -- Create table to track the list of affected capture task jobs
    ---------------------------------------------------
    --
    CREATE TABLE #SJL (
        Job int not null,
        State int
    )

    CREATE INDEX #IX_SJL_Job ON #SJL (Job)

    CREATE TABLE #TmpJobsNotInHistory (
        Job int not null,
        State int,
        JobFinish datetime
    )

    CREATE INDEX #IX_TmpJobsNotInHistory ON #TmpJobsNotInHistory (Job)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If IsNull(@intervalDaysForSuccess, -1) < 0
    Begin
        Set @intervalDaysForSuccess = 0
    End

    If IsNull(@intervalDaysForFail, -1) < 0
    Begin
        Set @intervalDaysForFail = 0
    End

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    ---------------------------------------------------
    -- Make sure the job Start and Finish values are up-to-date
    ---------------------------------------------------

    Exec synchronize_task_stats_with_task_steps @infoOnly=0

    ---------------------------------------------------
    -- Add old successful capture task jobs to be removed to list
    ---------------------------------------------------

    If @intervalDaysForSuccess > 0
    Begin
        Declare @cutoffDateTimeForSuccess datetime = DateAdd(hour, -1 * @intervalDaysForSuccess * 24, GetDate())

        INSERT INTO #SJL (Job, State)
        SELECT Job, State
        FROM T_Tasks
        WHERE State IN (3, 4, 15, 101) And    -- Complete, Inactive, Skipped, or Ignore
              IsNull(Finish, Start) < @cutoffDateTimeForSuccess
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error looking for successful jobs to remove'
            Goto Done
        End

        If @validateJobStepSuccess <> 0
        Begin
            -- Remove any jobs that have failed, in progress, or holding job steps
            DELETE #SJL
            FROM #SJL INNER JOIN
                 T_Task_Steps JS ON #SJL.Job = JS.Job
            WHERE NOT JS.State IN (4, 6, 7)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
                Print 'Warning: Removed ' + Convert(varchar(12), @myRowCount) + ' job(s) with one or more steps that was not skipped or complete'
            Else
                Print 'Successful jobs have been confirmed to all have successful (or skipped) steps'
        End

    End

    ---------------------------------------------------
    -- Add old failed capture task jobs to be removed to list
    ---------------------------------------------------

    If @intervalDaysForFail > 0
    Begin
        Declare @cutoffDateTimeForFail datetime = DateAdd(day, -1 * @intervalDaysForFail, GetDate())

        INSERT INTO #SJL (Job, State)
        SELECT Job,
               State
        FROM T_Tasks
        WHERE State In (5, 14) AND            -- 'Failed' or 'Failed, Ignore Job Step States'
              IsNull(Finish, Start) < @cutoffDateTimeForFail
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @message = 'Error looking for successful jobs to remove'
            Goto Done
        End
    End

    ---------------------------------------------------
    -- Make sure the capture task jobs to be deleted exist
    -- in T_Tasks_History and T_Task_Steps_History
    ---------------------------------------------------

    INSERT INTO #TmpJobsNotInHistory (Job, State)
    SELECT #SJL.Job,
           #SJL.State
    FROM #SJL
         LEFT OUTER JOIN T_Tasks_History JH
           ON #SJL.Job = JH.Job
    WHERE JH.Job IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Exists (Select * from #TmpJobsNotInHistory)
    Begin
        Declare @JobToAdd int = 0
        Declare @State int
        Declare @SaveTimeOverride datetime
        Declare @continue tinyint = 1

        UPDATE #TmpJobsNotInHistory
        SET JobFinish = Coalesce(J.Finish, J.Start, GetDate())
        FROM #TmpJobsNotInHistory Target
             INNER JOIN T_Tasks J
               ON Target.Job = J.Job

        While @Continue > 0
        Begin
            SELECT TOP 1 @JobToAdd = Job,
                         @State = State,
                         @SaveTimeOverride = JobFinish
            FROM #TmpJobsNotInHistory
            WHERE Job > @JobToAdd
            ORDER BY Job
             --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @Continue = 0
            Else
            Begin
                If @infoOnly > 0
                    Print 'Call copy_task_to_history for job ' + Cast(@JobToAdd as varchar(9)) + ' with date ' + Cast(@SaveTimeOverride as varchar(32))
                Else
                    exec copy_task_to_history @JobToAdd, @State, @message output, @OverrideSaveTime=1, @SaveTimeOverride=@SaveTimeOverride
            End
        End
    End

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    Declare @transName varchar(64) = 'remove_old_tasks'
    Begin transaction @transName

    exec @myError = remove_selected_tasks @infoOnly, @message output, @LogDeletions=0

    If @myError = 0
        Commit transaction @transName
    Else
        Rollback transaction @transName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[remove_old_tasks] TO [DDL_Viewer] AS [dbo]
GO
