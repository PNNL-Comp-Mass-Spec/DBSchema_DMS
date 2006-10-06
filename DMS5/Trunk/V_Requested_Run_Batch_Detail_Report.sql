/****** Object:  View [dbo].[V_Requested_Run_Batch_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW dbo.V_Requested_Run_Batch_Detail_Report
AS
SELECT R.ID, R.Batch AS Name, R.Description, 
       dbo.GetBatchRequestedRunList(R.ID) AS Requests, U.U_Name + ' (' + U.U_PRN + ')' AS Owner, 
       R.Created, R.Locked, 
       R.Last_Ordered AS [Last Ordered],
       R.Requested_Batch_Priority AS [Requested Batch Priority],
       R.Actual_Batch_Priority AS [Actual Batch Priority],
       R.Requested_Completion_Date AS [Requested Completion Date],
       R.Justification_for_High_Priority AS [Justification for High Priority],
       R.Comment AS [Comment]
FROM T_Requested_Run_Batches R 
     JOIN T_Users U ON R.Owner = U.ID


GO
