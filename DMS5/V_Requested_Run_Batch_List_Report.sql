/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Requested_Run_Batch_List_Report
AS

SELECT     
T_Requested_Run_Batches.ID, T_Requested_Run_Batches.Batch AS Name, T.Requests, H.Runs, 
T_Requested_Run_Batches.Description, T_Users.U_PRN AS OwnerPRN, T_Requested_Run_Batches.Created, 
T_Requested_Run_Batches.Locked
FROM        
 T_Requested_Run_Batches LEFT OUTER JOIN
                          (SELECT     RDS_BatchID AS batchID, COUNT(*) AS Requests
                            FROM          T_Requested_Run
                            GROUP BY RDS_BatchID) T ON T.batchID = T_Requested_Run_Batches.ID INNER JOIN
                      T_Users ON T_Requested_Run_Batches.Owner = T_Users.ID LEFT OUTER JOIN
                          (SELECT     RDS_BatchID AS batchID, COUNT(*) AS Runs
                            FROM          T_Requested_Run_History
                            GROUP BY RDS_BatchID) H ON H.batchID = T_Requested_Run_Batches.ID
WHERE     (T_Requested_Run_Batches.ID > 0)

GO
