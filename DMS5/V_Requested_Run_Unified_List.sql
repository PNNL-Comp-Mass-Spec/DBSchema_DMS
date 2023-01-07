/****** Object:  View [dbo].[V_Requested_Run_Unified_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Unified_List]
AS
SELECT RR.ID AS request,
       RR.RDS_Name AS name,
       RR.RDS_BatchID AS batch_id,
       RRB.Batch AS batch_name,
       RR.DatasetID AS dataset_id,
       D.Dataset_Num AS dataset,
       RR.Exp_ID AS experiment_id,
       E.Experiment_Num AS experiment,
       RR.RDS_Status AS status,
       RR.RDS_Block AS block,
       RR.RDS_Run_Order AS run_order
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
