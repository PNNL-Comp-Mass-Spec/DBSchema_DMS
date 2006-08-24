/****** Object:  View [dbo].[V_Requested_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Requested_Run_Detail_Report
AS
SELECT     T_Requested_Run.ID AS Request, T_Requested_Run.RDS_Name AS Name, T_Campaign.Campaign_Num AS Campaign, 
                      T_Experiments.Experiment_Num AS Experiment, dbo.ExpSampleLocation(T_Requested_Run.Exp_ID) AS [Sample Storage], 
                      T_Requested_Run.RDS_instrument_name AS Instrument, T_DatasetTypeName.DST_name AS Type, T_Users.U_Name AS Requester, 
                      T_Requested_Run.RDS_Oper_PRN AS PRN, T_Requested_Run.RDS_created AS Created, 
                      T_Requested_Run.RDS_instrument_setting AS [Instrument Settings], T_Requested_Run.RDS_special_instructions AS [Special Instructions], 
                      T_Requested_Run.RDS_note AS Note, T_Requested_Run.RDS_comment AS Comment, T_Requested_Run.RDS_priority AS Priority, 
                      T_Requested_Run.RDS_Well_Plate_Num AS [Well Plate], T_Requested_Run.RDS_Well_Num AS Well, 
                      T_Requested_Run_Batches.Batch AS [Batch Name], T_Requested_Run.RDS_BatchID AS Batch, 
                      T_Requested_Run.RDS_Blocking_Factor AS [Blocking Factor], T_Requested_Run.RDS_Block AS Block, 
                      T_Requested_Run.RDS_Run_Order AS [Run Order], T_Requested_Run.RDS_WorkPackage AS [Work Package], 
                      T_EUS_UsageType.Name AS [EUS Usage Type], T_Requested_Run.RDS_EUS_Proposal_ID AS [EUS Proposal], 
                      dbo.GetRequestedRunEUSUsersList(T_Requested_Run.ID, 'V') AS [EUS Users]
FROM         T_DatasetTypeName INNER JOIN
                      T_Requested_Run INNER JOIN
                      T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID ON 
                      T_DatasetTypeName.DST_Type_ID = T_Requested_Run.RDS_type_ID INNER JOIN
                      T_Users ON T_Requested_Run.RDS_Oper_PRN = T_Users.U_PRN INNER JOIN
                      T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID INNER JOIN
                      T_Requested_Run_Batches ON T_Requested_Run.RDS_BatchID = T_Requested_Run_Batches.ID INNER JOIN
                      T_EUS_UsageType ON T_Requested_Run.RDS_EUS_UsageType = T_EUS_UsageType.ID
WHERE     (T_Requested_Run.RDS_priority = 0)

GO
