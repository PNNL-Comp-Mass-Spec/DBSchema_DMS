/****** Object:  StoredProcedure [dbo].[update_cpu_loading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cpu_loading]
/****************************************************
**
**  Desc:
**      Update local processor list with count of CPUs
**      that are available for new tasks, given current
**      task assignments
**
**      Also updates memory usage
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**          06/03/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          09/10/2010 mem - Now using READUNCOMMITTED when querying T_Job_Steps
**          10/17/2011 mem - Now populating Memory_Available
**          09/24/2014 mem - Removed reference to Machine in T_Job_Steps
**          02/26/2015 mem - Split the Update query into two parts
**          04/17/2015 mem - Now using column Uses_All_Cores
**          11/18/2015 mem - Now using Actual_CPU_Load
**          05/26/2017 mem - Consider Remote_Info_ID when determining CPU and memory usage
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    CREATE TABLE #Tmp_MachineStats (
        Machine varchar(64) NOT NULL,
        CPUs_Used int null,
        Memory_Used int null
    )

    ---------------------------------------------------
    -- Find job steps that are currently busy
    -- and sum up cpu counts and memory uage for tools by machine
    -- Update T_Machines
    --
    -- This is a two-step query to avoid locking T_Job_Steps
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_MachineStats (Machine, CPUs_Used, Memory_Used)
    SELECT M.Machine,
        SUM(CASE WHEN JobStepsQ.State = 4
                 THEN
                    CASE
                       WHEN JobStepsQ.Remote_Info_ID > 1
                         THEN 0
                       WHEN JobStepsQ.Uses_All_Cores > 0 AND JobStepsQ.Actual_CPU_Load = JobStepsQ.CPU_Load
                         THEN M.Total_CPUs
                       ELSE
                         IsNull(JobStepsQ.Actual_CPU_Load, 1)
                    END
                 ELSE 0
            END) AS CPUs_used,
        SUM(CASE WHEN JobStepsQ.State = 4 AND JobStepsQ.Remote_Info_ID <= 1
                 THEN JobStepsQ.Memory_Usage_MB
                 ELSE 0
            END) AS Memory_Used
    FROM T_Machines M
         LEFT OUTER JOIN T_Local_Processors LP
           ON M.Machine = LP.Machine
         LEFT OUTER JOIN ( SELECT JS.Processor,
                                  JS.State,
                                  Tools.Uses_All_Cores,
                                  JS.CPU_Load,
                                  JS.Actual_CPU_Load,
                                  JS.Memory_Usage_MB,
                                  IsNull(JS.Remote_Info_ID, 0) AS Remote_Info_ID
                           FROM T_Job_Steps JS WITH ( READUNCOMMITTED )
                                INNER JOIN T_Step_Tools Tools
                                  ON Tools.Name = JS.Step_Tool ) JobStepsQ
           ON LP.Processor_Name = JobStepsQ.Processor
    GROUP BY M.Machine
    --
    UPDATE T_Machines
    SET CPUs_Available = M.Total_CPUs - TX.CPUs_used,
        Memory_Available = M.Total_Memory_MB - TX.Memory_Used
    FROM T_Machines M
         INNER JOIN #Tmp_MachineStats AS TX
           ON TX.Machine = M.Machine
    WHERE CPUs_Available <> M.Total_CPUs - TX.CPUs_used OR
          Memory_Available <> M.Total_Memory_MB - TX.Memory_Used
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
     --
    if @myError <> 0
    begin
        set @message = 'Error updating machine CPU loading'
        goto Done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_cpu_loading] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_cpu_loading] TO [Limited_Table_Write] AS [dbo]
GO
