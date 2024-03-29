/****** Object:  StoredProcedure [dbo].[delete_old_tasks_from_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_old_tasks_from_history]
/****************************************************
**
**  Desc:
**      Delete jobs over three years old from
**      T_Tasks_History, T_Task_Steps_History, T_Task_Step_Dependencies_History, and T_Task_Parameters_History
**
**      However, assure that at least 250,000 jobs are retained
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
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
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @dateThreshold datetime

    Declare @jobHistoryMinimumCount int = 250000

    Declare @currentJobCount int
    Declare @jobCountToDelete int
    Declare @tempTableJobsToRemove int
    Declare @jobFirst int
    Declare @jobLast int

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 1)

    Set @message = ''

    ---------------------------------------------------
    -- Create a temp table to hold the jobs to delete
    ---------------------------------------------------

    CREATE TABLE #Tmp_JobsToDelete (
        Job   int NOT NULL,
        Saved datetime NOT NULL,
        PRIMARY KEY CLUSTERED ( Job, Saved )
    )

    ---------------------------------------------------
    -- Define the date threshold by subtracting three years from January 1 of this year
    ---------------------------------------------------

    Set @dateThreshold = DateAdd(Year, -3, DateTimeFromParts(Year(GetDate()), 1, 1, 0, 0, 0, 0))

    ---------------------------------------------------
    -- Find jobs to delete
    ---------------------------------------------------

    INSERT INTO #Tmp_JobsToDelete( Job, Saved )
    SELECT Job, Saved
    FROM T_Tasks_History
    WHERE Saved < @dateThreshold
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @jobCountToDelete = @myRowcount

    If @jobCountToDelete = 0
    Begin
        Set @message = 'No old jobs were found; exiting'
        Goto Done
    End

    ---------------------------------------------------
    -- Assure that 250,000 rows will remain in T_Tasks_History
    ---------------------------------------------------

    SELECT @currentJobCount = Count(*)
    FROM T_Tasks_History

    If @currentJobCount - @jobCountToDelete < @jobHistoryMinimumCount
    Begin
        -- Remove extra jobs from #Tmp_JobsToDelete
        Set @tempTableJobsToRemove = @jobHistoryMinimumCount - (@currentJobCount - @jobCountToDelete)

        DELETE FROM #Tmp_JobsToDelete
        WHERE Job IN ( SELECT TOP ( @tempTableJobsToRemove ) Job
                       FROM #Tmp_JobsToDelete
                       ORDER BY Job DESC )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @message = 'Removed ' + Cast(@myRowCount As Varchar(12)) +
                       ' rows from #Tmp_JobsToDelete to assure that ' +
                       Cast(@jobHistoryMinimumCount As Varchar(12)) + ' rows remain in T_Tasks_History'

        Print @message

        If Not Exists (Select * From #Tmp_JobsToDelete)
        Begin
            Set @message = '#Tmp_JobsToDelete is now empty, so no old jobs to delete; exiting'
            Goto Done
        End
    End

    SELECT @jobCountToDelete = Count(*),
           @jobFirst = Min(Job),
           @jobLast = Max(Job)
    FROM #Tmp_JobsToDelete
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Delete the old jobs (preview if @infoOnly is non-zero)
    ---------------------------------------------------
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @infoOnly > 0
    Begin
        SELECT Top 10 Job, Saved, 'Preview delete' As Comment
        From #Tmp_JobsToDelete
        ORDER By Job

        SELECT TOP 10 Job, Saved, 'Preview delete' AS Comment
        FROM ( SELECT TOP 10 Job, Saved
               FROM #Tmp_JobsToDelete
               ORDER BY Job DESC ) FilterQ
        ORDER BY Job
    End
    Else
    Begin
        Delete From T_Task_Steps_History
        Where Job In (Select Job From #Tmp_JobsToDelete)

        Delete From T_Task_Step_Dependencies_History
        Where Job In (Select Job From #Tmp_JobsToDelete)

        Delete From T_Task_Parameters_History
        Where Job In (Select Job From #Tmp_JobsToDelete)

        Delete From T_Tasks_History
        Where Job In (Select Job From #Tmp_JobsToDelete)
    End

    If @infoOnly > 0
        Set @message = 'Would delete '
    Else
        Set @message = 'Deleted '

    Set @message = @message + Cast(@jobCountToDelete As Varchar(12)) + ' old jobs from the history tables; ' +
                   'job number range ' + Cast(@jobFirst As varchar(12)) + ' to ' + Cast(@jobLast As varchar(12))

    If @infoOnly = 0 And @jobCountToDelete > 0
    Begin
        Exec post_log_entry 'Normal', @message, 'delete_old_tasks_from_history'
    End

Done:
    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in delete_old_tasks_from_history'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        If @infoOnly = 0
            Exec post_log_entry 'Error', @message, 'delete_old_tasks_from_history'
    End

    If Len(@message) > 0
        Print @message

    Return @myError

GO
