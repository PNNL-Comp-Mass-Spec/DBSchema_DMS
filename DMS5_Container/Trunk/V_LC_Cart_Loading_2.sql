/****** Object:  View [dbo].[V_LC_Cart_Loading_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW  V_LC_Cart_Loading_2
AS 
SELECT
  T_LC_Cart.Cart_Name AS Cart,
  T_Requested_Run.RDS_Name AS Name,
  T_Requested_Run.ID AS Request,
  T_Requested_Run.RDS_Cart_Col AS Column#,
  T_Experiments.Experiment_Num AS Experiment,
  T_Requested_Run.RDS_priority AS Priority,
  T_DatasetTypeName.DST_Name AS Type,
  T_Requested_Run.RDS_BatchID AS Batch,
  T_Requested_Run.RDS_Block AS Block,
  T_Requested_Run.RDS_Run_Order AS [Run Order],
  T_EUS_UsageType.Name AS [EMSL Usage Type],
  T_Requested_Run.RDS_EUS_Proposal_ID AS [EMSL Proposal ID],
  dbo.GetRequestedRunEUSUsersList(T_Requested_Run.ID, 'I') AS [EMSL User List]
FROM
  T_Requested_Run
  INNER JOIN T_LC_Cart ON T_Requested_Run.RDS_Cart_ID = T_LC_Cart.ID
  INNER JOIN T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID
  INNER JOIN T_DatasetTypeName ON T_Requested_Run.RDS_type_ID = T_DatasetTypeName.DST_Type_ID
  INNER JOIN T_EUS_UsageType ON T_Requested_Run.RDS_EUS_UsageType = T_EUS_UsageType.ID
WHERE
  ( T_Requested_Run.RDS_Status = 'Active' )  

GO
