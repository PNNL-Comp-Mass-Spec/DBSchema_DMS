/****** Object:  StoredProcedure [dbo].[UpdateCachedRequestedRunBatchStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCachedRequestedRunBatchStats]
/****************************************************
**
**  Desc:
**      Updates the data in T_Cached_Requested_Run_Batch_Stats
**
**      This table is used by view V_Requested_Run_Batch_List_Report
**      to display information about the requested runs and datasets associated with a requested run batch
**
**  Arguments:
**    @batchID  Specific requested run batch to update, or 0 to update all active Requested Run Batches
**
**  Auth:   mem
**  Date:   02/10/2023 mem - Initial Version
**
*****************************************************/
(
    @batchID Int = 0,
    @message varchar(512) = '' output
)
As
    Set nocount on
    Set ansi_warnings off

    Declare @myRowCount int = 0
    Declare @myError int = 0

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @batchID = IsNull(@batchID, 0)
    Set @message = ''

    If @batchID = 0
    Begin
        -- Updating all requested run batches

        -- Delete rows in T_Cached_Requested_Run_Batch_Stats that are not in T_Requested_Run_Batches
        DELETE FROM T_Cached_Requested_Run_Batch_Stats
        WHERE NOT EXISTS (SELECT RRB.ID FROM T_Requested_Run_Batches RRB WHERE batch_id = RRB.ID);

        -- Add new batches to T_Cached_Requested_Run_Batch_Stats
        INSERT INTO T_Cached_Requested_Run_Batch_Stats (batch_id)
        SELECT RRB.ID
        FROM T_Requested_Run_Batches RRB
             LEFT OUTER JOIN T_Cached_Requested_Run_Batch_Stats RBS
               ON RBS.batch_id = RRB.ID
        WHERE RRB.ID > 0 AND
              RBS.batch_id Is Null;
    End
    Else
    Begin
        -- Assure that the batch exists in the cache table
        INSERT INTO T_Cached_Requested_Run_Batch_Stats (batch_id)
        SELECT RRB.ID
        FROM T_Requested_Run_Batches RRB
             LEFT OUTER JOIN T_Cached_Requested_Run_Batch_Stats RBS
                ON RBS.batch_id = RRB.ID
        WHERE RRB.ID = @batchID AND RBS.batch_id Is Null;
    End

    -- Update cached active requested run stats
    MERGE INTO T_Cached_Requested_Run_Batch_Stats AS t
    USING (
            SELECT RRB.batch_id,
                   StatsQ.oldest_request_created,
                   StatsQ.separation_group_first,
                   StatsQ.separation_group_last,
                   ActiveStatsQ.active_requests,
                   ActiveStatsQ.first_active_request,
                   ActiveStatsQ.last_active_request,
                   ActiveStatsQ.oldest_active_request_created,
                   CASE WHEN ActiveStatsQ.active_requests = 0
                        THEN dbo.GetRequestedRunBatchMaxDaysInQueue(StatsQ.batch_id)   -- No active requested runs for this batch
                        ELSE DATEDIFF(DAY, ISNULL(ActiveStatsQ.oldest_active_request_created, StatsQ.oldest_request_created), GETDATE())
                   END AS days_in_queue
            FROM ( SELECT ID As batch_id
                   FROM T_Requested_Run_Batches
                   WHERE T_Requested_Run_Batches.ID > 0
                 ) RRB
                 LEFT OUTER JOIN
                 ( SELECT RR.RDS_BatchID AS batch_id,
                          MIN(RR.RDS_created) AS oldest_request_created,
                          MIN(RR.RDS_Sec_Sep) AS separation_group_first,
                          MAX(RR.RDS_Sec_Sep) AS separation_group_last
                   FROM T_Requested_Run RR
                   WHERE RR.RDS_BatchID > 0 AND
                         (RR.RDS_BatchID = @batchID OR @batchID = 0)
                   GROUP BY RR.RDS_BatchID
                 ) StatsQ ON RRB.batch_id = StatsQ.batch_id
                 LEFT OUTER JOIN
                 ( SELECT RR.RDS_BatchID AS batch_id,
                          COUNT(*)            AS active_requests,
                          MIN(RR.ID)          AS first_active_request,
                          MAX(RR.ID)          AS last_active_request,
                          MIN(RR.RDS_created) AS oldest_active_request_created
                   FROM T_Requested_Run RR
                   WHERE RR.RDS_BatchID > 0 AND
                         RR.RDS_Status = 'Active' AND
                         (RR.RDS_BatchID = @batchID OR @batchID = 0)
                   GROUP BY RR.RDS_BatchID
                 ) ActiveStatsQ ON RRB.batch_id = ActiveStatsQ.batch_id
              WHERE RRB.batch_id = @batchID OR @batchID = 0
          ) AS s
    ON ( t.batch_id = s.batch_id )
    WHEN MATCHED And (
            ISNULL( NULLIF(t.separation_group_first, s.separation_group_first),
                    NULLIF(s.separation_group_first, t.separation_group_first)) IS NOT NULL Or
            ISNULL( NULLIF(t.separation_group_last, s.separation_group_last),
                    NULLIF(s.separation_group_last, t.separation_group_last)) IS NOT NULL Or
            ISNULL( NULLIF(t.active_requests, s.active_requests),
                    NULLIF(s.active_requests, t.active_requests)) IS NOT NULL Or
            ISNULL( NULLIF(t.first_active_request, s.first_active_request),
                    NULLIF(s.first_active_request, t.first_active_request)) IS NOT NULL Or
            ISNULL( NULLIF(t.last_active_request, s.last_active_request),
                    NULLIF(s.last_active_request, t.last_active_request)) IS NOT NULL Or
            ISNULL( NULLIF(t.oldest_active_request_created, s.oldest_active_request_created),
                    NULLIF(s.oldest_active_request_created, t.oldest_active_request_created)) IS NOT NULL Or
            ISNULL( NULLIF(t.oldest_request_created, s.oldest_request_created),
                    NULLIF(s.oldest_request_created, t.oldest_request_created)) IS NOT NULL Or
            ISNULL( NULLIF(t.days_in_queue, s.days_in_queue),
                    NULLIF(s.days_in_queue, t.days_in_queue)) IS NOT NULL
          ) THEN
     UPDATE SET
            separation_group_first = s.separation_group_first,
            separation_group_last  = s.separation_group_last,
            active_requests        = s.active_requests,
            first_active_request   = s.first_active_request,
            last_active_request    = s.last_active_request,
            oldest_active_request_created = s.oldest_active_request_created,
            oldest_request_created = s.oldest_request_created,
            days_in_queue          = s.days_in_queue,
            last_affected          = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT ( batch_id, separation_group_first, active_requests, first_active_request, last_active_request,
                 oldest_active_request_created, oldest_request_created, days_in_queue, last_affected )
        VALUES ( s.batch_id, s.separation_group_first, s.active_requests, s.first_active_request, s.last_active_request,
                 s.oldest_active_request_created, s.oldest_request_created, s.days_in_queue, CURRENT_TIMESTAMP )
    ;

    -- Update completed requested run stats
    MERGE INTO T_Cached_Requested_Run_Batch_Stats AS t
    USING ( SELECT RRB.batch_id,
                   StatsQ.datasets,
                   StatsQ.min_days_in_queue,
                   StatsQ.max_days_in_queue,
                   StatsQ.instrument_first,
                   StatsQ.instrument_last
            FROM ( SELECT ID As batch_id
                   FROM T_Requested_Run_Batches
                   WHERE T_Requested_Run_Batches.ID > 0
                 ) RRB
                 LEFT OUTER JOIN
                 ( SELECT RR.RDS_BatchID As Batch_ID,
                          Count(*) AS datasets,
                          MIN(QT.days_in_queue) AS min_days_in_queue,
                          MAX(QT.days_in_queue) AS max_days_in_queue,
                          MIN(InstName.IN_name) AS instrument_first,
                          MAX(InstName.IN_name) AS instrument_last
                   FROM T_Requested_Run RR
                        INNER JOIN V_Requested_Run_Queue_Times AS QT
                          ON QT.requested_run_id = RR.RDS_BatchID
                        INNER JOIN T_Dataset DS
                          ON RR.DatasetID = DS.dataset_id
                        INNER JOIN T_Instrument_Name InstName
                          ON DS.DS_instrument_name_ID = InstName.instrument_id
                   WHERE RR.RDS_BatchID > 0 AND
                         (RR.RDS_BatchID = @batchID OR @batchID = 0)
                   GROUP BY RR.RDS_BatchID
                ) StatsQ ON RRB.batch_id = StatsQ.batch_id
            WHERE RRB.batch_id = @batchID OR @batchID = 0
          ) AS s
    ON ( t.batch_id = s.batch_id )
    WHEN MATCHED And (
            ISNULL( NULLIF(t.datasets, s.datasets),
                    NULLIF(s.datasets, t.datasets)) IS NOT NULL Or
            ISNULL( NULLIF(t.min_days_in_queue, s.min_days_in_queue),
                    NULLIF(s.min_days_in_queue, t.min_days_in_queue)) IS NOT NULL Or
            ISNULL( NULLIF(t.max_days_in_queue, s.max_days_in_queue),
                    NULLIF(s.max_days_in_queue, t.max_days_in_queue)) IS NOT NULL Or
            ISNULL( NULLIF(t.instrument_first, s.instrument_first),
                    NULLIF(s.instrument_first, t.instrument_first)) IS NOT NULL Or
            ISNULL( NULLIF(t.instrument_last, s.instrument_last),
                    NULLIF(s.instrument_last, t.instrument_last)) IS NOT NULL
         ) THEN
    UPDATE SET
        datasets          = s.datasets,
        min_days_in_queue = s.min_days_in_queue,
        max_days_in_queue = s.max_days_in_queue,
        instrument_first  = s.instrument_first,
        instrument_last   = s.instrument_last,
        last_affected     = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT ( batch_id, datasets, min_days_in_queue, max_days_in_queue, instrument_first, instrument_last, last_affected )
        VALUES ( s.batch_id, s.datasets, s.min_days_in_queue, s.max_days_in_queue, s.instrument_first, s.instrument_last, CURRENT_TIMESTAMP )
    ;

    -- Update requested run count and sample prep queue stats
    MERGE INTO T_Cached_Requested_Run_Batch_Stats AS t
    USING ( SELECT RRB.batch_id,
                   StatsQ.requests,
                   StatsQ.days_in_prep_queue,
                   StatsQ.blocked,
                   StatsQ.block_missing
            FROM ( SELECT ID As batch_id
                   FROM T_Requested_Run_Batches
                   WHERE T_Requested_Run_Batches.ID > 0
                 ) RRB
                 LEFT OUTER JOIN
                 ( SELECT RR.RDS_BatchID As batch_ID,
                          Count(*) AS requests,
                          MAX(QT.days_in_queue) AS days_in_prep_queue,
                          SUM(CASE
                              WHEN ((COALESCE(RR.RDS_Block, 0) > 0) AND (COALESCE(RR.RDS_Run_Order, 0) > 0)) THEN 1
                              ELSE 0
                              END) AS blocked,
                          SUM(CASE
                              WHEN ((LOWER(COALESCE(spr.BlockAndRandomizeRuns, '')) = 'yes') AND
                                   ((COALESCE(RR.RDS_Block, 0) = 0) OR (COALESCE(RR.RDS_Run_Order, 0) = 0))) THEN 1
                              ELSE 0
                              END) AS block_missing
                   FROM T_Requested_Run RR
                        INNER JOIN T_Experiments AS E
                          ON RR.exp_id = E.exp_id
                        LEFT OUTER JOIN T_Sample_Prep_Request AS SPR
                          ON E.EX_sample_prep_request_ID = SPR.ID AND
                             SPR.ID <> 0
                        LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT
                          ON SPR.ID = QT.request_id
                   WHERE RR.RDS_BatchID > 0 AND
                         (RR.RDS_BatchID = @batchID OR @batchID = 0)
                   GROUP BY RR.RDS_BatchID
                ) StatsQ ON RRB.batch_id = StatsQ.batch_id
            WHERE RRB.batch_id = @batchID OR @batchID = 0
          ) AS s
    ON ( t.batch_id = s.batch_id )
    WHEN MATCHED And (
            ISNULL( NULLIF(t.requests, s.requests),
                    NULLIF(s.requests, t.requests)) IS NOT NULL Or
            ISNULL( NULLIF(t.days_in_prep_queue, s.days_in_prep_queue),
                    NULLIF(s.days_in_prep_queue, t.days_in_prep_queue)) IS NOT NULL Or
            ISNULL( NULLIF(t.blocked, s.blocked),
                    NULLIF(s.blocked, t.blocked)) IS NOT NULL Or
            ISNULL( NULLIF(t.block_missing, s.block_missing),
                    NULLIF(s.block_missing, t.block_missing)) IS NOT NULL
            ) THEN
    UPDATE SET
        requests           = s.requests,
        days_in_prep_queue = s.days_in_prep_queue,
        blocked            = s.blocked,
        block_missing      = s.block_missing,
        last_affected      = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT ( requests, days_in_prep_queue, blocked, block_missing, last_affected )
        VALUES ( s.requests, s.days_in_prep_queue, s.blocked, s.block_missing, CURRENT_TIMESTAMP )
    ;

    Return @myError


GO
