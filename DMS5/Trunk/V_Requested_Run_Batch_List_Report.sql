/****** Object:  View [dbo].[V_Requested_Run_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Requested_Run_Batch_List_Report
AS
SELECT     dbo.T_Requested_Run_Batches.ID, dbo.T_Requested_Run_Batches.Batch AS Name, T.Requests, H.Runs, 
                      dbo.T_Requested_Run_Batches.Requested_Batch_Priority AS [Requested Priority], dbo.T_Requested_Run_Batches.Description, 
                      dbo.T_Users.U_Name AS Owner, dbo.T_Requested_Run_Batches.Created, dbo.T_Requested_Run_Batches.Locked, 
                      dbo.T_Requested_Run_Batches.Justification_for_High_Priority, dbo.T_Requested_Run_Batches.Comment
FROM         dbo.T_Requested_Run_Batches LEFT OUTER JOIN
                          (SELECT     RDS_BatchID AS batchID, COUNT(*) AS Requests
                            FROM          T_Requested_Run
                            GROUP BY RDS_BatchID) T ON T.batchID = dbo.T_Requested_Run_Batches.ID INNER JOIN
                      dbo.T_Users ON dbo.T_Requested_Run_Batches.Owner = dbo.T_Users.ID LEFT OUTER JOIN
                          (SELECT     RDS_BatchID AS batchID, COUNT(*) AS Runs
                            FROM          T_Requested_Run_History
                            GROUP BY RDS_BatchID) H ON H.batchID = dbo.T_Requested_Run_Batches.ID
WHERE     (dbo.T_Requested_Run_Batches.ID > 0)

GO
