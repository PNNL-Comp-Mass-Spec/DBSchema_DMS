/****** Object:  View [dbo].[V_Requested_Run_Unified_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Unified_List] 
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RR.RDS_BatchID AS BatchID,
       RRB.Batch AS [Batch Name],
       RR.DatasetID AS Dataset_ID,
       D.Dataset_Num AS Dataset,
       RR.Exp_ID AS Experiment_ID,
       E.Experiment_Num AS Experiment,
       RR.RDS_Status AS Status,
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS [Run Order]
FROM T_Requested_Run RR
     INNER JOIN T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     LEFT OUTER JOIN T_Dataset D
       ON RR.DatasetID = D.Dataset_ID
     LEFT OUTER JOIN T_Requested_Run_Batches RRB
       ON RR.RDS_BatchID = RRB.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Unified_List] TO [DDL_Viewer] AS [dbo]
GO
