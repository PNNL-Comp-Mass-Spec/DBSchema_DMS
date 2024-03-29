/****** Object:  StoredProcedure [dbo].[update_requested_run_status_history] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_requested_run_status_history]
/****************************************************
**
**  Desc:
**      Updates stats in T_Requested_Run_Status_History,
**      summarizing the number of requested runs in each state
**      in T_Requested_Run
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   09/25/2012 mem - Initial Version
**          01/05/2023 mem - Use new column names in V_Requested_Run_Queue_Times
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @minimumTimeIntervalHours integer = 1,  -- Set this to 0 to force the addition of new data to T_Requested_Run_Status_History
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

    declare @S varchar(1024)

    set @message = ''

    if IsNull(@MinimumTimeIntervalHours, 0) = 0
        set @UpdateTable = 1
    else
    Begin

        SELECT @TimeIntervalLastUpdateHours = DateDiff(minute, MAX(Posting_Time), GetDate()) / 60.0
        FROM T_Requested_Run_Status_History

        If IsNull(@TimeIntervalLastUpdateHours, @MinimumTimeIntervalHours) >= @MinimumTimeIntervalHours
            set @UpdateTable = 1
        else
            set @UpdateTable = 0

    End

    if @UpdateTable = 1
    Begin

        INSERT INTO T_Requested_Run_Status_History (Posting_Time, State_ID, Origin, Request_Count,
                                                    QueueTime_0Days, QueueTime_1to6Days, QueueTime_7to44Days,
                                                    QueueTime_45to89Days, QueueTime_90to179Days, QueueTime_180DaysAndUp)
        SELECT GETDATE() AS Posting_Time,
               State_ID,
               Origin,
               COUNT(*) AS Request_Count,
               SUM(CASE WHEN DaysInQueue = 0                THEN 1 ELSE 0 END) AS QueueTime_0Days,
               SUM(CASE WHEN DaysInQueue BETWEEN  1 AND   1 THEN 1 ELSE 0 END) AS QueueTime_1to6Days,
               SUM(CASE WHEN DaysInQueue BETWEEN  7 AND  44 THEN 1 ELSE 0 END) AS QueueTime_7to44Days,
               SUM(CASE WHEN DaysInQueue BETWEEN 45 AND  89 THEN 1 ELSE 0 END) AS QueueTime_45to89Days,
               SUM(CASE WHEN DaysInQueue BETWEEN 90 AND 179 THEN 1 ELSE 0 END) AS QueueTime_90to179Days,
               SUM(CASE WHEN DaysInQueue >= 180             THEN 1 ELSE 0 END) AS QueueTime_180DaysAndUp
        FROM ( SELECT DISTINCT RRSN.State_ID,
                               RR.RDS_Origin AS Origin,
                               RR.ID,
                               QT.Days_In_Queue AS DaysInQueue
               FROM T_Requested_Run RR
                    INNER JOIN T_Requested_Run_State_Name RRSN
                      ON RR.RDS_Status = RRSN.State_Name
                    LEFT OUTER JOIN V_Requested_Run_Queue_Times QT
                      ON RR.ID = QT.Requested_Run_ID
             ) SourceQ
        GROUP BY State_ID, Origin
        ORDER BY State_ID, Origin
        --
        SELECT @myError = @@error, @myRowCount = @@RowCount

        set @message = 'Appended ' + convert(varchar(9), @myRowCount) + ' rows to the Requested Run Status History table'
    End
    else
        set @message = 'Update skipped since last update was ' + convert(varchar(9), Round(@TimeIntervalLastUpdateHours, 1)) + ' hours ago'

Done:

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_requested_run_status_history] TO [DDL_Viewer] AS [dbo]
GO
