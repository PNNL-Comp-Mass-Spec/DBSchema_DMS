/****** Object:  View [dbo].[V_LC_Cart_Block_Loading_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_LC_Cart_Block_Loading_List_Report
as
SELECT     R.RDS_BatchID AS BatchID, B.Batch, R.RDS_Block AS Block, COUNT(R.ID) AS Requests, dbo.GetRequestedRunBlockCartAssignment(R.RDS_BatchID, 
                      R.RDS_Block, 'cart') AS Cart, dbo.GetRequestedRunBlockCartAssignment(R.RDS_BatchID, R.RDS_Block, 'col') AS Col, CONVERT(VARCHAR(12), 
                      R.RDS_BatchID) + '.' + ISNULL(CONVERT(VARCHAR(12), R.RDS_Block), '') AS [#idx]
FROM         T_Requested_Run AS R INNER JOIN
                      T_Requested_Run_Batches AS B ON R.RDS_BatchID = B.ID
WHERE     (R.RDS_Status = 'Active')
GROUP BY R.RDS_BatchID, R.RDS_Block, B.Batch, R.RDS_Status
HAVING      (R.RDS_BatchID <> 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Block_Loading_List_Report] TO [DDL_Viewer] AS [dbo]
GO
