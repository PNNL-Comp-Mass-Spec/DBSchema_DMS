/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_List_Report]
AS
SELECT RRB.id,
       RRB.Batch AS name,
       ActiveReqSepGroups.requests,     -- Active requests
       CompletedRequests.runs,          -- Completed requests (with datasets)
       SPQ.blocked,                     -- Requests with a block number
       SPQ.block_missing,
       ActiveReqStats.first_request,
       ActiveReqStats.last_request,
       RRB.Requested_Batch_Priority AS req_priority,
       CASE WHEN CompletedRequests.Runs > 0 THEN
               CASE WHEN CompletedRequests.InstrumentFirst = CompletedRequests.instrumentlast
                    THEN CompletedRequests.instrumentfirst
                    ELSE CompletedRequests.InstrumentFirst + ' - ' + CompletedRequests.instrumentlast
               END
            ELSE ''
       END AS instrument,
       RRB.Requested_Instrument AS inst_group,
       RRB.description,
       T_Users.U_Name AS owner,
       RRB.created,
       CASE WHEN ActiveReqSepGroups.Requests IS NULL
            THEN CompletedRequests.MaxDaysInQueue    -- No active requested runs for this batch
            ELSE DATEDIFF(DAY, ISNULL(ActiveReqStats.oldest_request_created, CompletedRequests.Oldest_Request_Created), GETDATE())
       END AS days_in_queue,
       Cast(RRB.Requested_Completion_Date AS date) AS complete_by,
       SPQ.days_in_prep_queue,
       RRB.justification_for_high_priority,
       RRB.comment,
       CASE WHEN ActiveReqSepGroups.SeparationGroupFirst = ActiveReqSepGroups.separationgrouplast
            THEN ActiveReqSepGroups.separationgroupfirst
            ELSE ActiveReqSepGroups.SeparationGroupFirst + ' - ' + ActiveReqSepGroups.separationgrouplast
       END AS separation_group,
       CASE
           WHEN ActiveReqSepGroups.Requests IS NULL THEN 0    -- No active requested runs for this batch
           WHEN DATEDIFF(DAY, ActiveReqStats.oldest_request_created, GETDATE()) <= 30 THEN 30    -- Oldest active request in batch is 0 to 30 days old
           WHEN DATEDIFF(DAY, ActiveReqStats.oldest_request_created, GETDATE()) <= 60 THEN 60    -- Oldest active request is 30 to 60 days old
           WHEN DATEDIFF(DAY, ActiveReqStats.oldest_request_created, GETDATE()) <= 90 THEN 90    -- Oldest active request is 60 to 90 days old
           ELSE 120                                                                              -- Oldest active request is over 90 days old
       END AS days_in_queue_bin
       /*
       CASE
           WHEN ActiveReqSepGroups.Requests IS NULL OR
                CompletedRequests.MinDaysInQueue IS NULL THEN 0   -- No active requested runs for this batch
           WHEN CompletedRequests.MinDaysInQueue <= 30   THEN 30  -- Oldest request in batch is 0 to 30 days old
           WHEN CompletedRequests.MinDaysInQueue <= 60   THEN 60  -- Oldest request is 30 to 60 days old
           WHEN CompletedRequests.MinDaysInQueue <= 90   THEN 90  -- Oldest request is 60 to 90 days old
           ELSE 120                                               -- Oldest request is over 90 days old
       END AS min_days_in_queue_bin
       */
FROM T_Requested_Run_Batches AS RRB
     INNER JOIN T_Users
       ON RRB.Owner = T_Users.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              MIN(RDS_Sec_Sep) AS SeparationGroupFirst,
                              MAX(RDS_Sec_Sep) AS SeparationGroupLast,
                              COUNT(*) AS Requests
                       FROM T_Requested_Run AS RR1
                       WHERE (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID
                     ) AS ActiveReqSepGroups
       ON ActiveReqSepGroups.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RR2.RDS_BatchID AS BatchID,
                              COUNT(*) AS Runs,
                              MIN(RR2.RDS_created) AS Oldest_Request_Created,
                              MIN(QT.Days_In_Queue) AS MinDaysInQueue,
                              MAX(QT.Days_In_Queue) AS MaxDaysInQueue,
                              MIN(InstName.IN_name) AS InstrumentFirst,
                              MAX(InstName.IN_name) AS InstrumentLast
                       FROM T_Requested_Run AS RR2
                            INNER JOIN V_Requested_Run_Queue_Times AS QT
                              ON QT.RequesteD_Run_ID = RR2.ID
                            INNER JOIN T_Dataset AS DS
                              ON RR2.DatasetID = DS.Dataset_ID
                            INNER JOIN T_Instrument_Name AS InstName
                              ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                       WHERE (NOT (RR2.DatasetID IS NULL))
                       GROUP BY RR2.RDS_BatchID
                     ) AS CompletedRequests
       ON CompletedRequests.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              MIN(ID) AS First_Request,
                              MAX(ID) AS Last_Request,
                              MIN(RDS_created) AS Oldest_Request_Created
                       FROM T_Requested_Run AS RR3
                       WHERE (DatasetID IS NULL) AND
                             (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID
                     ) AS ActiveReqStats
       ON ActiveReqStats.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RR4.RDS_BatchID AS BatchID,
                              MAX(QT.Days_In_Queue) AS Days_in_Prep_Queue,
                              SUM(CASE WHEN ISNULL(SPR.BlockAndRandomizeRuns, '') = 'yes'
                                          AND ( ISNULL(RR4.RDS_Block, '') = ''
                                                OR ISNULL(RR4.RDS_Run_Order, '') = ''
                                              ) THEN 1
                                     ELSE 0
                                END) AS Block_Missing,
                                SUM(CASE WHEN ISNULL(RR4.RDS_Block, '') <> ''
                                          AND ISNULL(RR4.RDS_Run_Order, '') <> ''
                                     THEN 1
                                     ELSE 0
                                END) AS Blocked
                       FROM T_Requested_Run AS RR4
                            INNER JOIN T_Experiments AS E
                              ON RR4.Exp_ID = E.Exp_ID
                            LEFT OUTER JOIN T_Sample_Prep_Request AS SPR
                              ON E.EX_sample_prep_request_ID = SPR.ID AND
                                 SPR.ID <> 0
                            LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times AS QT
                              ON SPR.ID = QT.Request_ID
                       GROUP BY RR4.RDS_BatchID
                     ) AS SPQ
       ON SPQ.BatchID = RRB.ID
WHERE RRB.ID > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [DDL_Viewer] AS [dbo]
GO
