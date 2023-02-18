/****** Object:  StoredProcedure [dbo].[retry_selected_jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[retry_selected_jobs]
/****************************************************
**
**  Desc:
**      Updates capture jobs in temporary table #SJL
**
**      Note: Use SP update_multiple_capture_jobs to retry a list of jobs
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   01/11/2010
**          01/18/2010 grk - reset step retry count
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- set any failed or holding job steps to waiting
    -- and reset retry count from step tools table
    ---------------------------------------------------
    --
    UPDATE
      T_Job_Steps
    SET
      State = 1,
      Retry_Count = T_Step_Tools.Number_Of_Retries
    FROM
      T_Job_Steps
      INNER JOIN T_Step_Tools ON T_Job_Steps.Step_Tool = T_Step_Tools.Name
    WHERE
      ( T_Job_Steps.State IN ( 6, 7 ) ) -- 6=Failed, 7=Holding
      AND
      Job IN ( SELECT
                Job
               FROM
                #SJL )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating Resume job steps'
        goto Done
    end

    ---------------------------------------------------
    -- Reset the entries in T_Job_Step_Dependencies for any steps with state 1
    ---------------------------------------------------
    --
    UPDATE T_Job_Step_Dependencies
    SET Evaluated = 0,
        Triggered = 0
    FROM T_Job_Step_Dependencies JSD INNER JOIN
        T_Job_Steps JS ON
        JSD.Job = JS.Job AND
        JSD.Step_Number = JS.Step_Number
    WHERE
        JS.State = 1 AND            -- 1=Waiting
        JS.Job IN (SELECT Job From #SJL)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating Resume job step depencies'
        goto Done
    end

    ---------------------------------------------------
    -- set job state to "new"
    ---------------------------------------------------
    --
    UPDATE T_Jobs
    SET State = 1                       -- 20=resuming
    WHERE
        Job IN (SELECT Job From #SJL)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating Resume jobs'
        goto Done
    end
/**/
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[retry_selected_jobs] TO [DDL_Viewer] AS [dbo]
GO
