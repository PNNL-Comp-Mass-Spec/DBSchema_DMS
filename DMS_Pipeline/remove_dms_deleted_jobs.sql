/****** Object:  StoredProcedure [dbo].[remove_dms_deleted_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[remove_dms_deleted_jobs]
/****************************************************
**
**  Desc:
**  Delete failed jobs that have been removed from DMS
**  from the main tables in the database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          02/19/2009 grk - initial release (Ticket #723)
**          02/26/2009 mem - Updated to look for any job not present in DMS, but to exclude jobs with a currently running job step
**          06/01/2009 mem - Added parameter @MaxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          04/13/2010 grk - don't delete jobs where dataset ID = 0
**          05/26/2017 mem - Treat state 9 (Running_Remote) as an active job
**          02/01/2023 mem - Use new view name
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @infoOnly tinyint = 0,              -- 1 -> don't actually delete, just dump list of jobs that would have been
    @message varchar(512)='' output,
    @maxJobsToProcess int = 0
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    ---------------------------------------------------
    -- Create table to track the list of affected jobs
    ---------------------------------------------------
    --
    CREATE TABLE #SJL (
        Job INT,
        State INT
    )

    ---------------------------------------------------
    -- Find all jobs present in the Pipeline DB but not present in DMS
    -- V_DMS_Pipeline_Existing_Jobs returns a list of all jobs in DMS (regardless of state)
    ---------------------------------------------------
    --
    INSERT INTO #SJL (Job, State)
    SELECT Job, State
    FROM dbo.T_Jobs
    WHERE Dataset_ID <> 0 AND NOT Job IN (SELECT Job FROM V_DMS_Pipeline_Existing_Jobs)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        set @message = 'Error finding non-existent jobs in DMS'
        goto Done
    end

    if @myRowCount = 0
        goto Done

    ---------------------------------------------------
    -- Remove any entries from #SJL that have a currently running job step
    -- However, ignore job steps that started over 48 hours ago
    ---------------------------------------------------
    --
    DELETE #SJL
    FROM #SJL INNER JOIN
         T_Job_Steps JS ON #SJL.Job = JS.Job
    WHERE JS.State IN (4,9) AND JS.Start >= DateAdd(hour, -48, GetDate())
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Not Exists (SELECT * FROM #SJL)
        Goto Done

    If @MaxJobsToProcess > 0
    Begin
        -- Limit the number of jobs to delete
        DELETE FROM #SJL
        WHERE NOT Job IN ( SELECT TOP ( @MaxJobsToProcess ) Job
                           FROM #SJL
                           ORDER BY Job )
    End

    ---------------------------------------------------
    -- do actual deletion
    ---------------------------------------------------

    declare @transName varchar(64)
    set @transName = 'remove_dms_deleted_jobs'
    begin transaction @transName

    exec @myError = remove_selected_jobs @infoOnly, @message output, @LogDeletions = 1

    if @myError = 0
        commit transaction @transName
    else
        rollback transaction @transName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[remove_dms_deleted_jobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[remove_dms_deleted_jobs] TO [Limited_Table_Write] AS [dbo]
GO
