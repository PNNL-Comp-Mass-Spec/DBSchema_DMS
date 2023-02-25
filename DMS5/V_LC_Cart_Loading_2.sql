/****** Object:  View [dbo].[V_LC_Cart_Loading_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW  V_LC_Cart_Loading_2
AS
SELECT
  T_LC_Cart.Cart_Name AS cart,
  T_Requested_Run.RDS_Name AS name,
  T_Requested_Run.ID AS request,
  T_Requested_Run.RDS_Cart_Col AS column_number,
  T_Experiments.Experiment_Num AS experiment,
  T_Requested_Run.RDS_priority AS priority,
  T_DatasetTypeName.DST_Name AS type,
  T_Requested_Run.RDS_BatchID AS batch,
  T_Requested_Run.RDS_Block AS block,
  T_Requested_Run.RDS_Run_Order AS run_order,
  T_EUS_UsageType.Name AS emsl_usage_type,
  T_Requested_Run.RDS_EUS_Proposal_ID AS emsl_proposal_id,
  dbo.get_requested_run_eus_users_list(T_Requested_Run.id, 'I') AS emsl_user_list
FROM
  T_Requested_Run
  INNER JOIN T_LC_Cart ON T_Requested_Run.RDS_Cart_ID = T_LC_Cart.ID
  INNER JOIN T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID
  INNER JOIN T_DatasetTypeName ON T_Requested_Run.RDS_type_ID = T_DatasetTypeName.DST_Type_ID
  INNER JOIN T_EUS_UsageType ON T_Requested_Run.RDS_EUS_UsageType = T_EUS_UsageType.ID
WHERE
  ( T_Requested_Run.RDS_Status = 'Active' )

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Loading_2] TO [DDL_Viewer] AS [dbo]
GO
