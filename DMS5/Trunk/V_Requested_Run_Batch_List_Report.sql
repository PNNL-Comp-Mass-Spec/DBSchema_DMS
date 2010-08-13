/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Requested_Run_Batch_List_Report as
SELECT RRB.ID,
       RRB.Batch AS Name,
       T.Requests,
       H.Runs,
       F.[First Request],
       F.[Last Request],
       RRB.Requested_Batch_Priority AS [Req. Priority],
       RRB.Requested_Instrument AS Instrument,
       RRB.[Description],
       T_Users.U_Name AS [Owner],
       RRB.Created,
       Case 
			When T.Requests Is Null Then
				-- No active requested runs for this batch
				H.MaxDaysInQueue
			Else
				DATEDIFF(DAY, ISNULL(F.Oldest_Request_Created, H.Oldest_Request_Created), GETDATE()) 
	   End AS [Days In Queue],
       H.MinDaysInQueue AS [Min Days In Queue],
       RRB.Locked,
       RRB.Justification_for_High_Priority,
       RRB.[Comment],
       Case 
			When T.Requests Is Null Then 0	-- No active requested runs for this batch
			When DATEDIFF(DAY, F.Oldest_Request_Created, GETDATE()) <= 30 Then	30	-- Oldest request in batch is 0 to 30 days old
			When DATEDIFF(DAY, F.Oldest_Request_Created, GETDATE()) <= 60 Then	60	-- Oldest request is 30 to 60 days old
			When DATEDIFF(DAY, F.Oldest_Request_Created, GETDATE()) <= 90 Then	90	-- Oldest request is 60 to 90 days old
			Else 120								-- Oldest request is over 90 days old
		End
		AS #DaysInQueue,
		Case 
			When T.Requests Is Null Or  H.MinDaysInQueue Is Null Then 0	-- No active requested runs for this batch
			When H.MinDaysInQueue <= 30 Then	30	-- Oldest request in batch is 0 to 30 days old
			When H.MinDaysInQueue <= 60 Then	60	-- Oldest request is 30 to 60 days old
			When H.MinDaysInQueue <= 90 Then	90	-- Oldest request is 60 to 90 days old
			Else 120								-- Oldest request is over 90 days old
		End
		AS #MinDaysInQueue
FROM T_Requested_Run_Batches RRB
     INNER JOIN T_Users
       ON RRB.Owner = T_Users.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS batchID,
                              COUNT(*) AS Requests
                       FROM T_Requested_Run RR1
                       WHERE (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID ) AS T
       ON T.batchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RR2.RDS_BatchID AS batchID,
                              COUNT(*) AS Runs,
                              MIN(RR2.RDS_created) AS Oldest_Request_Created,
                              MIN(QT.[Days In Queue]) AS MinDaysInQueue,
                              MAX(QT.[Days In Queue]) AS MaxDaysInQueue
                       FROM T_Requested_Run RR2 INNER JOIN V_Requested_Run_Queue_Times QT
                              ON QT.RequestedRun_ID = RR2.ID
                       WHERE (NOT (RR2.DatasetID IS NULL))
                       GROUP BY RR2.RDS_BatchID ) AS H
       ON H.batchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS batchID,
                              MIN(ID) AS [First Request],
                              MAX(ID) AS [Last Request],
                              MIN(RDS_created) as Oldest_Request_Created
                       FROM T_Requested_Run AS RR3
                       WHERE (DatasetID IS NULL) AND
                             (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID ) AS F
       ON F.batchID = RRB.ID
WHERE (RRB.ID > 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [PNL\D3M580] AS [dbo]
GO
