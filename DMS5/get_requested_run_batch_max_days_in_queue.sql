/****** Object:  UserDefinedFunction [dbo].[get_requested_run_batch_max_days_in_queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_requested_run_batch_max_days_in_queue]
/****************************************************
**
**  Desc:
**      Returns the largest value for v_requested_run_queue_times.days_in_queue
**      for the requested runs in the given batch
**
**  Return value: Maximum days in queue
**
**  Auth:   mem
**  Date:   02/10/2023 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @batchID int
)
RETURNS int
AS
BEGIN
    Declare @daysInQueue int

    SELECT @daysInQueue = MAX(QT.days_in_queue)
    FROM T_Requested_Run RR
         INNER JOIN V_Requested_Run_Queue_Times QT
           ON QT.requested_run_id = RR.ID
    WHERE RR.RDS_BatchID = @batchID AND NOT RR.DatasetID IS NULL
    GROUP BY RR.RDS_BatchID;

    RETURN @daysInQueue;
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_requested_run_batch_max_days_in_queue] TO [DDL_Viewer] AS [dbo]
GO
