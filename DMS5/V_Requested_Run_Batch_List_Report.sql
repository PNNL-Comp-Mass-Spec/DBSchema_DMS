/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Requested_Run_Batch_List_Report]
AS
SELECT RRB.id,
       RRB.Batch AS name,
       RBS.active_requests AS requests, -- Active requests
       RBS.datasets,                    -- Completed requests (with datasets)
       RBS.blocked,                     -- Requests with a block number
       RBS.block_missing,
       RBS.first_active_request,
       RBS.last_active_request,
       RRB.Requested_Batch_Priority AS req_priority,
       CASE WHEN (COALESCE(RBS.datasets, 0) > 0)THEN
               CASE WHEN RBS.instrument_first = RBS.instrument_last
                    THEN RBS.instrument_first
                    ELSE RBS.instrument_first + ' - ' + RBS.instrument_last
               END
            ELSE ''
       END AS instrument,
       RBS.instrument_group_first AS inst_group,
       RRB.description,
       T_Users.U_Name AS owner,
       RRB.created,
       RBS.days_in_queue,
       Cast(RRB.Requested_Completion_Date AS date) AS complete_by,
       RBS.days_in_prep_queue,
       RRB.justification_for_high_priority,
       RRB.comment,
       CASE WHEN RBS.separation_group_first = RBS.separation_group_last
            THEN RBS.separation_group_first
            ELSE RBS.separation_group_first + ' - ' + RBS.separation_group_last
       END AS separation_group,
       RRB.Batch_Group_id AS batch_group,
       RRB.Batch_Group_Order AS batch_group_order,
       CASE
           WHEN COALESCE(RBS.active_requests, 0) = 0 THEN 0                                 -- No active requested runs for this batch
           WHEN DATEDIFF(DAY, RBS.oldest_active_request_created, GETDATE()) <= 30 THEN 30   -- Oldest active request in batch is 0 to 30 days old
           WHEN DATEDIFF(DAY, RBS.oldest_active_request_created, GETDATE()) <= 60 THEN 60   -- Oldest active request is 30 to 60 days old
           WHEN DATEDIFF(DAY, RBS.oldest_active_request_created, GETDATE()) <= 90 THEN 90   -- Oldest active request is 60 to 90 days old
           ELSE 120                                                                         -- Oldest active request is over 90 days old
       END AS days_in_queue_bin
FROM T_Requested_Run_Batches AS RRB
     LEFT OUTER JOIN T_Users
       ON RRB.Owner = T_Users.ID
     LEFT OUTER JOIN T_Cached_Requested_Run_Batch_Stats RBS
       ON RRB.ID = RBS.batch_id
WHERE RRB.ID > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [DDL_Viewer] AS [dbo]
GO
