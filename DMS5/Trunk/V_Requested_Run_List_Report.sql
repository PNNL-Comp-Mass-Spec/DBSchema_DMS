/****** Object:  View [dbo].[V_Requested_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Requested_Run_List_Report
AS
SELECT     dbo.T_Requested_Run.ID AS Request, dbo.T_Requested_Run.RDS_Name AS Name, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Requested_Run.RDS_instrument_name AS Instrument, dbo.T_Users.U_Name AS Requester, dbo.T_Requested_Run.RDS_created AS Created, 
                      dbo.T_Requested_Run.RDS_WorkPackage AS [Work Package], dbo.T_EUS_UsageType.Name AS Usage, 
                      dbo.T_Requested_Run.RDS_EUS_Proposal_ID AS Proposal, dbo.T_Requested_Run.RDS_comment AS Comment_____________, 
                      dbo.T_Requested_Run.RDS_note AS Note, dbo.T_DatasetTypeName.DST_name AS Type, dbo.T_Requested_Run.RDS_Well_Plate_Num AS Wellplate, 
                      dbo.T_Requested_Run.RDS_Well_Num AS Well, dbo.T_Requested_Run.RDS_BatchID AS Batch, 
                      dbo.T_Requested_Run.RDS_Blocking_Factor AS [Blocking Factor], dbo.T_Requested_Run.RDS_Block AS Block, 
                      dbo.T_Requested_Run.RDS_Run_Order AS [Run Order]
FROM         dbo.T_DatasetTypeName INNER JOIN
                      dbo.T_Requested_Run ON dbo.T_DatasetTypeName.DST_Type_ID = dbo.T_Requested_Run.RDS_type_ID INNER JOIN
                      dbo.T_Users ON dbo.T_Requested_Run.RDS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_EUS_UsageType ON dbo.T_Requested_Run.RDS_EUS_UsageType = dbo.T_EUS_UsageType.ID
WHERE     (dbo.T_Requested_Run.RDS_priority = 0)

GO
