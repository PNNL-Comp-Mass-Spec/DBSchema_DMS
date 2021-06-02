/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_List_Report]
AS
SELECT RRB.ID,
       RRB.Batch AS Name,
       ActiveReqSepTypes.Requests,      -- Active requests
       CompletedRequests.Runs,          -- Completed requests (with datasets)
       SPQ.Blocked,                     -- Requests with a block number
       SPQ.BlkMissing,
       ActiveReqStats.[First Request],
       ActiveReqStats.[Last Request],
       RRB.Requested_Batch_Priority AS [Req. Priority],
       CASE WHEN CompletedRequests.Runs > 0 THEN
               CASE WHEN CompletedRequests.InstrumentFirst = CompletedRequests.InstrumentLast 
                    THEN CompletedRequests.InstrumentFirst
                    ELSE CompletedRequests.InstrumentFirst + ' - ' + CompletedRequests.InstrumentLast
               END
            ELSE ''
       END AS Instrument,
       RRB.Requested_Instrument AS [Inst. Group],
       RRB.Description,
       T_Users.U_Name AS Owner,
       RRB.Created,
       CASE WHEN ActiveReqSepTypes.Requests IS NULL 
            THEN CompletedRequests.MaxDaysInQueue    -- No active requested runs for this batch
            ELSE DATEDIFF(DAY, ISNULL(ActiveReqStats.Oldest_Request_Created, CompletedRequests.Oldest_Request_Created), GETDATE())
       END AS [Days In Queue],
       Cast(RRB.Requested_Completion_Date as date) AS [Complete By],
       SPQ.[Days in Prep Queue],
       RRB.Justification_for_High_Priority,
       RRB.[Comment],
       CASE WHEN ActiveReqSepTypes.SeparationTypeFirst = ActiveReqSepTypes.SeparationTypeLast 
            THEN ActiveReqSepTypes.SeparationTypeFirst
            ELSE ActiveReqSepTypes.SeparationTypeFirst + ' - ' + ActiveReqSepTypes.SeparationTypeLast
       END AS [Separation Type],        -- Separation group
       CASE
           WHEN ActiveReqSepTypes.Requests IS NULL THEN 0    -- No active requested runs for this batch
           WHEN DATEDIFF(DAY, ActiveReqStats.Oldest_Request_Created, GETDATE()) <= 30 THEN 30    -- Oldest active request in batch is 0 to 30 days old
           WHEN DATEDIFF(DAY, ActiveReqStats.Oldest_Request_Created, GETDATE()) <= 60 THEN 60    -- Oldest active request is 30 to 60 days old
           WHEN DATEDIFF(DAY, ActiveReqStats.Oldest_Request_Created, GETDATE()) <= 90 THEN 90    -- Oldest active request is 60 to 90 days old
           ELSE 120                                                                              -- Oldest active request is over 90 days old
       END AS [#DaysInQueue],
       CASE
           WHEN ActiveReqSepTypes.Requests IS NULL OR
                CompletedRequests.MinDaysInQueue IS NULL THEN 0   -- No active requested runs for this batch
           WHEN CompletedRequests.MinDaysInQueue <= 30   THEN 30  -- Oldest request in batch is 0 to 30 days old
           WHEN CompletedRequests.MinDaysInQueue <= 60   THEN 60  -- Oldest request is 30 to 60 days old
           WHEN CompletedRequests.MinDaysInQueue <= 90   THEN 90  -- Oldest request is 60 to 90 days old
           ELSE 120                                               -- Oldest request is over 90 days old
       END AS [#MinDaysInQueue]
FROM T_Requested_Run_Batches AS RRB
     INNER JOIN T_Users
       ON RRB.Owner = T_Users.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              MIN(RDS_Sec_Sep) AS SeparationTypeFirst,
                              MAX(RDS_Sec_Sep) AS SeparationTypeLast,
                              COUNT(*) AS Requests
                       FROM T_Requested_Run AS RR1
                       WHERE (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID 
                     ) AS ActiveReqSepTypes
       ON ActiveReqSepTypes.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RR2.RDS_BatchID AS BatchID,
                              COUNT(*) AS Runs,
                              MIN(RR2.RDS_created) AS Oldest_Request_Created,
                              MIN(QT.[Days In Queue]) AS MinDaysInQueue,
                              MAX(QT.[Days In Queue]) AS MaxDaysInQueue,
                              MIN(InstName.IN_name) AS InstrumentFirst,
                              MAX(InstName.IN_name) AS InstrumentLast
                       FROM T_Requested_Run AS RR2
                            INNER JOIN V_Requested_Run_Queue_Times AS QT
                              ON QT.RequestedRun_ID = RR2.ID
                            INNER JOIN T_Dataset AS DS
                              ON RR2.DatasetID = DS.Dataset_ID
                            INNER JOIN T_Instrument_Name AS InstName
                              ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                       WHERE (NOT (RR2.DatasetID IS NULL))
                       GROUP BY RR2.RDS_BatchID 
                     ) AS CompletedRequests
       ON CompletedRequests.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              MIN(ID) AS [First Request],
                              MAX(ID) AS [Last Request],
                              MIN(RDS_created) AS Oldest_Request_Created
                       FROM T_Requested_Run AS RR3
                       WHERE (DatasetID IS NULL) AND
                             (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID 
                     ) AS ActiveReqStats
       ON ActiveReqStats.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RR4.RDS_BatchID AS BatchID,
                              MAX(QT.[Days In Queue]) AS [Days in Prep Queue],
                              SUM(CASE WHEN ISNULL(SPR.BlockAndRandomizeRuns, '') = 'yes'
                                          AND ( ISNULL(RR4.RDS_Block, '') = ''
                                                OR ISNULL(RR4.RDS_Run_Order, '') = ''
                                              ) THEN 1
                                     ELSE 0
                                END) AS BlkMissing ,
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
