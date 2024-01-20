/****** Object:  StoredProcedure [dbo].[update_cached_requested_run_batch_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_requested_run_batch_stats]
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
**          02/24/2023 mem - Add argument @fullRefresh
**                         - When @fullRefresh is 0, use "last updated" times to limit the batch IDs to update
**                         - Fix long-running merge queries by using temp tables to store stats
**                         - Post a log entry if the runtime exceeds 30 seconds
**          01/02/2024 mem - Fix column name bug when joining V_Requested_Run_Queue_Times to T_Requested_Run
**          01/19/2024 mem - Fix bug that failed to populate column separation_group_last when adding a new batch to T_Cached_Requested_Run_Batch_Stats
**
*****************************************************/
(
    @batchID int = 0,
    @fullRefresh tinyint = 0,           -- When 0, only update batches where T_Requested_Run.Updated is later than T_Cached_Requested_Run_Batch_Stats.last_affected; when 1, update all
    @message varchar(512) = '' output
)
AS
    Set nocount on
    Set ansi_warnings off

    Declare @myRowCount int = 0
    Declare @myError int = 0

    -- These runtimes are in milliseconds
    Declare @runtimeStep1 int
    Declare @runtimeStep2 int
    Declare @runtimeStep3 int

    Declare @startTime datetime = GetDate();

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @batchID = IsNull(@batchID, 0)
    Set @fullRefresh = IsNull(@fullRefresh, 0)
    Set @message = ''

    If @batchID = 0
    Begin
        -- Updating all requested run batches

        -- Delete rows in T_Cached_Requested_Run_Batch_Stats that are not in T_Requested_Run_Batches
        DELETE FROM T_Cached_Requested_Run_Batch_Stats
        WHERE NOT EXISTS (SELECT RRB.ID FROM T_Requested_Run_Batches RRB WHERE batch_id = RRB.ID);

        -- Add new batches to T_Cached_Requested_Run_Batch_Stats
        INSERT INTO T_Cached_Requested_Run_Batch_Stats (batch_id, last_affected)
        SELECT RRB.ID, Cast('1970-01-01' As Datetime)
        FROM T_Requested_Run_Batches RRB
             LEFT OUTER JOIN T_Cached_Requested_Run_Batch_Stats RBS
               ON RBS.batch_id = RRB.ID
        WHERE RRB.ID > 0 AND
              RBS.batch_id Is Null;
    End
    Else
    Begin
        -- Assure that the batch exists in the cache table
        INSERT INTO T_Cached_Requested_Run_Batch_Stats (batch_id, last_affected)
        SELECT RRB.ID, Cast('1970-01-01' As Datetime)
        FROM T_Requested_Run_Batches RRB
             LEFT OUTER JOIN T_Cached_Requested_Run_Batch_Stats RBS
                ON RBS.batch_id = RRB.ID
        WHERE RRB.ID = @batchID AND RBS.batch_id Is Null;
    End

    ------------------------------------------------
    -- Find batch IDs to update
    ------------------------------------------------

    CREATE TABLE #Tmp_BatchIDs (
        Batch_ID int not Null
    );

    CREATE UNIQUE INDEX #IX_BatchIDs On #Tmp_BatchIDs (Batch_ID);

    If @batchID > 0
    Begin
        INSERT INTO #Tmp_BatchIDs (Batch_ID)
        SELECT Batch_ID
        FROM T_Cached_Requested_Run_Batch_Stats
        Where Batch_ID = @batchID
    End
    Else
    Begin
        If @fullRefresh > 0
        Begin
            INSERT INTO #Tmp_BatchIDs (Batch_ID)
            SELECT Batch_ID
            FROM T_Cached_Requested_Run_Batch_Stats
            WHERE Batch_ID > 0
        End
        Else
        Begin
            INSERT INTO #Tmp_BatchIDs (Batch_ID)
            SELECT DISTINCT RBS.Batch_ID
            FROM T_Cached_Requested_Run_Batch_Stats RBS
                 INNER JOIN T_Requested_Run RR
                   ON RBS.Batch_ID = RR.RDS_BatchID
            WHERE RBS.Batch_ID > 0 And RR.Updated > RBS.Last_Affected
        End
    End

    ------------------------------------------------
    -- Step 1: Update cached active requested run stats
    ------------------------------------------------

    Begin Transaction;

    MERGE INTO T_Cached_Requested_Run_Batch_Stats AS t
    USING (
            SELECT BatchQ.batch_id,
                   StatsQ.oldest_request_created,
                   StatsQ.separation_group_first,
                   StatsQ.separation_group_last,
                   ActiveStatsQ.active_requests,
                   ActiveStatsQ.first_active_request,
                   ActiveStatsQ.last_active_request,
                   ActiveStatsQ.oldest_active_request_created,
                   CASE WHEN ActiveStatsQ.active_requests = 0
                        THEN dbo.get_requested_run_batch_max_days_in_queue(StatsQ.batch_id)   -- No active requested runs for this batch
                        ELSE DATEDIFF(DAY, ISNULL(ActiveStatsQ.oldest_active_request_created, StatsQ.oldest_request_created), GETDATE())
                   END AS days_in_queue
            FROM ( SELECT Batch_ID
                   FROM #Tmp_BatchIDs
                 ) BatchQ
                 LEFT OUTER JOIN
                 ( SELECT RR.RDS_BatchID AS batch_id,
                          MIN(RR.RDS_created) AS oldest_request_created,
                          MIN(RR.RDS_Sec_Sep) AS separation_group_first,
                          MAX(RR.RDS_Sec_Sep) AS separation_group_last
                   FROM T_Requested_Run RR
                        INNER JOIN #Tmp_BatchIDs
                          ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID
                   GROUP BY RR.RDS_BatchID
                 ) StatsQ ON BatchQ.batch_id = StatsQ.batch_id
                 LEFT OUTER JOIN
                 ( SELECT RR.RDS_BatchID AS batch_id,
                          COUNT(*)            AS active_requests,
                          MIN(RR.ID)          AS first_active_request,
                          MAX(RR.ID)          AS last_active_request,
                          MIN(RR.RDS_created) AS oldest_active_request_created
                   FROM T_Requested_Run RR
                        INNER JOIN #Tmp_BatchIDs
                          ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID
                   WHERE RR.RDS_Status = 'Active'
                   GROUP BY RR.RDS_BatchID
                 ) ActiveStatsQ ON BatchQ.batch_id = ActiveStatsQ.batch_id
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
        INSERT ( batch_id, separation_group_first, separation_group_last, active_requests, first_active_request, last_active_request,
                 oldest_active_request_created, oldest_request_created, days_in_queue, last_affected )
        VALUES ( s.batch_id, s.separation_group_first, s.separation_group_last, s.active_requests, s.first_active_request, s.last_active_request,
                 s.oldest_active_request_created, s.oldest_request_created, s.days_in_queue, CURRENT_TIMESTAMP )
    ;

    Commit Transaction;

    Set @runtimeStep1 = DateDiff(millisecond, @startTime, GetDate())

    ------------------------------------------------
    -- Step 2: Update completed requested run stats
    -- (requested runs that have a Dataset ID value)
    ------------------------------------------------

    CREATE TABLE #Tmp_RequestedRunStats (
	    batch_id int NOT NULL,
	    datasets int NULL,
	    min_days_in_queue int NULL,
	    max_days_in_queue int NULL,
	    instrument_first varchar(24) NULL,
	    instrument_last varchar(24) NULL
    );

    CREATE UNIQUE INDEX #IX_Tmp_RequestedRunStats On #Tmp_RequestedRunStats (batch_id);

    INSERT INTO #Tmp_RequestedRunStats (batch_id, datasets, min_days_in_queue, max_days_in_queue, instrument_first, instrument_last)
    SELECT BatchQ.batch_id,
           StatsQ.datasets,
           StatsQ.min_days_in_queue,
           StatsQ.max_days_in_queue,
           StatsQ.instrument_first,
           StatsQ.instrument_last
    FROM ( SELECT Batch_ID
           FROM #Tmp_BatchIDs
         ) BatchQ
         LEFT OUTER JOIN ( SELECT RR.RDS_BatchID AS Batch_ID,
                                  Count(*) AS datasets,
                                  MIN(QT.days_in_queue) AS min_days_in_queue,
                                  MAX(QT.days_in_queue) AS max_days_in_queue,
                                  MIN(InstName.IN_name) AS instrument_first,
                                  MAX(InstName.IN_name) AS instrument_last
                           FROM T_Requested_Run RR
                                INNER JOIN #Tmp_BatchIDs
                                  ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID
                                INNER JOIN V_Requested_Run_Queue_Times AS QT
                                  ON QT.requested_run_id = RR.ID
                                INNER JOIN T_Dataset DS
                                  ON RR.DatasetID = DS.dataset_id
                                INNER JOIN T_Instrument_Name InstName
                                  ON DS.DS_instrument_name_ID = InstName.instrument_id
                           GROUP BY RR.RDS_BatchID ) StatsQ
            ON BatchQ.batch_id = StatsQ.batch_id;

    Begin Transaction;

    MERGE INTO T_Cached_Requested_Run_Batch_Stats AS t
    USING ( SELECT batch_id,
                   datasets,
                   min_days_in_queue,
                   max_days_in_queue,
                   instrument_first,
                   instrument_last
            FROM #Tmp_RequestedRunStats
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

    Commit Transaction;

    Drop Table #Tmp_RequestedRunStats;

    Set @runtimeStep2 = DateDiff(millisecond, @startTime, GetDate()) - @runtimeStep1

    ------------------------------------------------
    -- Step 3: Update requested run count and sample prep queue stats
    ------------------------------------------------

    CREATE TABLE #Tmp_RequestedRunExperimentStats (
	    batch_id int NOT NULL,
	    requests int NULL,
	    days_in_prep_queue int NULL,
	    blocked int NULL,
	    block_missing int NULL
    );

    CREATE UNIQUE INDEX #IX_RequestedRunExperimentStats On #Tmp_RequestedRunExperimentStats (batch_id);

    INSERT INTO #Tmp_RequestedRunExperimentStats (batch_id, requests, days_in_prep_queue, blocked, block_missing)
    SELECT BatchQ.batch_id,
           StatsQ.requests,
           StatsQ.days_in_prep_queue,
           StatsQ.blocked,
           StatsQ.block_missing
    FROM ( SELECT Batch_ID
           FROM #Tmp_BatchIDs
         ) BatchQ
         LEFT OUTER JOIN ( SELECT RR.RDS_BatchID AS batch_ID,
                                  Count(*) AS requests,
                                  MAX(QT.days_in_queue) AS days_in_prep_queue,
                                  SUM(CASE
                                          WHEN ((COALESCE(RR.RDS_Block, 0) > 0) AND
                                                (COALESCE(RR.RDS_Run_Order, 0) > 0))
                                          THEN 1
                                          ELSE 0
                                      END) AS blocked,
                                  SUM(CASE
                                          WHEN ((LOWER(COALESCE(spr.BlockAndRandomizeRuns, '')) = 'yes') AND
                                                ((COALESCE(RR.RDS_Block, 0) = 0) OR
                                                 (COALESCE(RR.RDS_Run_Order, 0) = 0)))
                                          THEN 1
                                          ELSE 0
                                      END) AS block_missing
                           FROM T_Requested_Run RR
                                INNER JOIN #Tmp_BatchIDs
                                  ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID
                                INNER JOIN T_Experiments AS E
                                  ON RR.exp_id = E.exp_id
                                LEFT OUTER JOIN T_Sample_Prep_Request AS SPR
                                  ON E.EX_sample_prep_request_ID = SPR.ID AND
                                     SPR.ID <> 0
                                LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT
                                  ON SPR.ID = QT.request_id
                           GROUP BY RR.RDS_BatchID ) StatsQ
           ON BatchQ.batch_id = StatsQ.batch_id;

    Begin Transaction;

    MERGE INTO T_Cached_Requested_Run_Batch_Stats AS t
    USING ( SELECT batch_id,
                   requests,
                   days_in_prep_queue,
                   blocked,
                   block_missing
            FROM #Tmp_RequestedRunExperimentStats
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

    Commit Transaction;

    DROP TABLE #Tmp_RequestedRunExperimentStats;

    Set @runtimeStep3 = DateDiff(millisecond, @startTime, GetDate()) - @runtimeStep1 - @runtimeStep2


    -- Overall runtime, in seconds
    Declare @runtimeSeconds Decimal(9,2) = DateDiff(millisecond, @startTime, GetDate()) / 1000.0

    Declare @runtimeMessage varchar(128)
    Set @runtimeMessage = 'Step 1: ' + Cast(Cast(@runtimeStep1 / 1000.0 As Decimal(9,2)) As varchar(12)) + ' seconds; ' +
                          'Step 2: ' + Cast(Cast(@runtimeStep2 / 1000.0 As Decimal(9,2)) As varchar(12)) + ' seconds; ' +
                          'Step 3: ' + Cast(Cast(@runtimeStep3 / 1000.0 As Decimal(9,2)) As varchar(12)) + ' seconds'

    If @runtimeSeconds > 30
    Begin
        Set @message = 'Excessive runtime updating requested run batch stats; ' + Cast(@runtimeSeconds As varchar(12)) + ' seconds elapsed overall; ' + @runtimeMessage
        Exec post_log_entry 'Error', @message, 'update_cached_requested_run_batch_stats'
    End
    Else
    Begin
        Set @message = 'Overall runtime: ' + Cast(@runtimeSeconds As varchar(12)) + ' seconds; ' + Coalesce(@runtimeMessage, '??')
    End

    Return @myError

GO
