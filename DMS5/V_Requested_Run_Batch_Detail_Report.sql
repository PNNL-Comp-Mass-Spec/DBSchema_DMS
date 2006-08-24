/****** Object:  View [dbo].[V_Requested_Run_Batch_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Requested_Run_Batch_Detail_Report
AS
SELECT     dbo.T_Requested_Run_Batches.ID, dbo.T_Requested_Run_Batches.Batch AS Name, dbo.T_Requested_Run_Batches.Description, 
                      dbo.GetBatchRequestedRunList(dbo.T_Requested_Run_Batches.ID) AS Requests, dbo.T_Users.U_Name + ' (' + dbo.T_Users.U_PRN + ')' AS Owner, 
                      dbo.T_Requested_Run_Batches.Created, dbo.T_Requested_Run_Batches.Locked, 
                      dbo.T_Requested_Run_Batches.Last_Ordered AS [Last Ordered]
FROM         dbo.T_Requested_Run_Batches INNER JOIN
                      dbo.T_Users ON dbo.T_Requested_Run_Batches.Owner = dbo.T_Users.ID

GO
