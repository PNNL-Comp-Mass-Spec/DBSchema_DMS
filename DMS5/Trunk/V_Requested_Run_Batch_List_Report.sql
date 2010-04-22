/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--
CREATE VIEW V_Requested_Run_Batch_List_Report as
SELECT     T_Requested_Run_Batches.ID, T_Requested_Run_Batches.Batch AS Name, T.Requests, H.Runs, F.[First Request], F.[Last Request], 
                      T_Requested_Run_Batches.Requested_Batch_Priority AS [Req. Priority], T_Requested_Run_Batches.Requested_Instrument AS Instrument, 
                      T_Requested_Run_Batches.Description, T_Users.U_Name AS Owner, T_Requested_Run_Batches.Created, T_Requested_Run_Batches.Locked, 
                      T_Requested_Run_Batches.Justification_for_High_Priority, T_Requested_Run_Batches.Comment
FROM         T_Requested_Run_Batches LEFT OUTER JOIN
                          (SELECT     RDS_BatchID AS batchID, COUNT(*) AS Requests
                            FROM          T_Requested_Run
                            WHERE      (RDS_Status = 'Active')
                            GROUP BY RDS_BatchID) AS T ON T.batchID = T_Requested_Run_Batches.ID INNER JOIN
                      T_Users ON T_Requested_Run_Batches.Owner = T_Users.ID LEFT OUTER JOIN
                          (SELECT     RDS_BatchID AS batchID, COUNT(*) AS Runs
                            FROM          T_Requested_Run AS T_Requested_Run_2
                            WHERE      (NOT (DatasetID IS NULL))
                            GROUP BY RDS_BatchID) AS H ON H.batchID = T_Requested_Run_Batches.ID LEFT OUTER JOIN
                          (SELECT     RDS_BatchID AS batchID, MIN(ID) AS [First Request], MAX(ID) AS [Last Request]
                            FROM          T_Requested_Run AS T_Requested_Run_1
                            WHERE      (DatasetID IS NULL) AND (RDS_Status = 'Active')
                            GROUP BY RDS_BatchID) AS F ON F.batchID = T_Requested_Run_Batches.ID
WHERE     (T_Requested_Run_Batches.ID > 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_List_Report] TO [PNL\D3M580] AS [dbo]
GO
