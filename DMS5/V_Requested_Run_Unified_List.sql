/****** Object:  View [dbo].[V_Requested_Run_Unified_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Unified_List]  as
SELECT     T_Requested_Run.RDS_BatchID AS BatchID, T_Requested_Run.RDS_Name AS Name, T_Requested_Run.RDS_Status AS Status, 
                      T_Requested_Run.ID AS Request, T_Requested_Run.DatasetID AS Dataset_ID, T_Dataset.Dataset_Num AS Dataset, 
                      T_Experiments.Experiment_Num AS Experiment, T_Requested_Run.Exp_ID AS Experiment_ID, T_Requested_Run.RDS_Block AS Block, 
                      T_Requested_Run.RDS_Run_Order AS [Run Order]
FROM         T_Requested_Run INNER JOIN
                      T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID LEFT OUTER JOIN
                      T_Dataset ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID  

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Unified_List] TO [DDL_Viewer] AS [dbo]
GO
