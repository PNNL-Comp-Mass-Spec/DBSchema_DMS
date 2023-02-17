/****** Object:  StoredProcedure [dbo].[import_job_processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[import_job_processors]
/****************************************************
**
**  Desc:
**    get list of jobs and associated processors
**    and count of associated groups that are enabled for general processing
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**          05/26/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/17/2009 mem - Removed Insert operation for T_Local_Job_Processors, since sync_job_info now populates T_Local_Job_Processors (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          06/27/2009 mem - Now removing entries from T_Local_Job_Processors only if the job is complete or not present in T_Jobs; if a job is failed but still in T_Jobs, then the entry is not removed from T_Local_Job_Processors
**          07/01/2010 mem - No longer logging message "Updated T_Local_Job_Processors; DeleteCount=" each time T_Local_Job_Processors is updated
**          06/01/2015 mem - No longer deleting rows in T_Local_Job_Processors since we have deprecated processor groups
**          02/15/2016 mem - Re-enabled support for processor groups, but altered logic to wait for 2 hours before deleting completed jobs
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @bypassDMS tinyint = 0,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    if @bypassDMS <> 0
        goto Done

    ---------------------------------------------------
    -- Remove job-processor associations
    -- from jobs that completed at least 2 hours ago
    ---------------------------------------------------

    DELETE FROM T_Local_Job_Processors
    WHERE Job IN ( SELECT Job
                   FROM T_Jobs
                   WHERE State = 4 AND
                         Finish < DateAdd(hour, -2, GetDate()) )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        set @message = 'Error removing job-processor associations'
        goto Done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[import_job_processors] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[import_job_processors] TO [Limited_Table_Write] AS [dbo]
GO
