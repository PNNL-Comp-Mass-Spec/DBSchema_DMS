/****** Object:  View [dbo].[V_History_Scheduled_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_History_Scheduled_Run_Detail_Report
AS
SELECT     dbo.T_Requested_Run_History.ID AS Request, dbo.T_Requested_Run_History.RDS_Name AS Name, 
                      dbo.T_Requested_Run_History.RDS_created AS [Request Created], dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.DS_created AS [Dataset Created], 
                      dbo.T_Requested_Run_History.RDS_Oper_PRN AS Requestor, dbo.T_Requested_Run_History.RDS_instrument_name AS Instrument, 
                      dbo.T_DatasetTypeName.DST_name AS [Run Type], dbo.T_Requested_Run_History.RDS_instrument_setting AS [Instrument Settings], 
                      dbo.T_Requested_Run_History.RDS_special_instructions AS [Special Instructions], dbo.T_Requested_Run_History.RDS_comment AS Comment, 
                      dbo.T_Requested_Run_History.RDS_note AS Note, dbo.T_Requested_Run_History.RDS_internal_standard AS [Internal Standard], 
                      dbo.T_LC_Cart.Cart_Name AS Cart, dbo.T_Requested_Run_History.RDS_Run_Start AS [Run Start], 
                      dbo.T_Requested_Run_History.RDS_Run_Finish AS [Run Finish], dbo.T_Requested_Run_History.RDS_WorkPackage AS [Work Package], 
                      dbo.T_Requested_Run_History.RDS_BatchID AS Batch, dbo.T_Requested_Run_History.RDS_Blocking_Factor AS [Blocking Factor], 
                      dbo.T_Requested_Run_History.RDS_Block AS Block, dbo.T_Requested_Run_History.RDS_Run_Order AS [Run Order], 
                      dbo.T_EUS_UsageType.Name AS [EUS Usage Type], dbo.T_Requested_Run_History.RDS_EUS_Proposal_ID AS [EMSL Proposal], 
                      dbo.GetRequestedRunHistoryEUSUsersList(dbo.T_Requested_Run_History.ID, 'V') AS [EUS Users]
FROM         dbo.T_Requested_Run_History INNER JOIN
                      dbo.T_Dataset ON dbo.T_Requested_Run_History.DatasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_DatasetTypeName ON dbo.T_Requested_Run_History.RDS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run_History.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_EUS_UsageType ON dbo.T_Requested_Run_History.RDS_EUS_UsageType = dbo.T_EUS_UsageType.ID INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_Requested_Run_History.RDS_Cart_ID = dbo.T_LC_Cart.ID

GO
