/****** Object:  StoredProcedure [dbo].[remove_selected_tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[remove_selected_tasks]
/****************************************************
**
**  Desc:
**      Delete jobs given in temp table #SJL
**      that must be populated by the caller
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          09/12/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          09/24/2014 mem - Rename Job in T_Task_Step_Dependencies
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @infoOnly tinyint = 0,              -- 1 -> don't actually delete, just dump list of jobs that would have been
    @message varchar(512)='' output,
    @logDeletions tinyint = 0           -- When 1, then logs each deleted job number in T_Log_Entries
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    Declare @Job int
    Declare @continue tinyint

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''
    Set @LogDeletions = IsNull(@LogDeletions, 0)

    ---------------------------------------------------
    -- bail if no candidates found
    ---------------------------------------------------
    --
    declare @numJobs int
    set @numJobs = 0
    --
    SELECT @numJobs = COUNT(*) FROM #SJL
    --
    if @numJobs = 0
        goto Done

    if @infoOnly > 0
    begin
        SELECT * FROM #SJL
    end
    else
    begin -- <a>

        ---------------------------------------------------
        -- delete job dependencies
        ---------------------------------------------------
        --
        DELETE FROM T_Task_Step_Dependencies
        WHERE (Job IN (SELECT Job FROM #SJL))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
         --
        if @myError <> 0
        begin
            set @message = 'Error deleting T_Task_Step_Dependencies'
            goto Done
        end

        ---------------------------------------------------
        -- delete job parameters
        ---------------------------------------------------
        --
        DELETE FROM T_Task_Parameters
        WHERE Job IN (SELECT Job FROM #SJL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
         --
        if @myError <> 0
        begin
            set @message = 'Error deleting T_Task_Parameters'
            goto Done
        end

        ---------------------------------------------------
        -- delete job steps
        ---------------------------------------------------
        --
        DELETE FROM T_Task_Steps
        WHERE Job IN (SELECT Job FROM #SJL)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
         --
        if @myError <> 0
        begin
            set @message = 'Error deleting T_Task_Steps'
            goto Done
        end

        ---------------------------------------------------
        -- Delete entries in T_Tasks
        ---------------------------------------------------
        --
        If @LogDeletions <> 0
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
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @Continue = 0
                Else
                Begin -- <d>

                    DELETE FROM T_Tasks
                    WHERE Job = @Job
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                    --
                    if @myError <> 0
                    begin
                        set @message = 'Error deleting job ' + Convert(varchar(17), @Job) + ' from T_Tasks'
                        goto Done
                    end

                    Set @message = 'Deleted job ' + Convert(varchar(17), @Job) + ' from T_Tasks'
                    Exec post_log_entry 'Normal', @message, 'remove_selected_tasks'

                End -- </d>

            End -- </c>

        End -- </b1>
        Else
        Begin -- <b2>

            ---------------------------------------------------
            -- Delete in bulk
            ---------------------------------------------------

            DELETE FROM T_Tasks
            WHERE Job IN (SELECT Job FROM #SJL)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                set @message = 'Error deleting T_Tasks'
                goto Done
            end

        End -- </b2>
    end -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[remove_selected_tasks] TO [DDL_Viewer] AS [dbo]
GO
