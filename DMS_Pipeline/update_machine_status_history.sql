/****** Object:  StoredProcedure [dbo].[update_machine_status_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_machine_status_history]
/****************************************************
**
**  Desc:
**      Appends new entries to T_Machine_Status_History,
**      summarizing the number of active jobs on each machine
**      and the max reported free memory in the last 24 hours
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   08/10/2010 mem - Initial version
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**
*****************************************************/
(
    @minimumTimeIntervalHours int = 1,      -- Set this to 0 to force the addition of new data to T_Analysis_Job_Status_History
    @activeProcessWindowHours int = 24,     -- Will consider status values posted within the last @ActiveProcessWindowHours as valid status values
    @message varchar(128) = '' OUTPUT
)
AS
    Set NoCount On

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    declare @TimeIntervalLastUpdateHours real
    declare @UpdateTable tinyint

    ----------------------------------------
    -- Validate the inputs
    ----------------------------------------
    --
    Set @MinimumTimeIntervalHours = IsNull(@MinimumTimeIntervalHours, 1)
    Set @ActiveProcessWindowHours = IsNull(@ActiveProcessWindowHours, 24)
    set @message = ''

    if IsNull(@MinimumTimeIntervalHours, 0) = 0
        set @UpdateTable = 1
    else
    Begin
        ----------------------------------------
        -- Lookup how long ago the table was last updated
        ----------------------------------------
        --
        SELECT @TimeIntervalLastUpdateHours = DateDiff(minute, MAX(Posting_Time), GetDate()) / 60.0
        FROM T_Machine_Status_History

        If IsNull(@TimeIntervalLastUpdateHours, @MinimumTimeIntervalHours) >= @MinimumTimeIntervalHours
            set @UpdateTable = 1
        else
            set @UpdateTable = 0

    End

    if @UpdateTable = 1
    Begin

        INSERT INTO T_Machine_Status_History( Posting_Time,
                                      Machine,
                                      Processor_Count_Active,
                                      Free_Memory_MB )
        SELECT GETDATE(),
               M.Machine,
               COUNT(*) AS Processor_Count_Active,
               CONVERT(int, MAX(PS.Free_Memory_MB)) AS Free_Memory_MB
        FROM T_Processor_Status PS
             INNER JOIN T_Local_Processors LP
               ON PS.Processor_Name = LP.Processor_Name
             INNER JOIN T_Machines M
               ON LP.Machine = M.Machine
        WHERE PS.Status_Date > DateAdd(Hour, -@ActiveProcessWindowHours, GetDate())
        GROUP BY M.Machine
        ORDER BY M.Machine
        --
        SELECT @myError = @@error, @myRowCount = @@RowCount

        set @message = 'Appended ' + convert(varchar(9), @myRowCount) + ' rows to the Machine Status History table'
    End
    else
        set @message = 'Update skipped since last update was ' + convert(varchar(9), Round(@TimeIntervalLastUpdateHours, 1)) + ' hours ago'

Done:

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_machine_status_history] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_machine_status_history] TO [Limited_Table_Write] AS [dbo]
GO
