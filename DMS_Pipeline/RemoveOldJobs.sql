/****** Object:  StoredProcedure [dbo].[RemoveOldJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RemoveOldJobs]
/****************************************************
**
**  Delete jobs past their expiration date
**  from the main tables in the database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          12/18/2008 grk - Initial release
**          12/29/2008 mem - Updated to use Start time if Finish time is null and the Job has failed (State=5)
**          02/19/2009 grk - Added call to RemoveSelectedJobs (Ticket #723)
**          02/26/2009 mem - Now passing @logDeletions=0 to RemoveSelectedJobs
**          05/31/2009 mem - Updated @intervalDaysForSuccess to support partial days (e.g. 0.5)
**          02/24/2012 mem - Added parameter @maxJobsToProcess with a default of 25000
**          08/20/2013 mem - Added parameter @logDeletions
**          03/10/2014 mem - Added call to SynchronizeJobStatsWithJobSteps
**          01/18/2017 mem - Now counting job state 7 (No Intermediate Files Created) as Success
**          08/17/2021 mem - When looking for completed or inactive jobs, use the Start time if Finish is null
**                         - Also look for jobs with state 14 = Failed, Ignore Job Step States
**
*****************************************************/
(
    @intervalDaysForSuccess real = 45,      -- Successful jobs must be this old to be deleted (0 -> no deletion)
    @intervalDaysForFail int = 135,         -- Failed jobs must be this old to be deleted (0 -> no deletion)
    @infoOnly tinyint = 0,
    @message varchar(512)='' output,
    @validateJobStepSuccess tinyint = 0,
    @jobListOverride varchar(max) = '',     -- Comma separated list of jobs to remove from T_Jobs, T_Job_Steps, and T_Job_Parameters
    @maxJobsToProcess int = 25000,
    @logDeletions tinyint = 0               -- When 1, then logs each deleted job number in T_Log_Entries; when 2 then prints a log message (but does not log to T_Log_Entries)
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @saveTime datetime = getdate()

    ---------------------------------------------------
    -- Create table to track the list of affected jobs
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
        Set @intervalDaysForSuccess = 0

    If isNull(@intervalDaysForFail, -1) < 0
        Set @intervalDaysForFail = 0

    Set @jobListOverride = IsNull(@jobListOverride, '')

    Set @maxJobsToProcess = IsNull(@maxJobsToProcess, 25000)
    Set @logDeletions = IsNull(@logDeletions, 0)

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    ---------------------------------------------------
    -- Make sure the job Start and Finish values are up-to-date
    ---------------------------------------------------
    --
    Exec SynchronizeJobStatsWithJobSteps @infoOnly=0

    ---------------------------------------------------
    -- Add old successful jobs to be removed to list
    ---------------------------------------------------
    --
    If @intervalDaysForSuccess > 0
    Begin -- <a>
        Declare @cutoffDateTimeForSuccess datetime
        Set @cutoffDateTimeForSuccess = dateadd(hour, -1 * @intervalDaysForSuccess * 24, getdate())

        INSERT INTO #SJL (Job, State)
        SELECT TOP ( @maxJobsToProcess ) Job, State
        FROM T_Jobs
        WHERE State IN (4, 7) AND        -- 4=Complete, 7=No Intermediate Files Created
              IsNull(Finish, Start) < @cutoffDateTimeForSuccess
        ORDER BY Finish
         --
        SELECT @myError = @@error, @myRowCount = @@rowcount
         --
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
                 T_Job_Steps JS ON #SJL.Job = JS.Job
            WHERE NOT JS.State IN (3, 5)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
                Print 'Warning: Removed ' + Convert(varchar(12), @myRowCount) + ' job(s) with one or more steps that was not skipped or complete'
            Else
                Print 'Successful jobs have been confirmed to all have successful (or skipped) steps'
        End

    End -- </a>

    ---------------------------------------------------
    -- Add old failed jobs to be removed to list
    ---------------------------------------------------
    --
    If @intervalDaysForFail > 0
    Begin -- <b>
        Declare @cutoffDateTimeForFail datetime
        Set @cutoffDateTimeForFail = dateadd(day, -1 * @intervalDaysForFail, getdate())

        INSERT INTO #SJL (Job, State)
        SELECT Job,
               State
        FROM T_Jobs
        WHERE State IN (5, 14) AND            -- 5=Failed, 14=No Export
              IsNull(Finish, Start) < @cutoffDateTimeForFail
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error looking for successful jobs to remove'
            Goto Done
        End
    End -- </b>

    ---------------------------------------------------
    -- Add any jobs defined in @jobListOverride
    ---------------------------------------------------
    If @jobListOverride <> ''
    Begin
        INSERT INTO #SJL (Job, State)
        SELECT Job,
               State
        FROM T_Jobs
        WHERE Job IN ( SELECT DISTINCT VALUE
                       FROM dbo.udfParseDelimitedIntegerList ( @jobListOverride, ',' ) ) AND
              NOT Job IN ( SELECT Job FROM #SJL )
    End

    ---------------------------------------------------
    -- Make sure the jobs to be deleted exist
    -- in T_Jobs_History and T_Job_Steps_History
    ---------------------------------------------------

    INSERT INTO #TmpJobsNotInHistory (Job, State)
    SELECT #SJL.Job,
           #SJL.State
    FROM #SJL
         LEFT OUTER JOIN T_Jobs_History JH
           ON #SJL.Job = JH.Job
    WHERE JH.Job IS NULL
     --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Exists (Select * from #TmpJobsNotInHistory)
    Begin -- <c>
        Declare @JobToAdd int = 0
        Declare @State int
        Declare @SaveTimeOverride datetime
        Declare @continue tinyint = 1

        UPDATE #TmpJobsNotInHistory
        SET JobFinish = Coalesce(J.Finish, J.Start, GetDate())
        FROM #TmpJobsNotInHistory Target
             INNER JOIN T_Jobs J
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
                    Print 'Call copyJobToHistory for job ' + Cast(@JobToAdd as varchar(9)) + ' with date ' + Cast(@SaveTimeOverride as varchar(32))
                Else
                    exec CopyJobToHistory @JobToAdd, @State, @message output, @OverrideSaveTime=1, @SaveTimeOverride=@SaveTimeOverride
            End
        End
    End -- </c>

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    Declare @transName varchar(64) = 'RemoveOldJobs'
    Begin transaction @transName

    exec @myError = RemoveSelectedJobs @infoOnly, @message output, @logDeletions=@logDeletions

    If @myError = 0
        Commit transaction @transName
    Else
        Rollback transaction @transName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RemoveOldJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RemoveOldJobs] TO [Limited_Table_Write] AS [dbo]
GO
