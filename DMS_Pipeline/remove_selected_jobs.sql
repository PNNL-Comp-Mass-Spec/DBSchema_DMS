/****** Object:  StoredProcedure [dbo].[remove_selected_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[remove_selected_jobs]
/****************************************************
**
**  Desc:
**      Delete jobs given in temp table #SJL (populated by the caller)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          02/19/2009 grk - initial release (Ticket #723)
**          02/26/2009 mem - Added parameter @LogDeletions
**          02/28/2009 grk - Added logic to preserve record of successful shared results
**          08/20/2013 mem - Added support for @LogDeletions=2
**                         - Now disabling trigger trig_ud_T_Jobs when deleting rows from T_Jobs (required because stored procedure remove_old_jobs wraps the call to this procedure with a transaction)
**          06/16/2014 mem - Now disabling trigger trig_ud_T_Job_Steps when deleting rows from T_Job_Steps
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**          06/29/2023 mem - Update table alias and update comments
**
*****************************************************/
(
    @infoOnly tinyint = 0,              -- 1 -> don't actually delete, just dump list of jobs that would have been
    @message varchar(512)='' output,
    @logDeletions tinyint = 0           -- When 1, then logs each deleted job number in T_Log_Entries; when 2 then prints a log message (but does not log to T_Log_Entries)
)
AS
    Set nocount on

    declare @myError int
    Set @myError = 0

    declare @myRowCount int
    Set @myRowCount = 0

    Declare @Job int
    Declare @continue tinyint

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''
    Set @LogDeletions = IsNull(@LogDeletions, 0)

    ---------------------------------------------------
    -- Bail If no candidates found
    ---------------------------------------------------
    --
    declare @numJobs int
    Set @numJobs = 0
    --
    SELECT @numJobs = COUNT(*) FROM #SJL
    --
    If @numJobs = 0
        goto Done

    If @infoOnly > 0
    Begin
        SELECT * FROM #SJL
    End
    Else
    Begin -- <a>

        ---------------------------------------------------
        -- Preserve record of successfully completed
        -- shared results
        ---------------------------------------------------

        -- For the jobs being deleted, finds all instances of
        -- successfully completed results transfer steps that
        -- were directly dependent upon steps that generated
        -- shared results, and makes sure that their output folder
        -- name is entered into the shared results table

        INSERT INTO T_Shared_Results (Results_Name)
        SELECT DISTINCT JS.Output_Folder_Name
        FROM T_Job_Steps AS TransferJS
             INNER JOIN T_Job_Step_Dependencies AS JSD
               ON TransferJS.Job = JSD.Job AND
                  TransferJS.Step = JSD.Step
             INNER JOIN T_Job_Steps AS JS
               ON JSD.Job = JS.Job AND
                  JSD.Target_Step = JS.Step
        WHERE TransferJS.Tool = 'Results_Transfer' AND
              TransferJS.State = 5 AND
              JS.Shared_Result_Version > 0 AND
              NOT JS.Output_Folder_Name IN ( SELECT Results_Name
                                             FROM T_Shared_Results ) AND
              TransferJS.Job IN ( SELECT Job
                                  FROM #SJL )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
         --
        If @myError <> 0
        Begin
            Set @message = 'Error preserving shared results'
            goto Done
        End

        ---------------------------------------------------
        -- Delete job dependencies
        ---------------------------------------------------
        --
        DELETE FROM T_Job_Step_Dependencies
        WHERE Job IN (SELECT Job FROM #SJL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error deleting T_Job_Step_Dependencies'
            goto Done
        End

        If @LogDeletions = 2
            print 'Deleted ' + Convert(varchar(12), @myRowCount) + ' rows from T_Job_Step_Dependencies'

        ---------------------------------------------------
        -- Delete job parameters
        ---------------------------------------------------
        --
        DELETE FROM T_Job_Parameters
        WHERE Job IN (SELECT Job FROM #SJL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
         --
        If @myError <> 0
        Begin
            Set @message = 'Error deleting T_Job_Parameters'
            goto Done
        End

        If @LogDeletions = 2
            print 'Deleted ' + Convert(varchar(12), @myRowCount) + ' rows from T_Job_Parameters';

        disable trigger trig_ud_T_Job_Steps on T_Job_Steps;

        ---------------------------------------------------
        -- Delete job steps
        ---------------------------------------------------
        --
        DELETE FROM T_Job_Steps
        WHERE Job IN (SELECT Job FROM #SJL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error deleting T_Job_Steps'
            goto Done
        End

        If @LogDeletions = 2
            print 'Deleted ' + Convert(varchar(12), @myRowCount) + ' rows from T_Job_Steps';

        enable trigger trig_ud_T_Job_Steps on T_Job_Steps;

        ---------------------------------------------------
        -- Delete entries in T_Jobs
        ---------------------------------------------------
        --
        If @LogDeletions = 1
        Begin -- <b1>

            ---------------------------------------------------
            -- Delete jobs one at a time, posting a log entry for each deleted job
            ---------------------------------------------------

            Set @Job = 0

            SELECT @Job = MIN(Job)
            FROM #SJL

            Set @Job = IsNull(@Job, 0) - 1

            Set @Continue = 1
            While @Continue = 1
            Begin -- <c>
                SELECT TOP 1 @Job = Job
                FROM #SJL
                WHERE Job > @Job
                ORDER BY Job
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @Continue = 0
                Else
                Begin -- <d>

                    DELETE FROM T_Jobs
                    WHERE Job = @Job
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                    --
                    If @myError <> 0
                    Begin
                        Set @message = 'Error deleting job ' + Convert(varchar(17), @Job) + ' from T_Jobs'
                        goto Done
                    End

                    Set @message = 'Deleted job ' + Convert(varchar(17), @Job) + ' from T_Jobs'
                    Exec post_log_entry 'Normal', @message, 'remove_selected_jobs'

                End -- </d>

            End -- </c>

        End -- </b1>
        Else
        Begin; -- <b2>

            ---------------------------------------------------
            -- Delete in bulk
            ---------------------------------------------------

            Disable Trigger trig_ud_T_Jobs ON T_Jobs;

            DELETE FROM T_Jobs
            WHERE Job IN (SELECT Job FROM #SJL)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Error deleting T_Jobs'
                goto Done
            End

            If @LogDeletions = 2
                print 'Deleted ' + Convert(varchar(12), @myRowCount) + ' rows from T_Jobs';

            Enable Trigger trig_ud_T_Jobs ON T_Jobs;

        End; -- </b2>
    End -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[remove_selected_jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[remove_selected_jobs] TO [Limited_Table_Write] AS [dbo]
GO
