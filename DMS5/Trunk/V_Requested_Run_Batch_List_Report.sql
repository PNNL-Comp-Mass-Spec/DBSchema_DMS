/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Requested_Run_Batch_List_Report] as
SELECT RRB.ID,
       RRB.Batch AS Name,
       T.Requests,
       H.Runs,
       F.[First Request],
       F.[Last Request],
       RRB.Requested_Batch_Priority AS [Req. Priority],
       CASE WHEN H.Runs > 0 Then
			CASE WHEN H.InstrumentFirst = H.InstrumentLast 
			     THEN H.InstrumentFirst
			     Else H.InstrumentFirst + ' - ' + H.InstrumentLast
			End
		ELSE ''
		End AS Instrument,       
       RRB.Requested_Instrument AS [Inst. Group],
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
       SPQ.[Days in Prep Queue],
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
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              COUNT(*) AS Requests
                       FROM T_Requested_Run RR1
                       WHERE (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID ) AS T
       ON T.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RR2.RDS_BatchID AS BatchID,
                              COUNT(*) AS Runs,
                              MIN(RR2.RDS_created) AS Oldest_Request_Created,
                              MIN(QT.[Days In Queue]) AS MinDaysInQueue,
                              MAX(QT.[Days In Queue]) AS MaxDaysInQueue,
                              MIN(InstName.IN_name) AS InstrumentFirst,
                              MAX(InstName.IN_name) AS InstrumentLast
                       FROM T_Requested_Run RR2 INNER JOIN V_Requested_Run_Queue_Times QT
                              ON QT.RequestedRun_ID = RR2.ID
                            INNER JOIN T_Dataset DS ON RR2.DatasetID = DS.Dataset_ID
                            INNER JOIN T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                       WHERE (NOT (RR2.DatasetID IS NULL))
                       GROUP BY RR2.RDS_BatchID ) AS H
       ON H.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              MIN(ID) AS [First Request],
                              MAX(ID) AS [Last Request],
                              MIN(RDS_created) as Oldest_Request_Created
                       FROM T_Requested_Run AS RR3
                       WHERE (DatasetID IS NULL) AND
                             (RDS_Status = 'Active')
                       GROUP BY RDS_BatchID ) AS F
       ON F.BatchID = RRB.ID
     LEFT OUTER JOIN ( SELECT RR4.RDS_BatchID AS BatchID,
                              MAX(QT.[Days In Queue]) AS [Days in Prep Queue]
                       FROM T_Requested_Run RR4
                            INNER JOIN T_Experiments E
                              ON RR4.Exp_ID = E.Exp_ID
                            INNER JOIN T_Sample_Prep_Request SPR
                              ON E.EX_sample_prep_request_ID = SPR.ID AND
                                 SPR.ID <> 0
                            LEFT OUTER JOIN V_Sample_Prep_Request_Queue_Times QT
                              ON SPR.ID = QT.Request_ID
                       GROUP BY RR4.RDS_BatchID
                      ) AS SPQ
        ON SPQ.BatchID = RRB.ID
WHERE (RRB.ID > 0)



GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [PNL\D3M580] AS [dbo]
GO
