/****** Object:  StoredProcedure [dbo].[finish_task_creation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[finish_task_creation]
/****************************************************
**
**  Desc:
**      Perform a mixed bag of operations on the jobs
**      in the temporary tables to finalize them before
**      copying to the main database tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/31/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/06/2009 grk - added code for: Special="Job_Results"
**          07/31/2009 mem - Now filtering by job in the subquery that looks for job steps with flag Special="Job_Results" (necessary when #Job_Steps contains more than one job)
**          04/08/2011 mem - Now skipping the 'ImsDeMultiplex' step for datasets that end in '_inverse'
**          09/24/2014 mem - Rename Job in T_Task_Step_Dependencies
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/07/2023 mem - Rename columns in temporary table
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @job int,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- update step dependency count
    ---------------------------------------------------
    --
    UPDATE #Job_Steps
    SET
        Dependencies = T.dependencies
    FROM
        #Job_Steps INNER JOIN
        (
            SELECT
              Step,
              COUNT(*) AS dependencies
            FROM
              #Job_Step_Dependencies
            WHERE    (Job = @job)
            GROUP BY Step
        ) AS T
        ON T.Step = #Job_Steps.Step
    WHERE #Job_Steps.Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating job step dependency count'
        goto Done
    end

    ---------------------------------------------------
    -- Initialize input directory of dataset
    -- for steps that have no dependencies
    ---------------------------------------------------
    --
    UPDATE #Job_Steps
    SET
        Input_Directory_Name = ''
    FROM
        #Job_Steps
    WHERE
        Dependencies = 0 AND
        Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error setting default input directory names'
        goto Done
    end

    ---------------------------------------------------
    -- Set results directory name for job to be that of
    --  the output directory for any step designated as
    --  Special="Job_Results"
    --
    -- This will only affect jobs that have a step with
    --  the Special_Instructions = 'Job_Results' attribute
    ---------------------------------------------------
    --
    UPDATE #Jobs
    SET Results_Directory_Name = LookupQ.Output_Directory_Name
    FROM #Jobs INNER JOIN
        (
            SELECT TOP 1 Job, Output_Directory_Name
            FROM #Job_Steps
            WHERE Job = @job AND
                  Special_Instructions = 'Job_Results'
            ORDER BY Step
        ) LookupQ ON #Jobs.Job = LookupQ.Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Skip the demultiplex step for datasets that end in _inverse
    -- These datasets have already been demultiplexed
    ---------------------------------------------------
    --
    UPDATE #Job_Steps
    SET State = 3
    FROM #Job_Steps JS
         INNER JOIN #Jobs J
           ON JS.Job = J.Job
    WHERE J.Dataset LIKE '%[_]inverse' AND
          JS.Tool = 'ImsDeMultiplex'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- set job to initialized state ("New")
    ---------------------------------------------------
    --
    UPDATE #Jobs
    SET State = 1
    WHERE Job = @job

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating job state'
        goto Done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[finish_task_creation] TO [DDL_Viewer] AS [dbo]
GO
