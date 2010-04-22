/****** Object:  View [dbo].[V_Find_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Find_Requested_Run
AS
SELECT     dbo.T_Requested_Run.ID AS Request_ID, dbo.T_Requested_Run.RDS_Name AS Request_Name, dbo.T_Experiments.Experiment_Num AS Experiment,
                       dbo.T_Requested_Run.RDS_instrument_name AS Instrument, dbo.T_Users.U_Name AS Requester, dbo.T_Requested_Run.RDS_created AS Created, 
                      dbo.T_Requested_Run.RDS_WorkPackage AS Work_Package, dbo.T_EUS_UsageType.Name AS Usage, 
                      dbo.T_Requested_Run.RDS_EUS_Proposal_ID AS Proposal, dbo.T_Requested_Run.RDS_comment AS Comment, 
                      dbo.T_Requested_Run.RDS_note AS Note, dbo.T_DatasetTypeName.DST_name AS Run_Type, 
                      dbo.T_Requested_Run.RDS_Well_Plate_Num AS Wellplate, dbo.T_Requested_Run.RDS_Well_Num AS Well, 
                      dbo.T_Requested_Run.RDS_BatchID AS Batch, dbo.T_Requested_Run.RDS_Blocking_Factor AS Blocking_Factor, 
                      dbo.T_Requested_Run.RDS_priority AS Priority, dbo.T_LC_Cart.Cart_Name AS [LC Cart]
FROM         dbo.T_DatasetTypeName INNER JOIN
                      dbo.T_Requested_Run ON dbo.T_DatasetTypeName.DST_Type_ID = dbo.T_Requested_Run.RDS_type_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Requested_Run.RDS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_EUS_UsageType ON dbo.T_Requested_Run.RDS_EUS_UsageType = dbo.T_EUS_UsageType.ID INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_Requested_Run.RDS_Cart_ID = dbo.T_LC_Cart.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Requested_Run] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Requested_Run] TO [PNL\D3M580] AS [dbo]
GO
