/****** Object:  StoredProcedure [dbo].[update_actual_cpu_loading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_actual_cpu_loading]
/****************************************************
**
**  Desc:
**      Updates Actual_CPU_Load based on T_Processor_Status
**      (using ProgRunner_CoreUsage values pushed by the Analysis Manager)
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   mem
**  Date:   11/20/2015 mem - Initial release
**          01/05/2016 mem - Check for load values over 255
**          05/26/2017 mem - Ignore jobs running remotely
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in T_Job_Steps and T_Job_Step_Dependencies
**
*****************************************************/
(
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    ---------------------------------------------------
    -- Look for actively running Progrunner tasks in T_Processor_Status
    ---------------------------------------------------

    Declare @PendingUpdates AS Table (
        Processor_Name varchar(128) not null,
        Job int not null,
        Step int not null,
        New_CPU_Load int not null
    )


    ---------------------------------------------------
    -- Find managers with an active job step and valid values for ProgRunner_ProcessID and ProgRunner_CoreUsage
    ---------------------------------------------------
    --
    INSERT INTO @PendingUpdates( Processor_Name,
                                 Job,
                                 Step,
                                 New_CPU_Load )
    SELECT PS.Processor_Name,
           JS.Job,
           JS.Step,
           Round(PS.ProgRunner_CoreUsage, 0) AS New_CPU_Load
    FROM T_Processor_Status PS
         INNER JOIN T_Job_Steps JS
           ON PS.Job = JS.Job AND
              PS.Job_Step = JS.Step AND
              PS.Processor_Name = JS.Processor
    WHERE JS.State = 4 AND
          IsNull(JS.Remote_Info_ID, 0) <= 1 AND
          ISNULL(PS.ProgRunner_ProcessID, 0) > 0 AND
          NOT (PS.ProgRunner_CoreUsage IS NULL)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    --
    -- Make sure New_CPU_Load is <= 255
    --
    UPDATE @PendingUpdates
    SET New_CPU_Load = 255
    WHERE New_CPU_Load > 255


    If Exists (Select * From @PendingUpdates)
    Begin -- <a>

        ---------------------------------------------------
        -- Preview the results or update T_Job_Steps
        ---------------------------------------------------

        If @infoOnly <> 0
        Begin
            SELECT JS.Job,
                   JS.Dataset,
                   JS.Step,
                   JS.Tool,
                   JS.RunTime_Minutes,
                   JS.Job_Progress,
                   JS.Processor,
                   JS.CPU_Load,
                   JS.Actual_CPU_Load,
                   U.New_CPU_Load
            FROM @PendingUpdates U
                 INNER JOIN V_Job_Steps JS
                   ON U.Job = JS.Job AND
                      U.Step = JS.Step AND
                      U.Processor_Name = JS.Processor
            ORDER BY JS.Tool, JS.Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End
        Else
        Begin
            UPDATE T_Job_Steps
            SET Actual_CPU_Load = U.New_CPU_Load
            FROM @PendingUpdates U
                 INNER JOIN T_Job_Steps JS
                   ON U.Job = JS.Job AND
                      U.Step = JS.Step AND
                      U.Processor_Name = JS.Processor
            WHERE JS.Actual_CPU_Load <> U.New_CPU_Load OR
                  JS.Actual_CPU_Load IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

    End -- </a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_actual_cpu_loading] TO [DDL_Viewer] AS [dbo]
GO
