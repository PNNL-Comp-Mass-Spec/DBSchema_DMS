/****** Object:  View [dbo].[V_Requested_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Requested_Run_Detail_Report
AS
SELECT     RR.ID AS Request, RR.RDS_Name AS Name, RR.RDS_priority AS Priority, C.Campaign_Num AS Campaign, E.Experiment_Num AS Experiment, 
                      dbo.ExpSampleLocation(RR.Exp_ID) AS [Sample Storage], RR.RDS_instrument_name AS Instrument, DTN.DST_Name AS Type, 
                      RR.RDS_Sec_Sep AS [Separation Type], U.U_Name AS Requester, RR.RDS_Oper_PRN AS PRN, RR.RDS_created AS Created, 
                      RR.RDS_instrument_setting AS [Instrument Settings], RR.RDS_special_instructions AS [Special Instructions], RR.RDS_note AS Note, 
                      RR.RDS_comment AS Comment, RR.RDS_Well_Plate_Num AS [Well Plate], RR.RDS_Well_Num AS Well, RRB.Batch AS [Batch Name], 
                      RR.RDS_BatchID AS Batch, RR.RDS_Blocking_Factor AS [Blocking Factor], RR.RDS_Block AS Block, RR.RDS_Run_Order AS [Run Order], 
                      RR.RDS_WorkPackage AS [Work Package], EUT.Name AS [EUS Usage Type], RR.RDS_EUS_Proposal_ID AS [EUS Proposal], 
                      dbo.GetRequestedRunEUSUsersList(RR.ID, 'V') AS [EUS Users], dbo.T_Attachments.Attachment_Name AS [MRM Transistion List]
FROM         dbo.T_DatasetTypeName AS DTN INNER JOIN
                      dbo.T_Requested_Run AS RR INNER JOIN
                      dbo.T_Experiments AS E ON RR.Exp_ID = E.Exp_ID ON DTN.DST_Type_ID = RR.RDS_type_ID INNER JOIN
                      dbo.T_Users AS U ON RR.RDS_Oper_PRN = U.U_PRN INNER JOIN
                      dbo.T_Campaign AS C ON E.EX_campaign_ID = C.Campaign_ID INNER JOIN
                      dbo.T_Requested_Run_Batches AS RRB ON RR.RDS_BatchID = RRB.ID INNER JOIN
                      dbo.T_EUS_UsageType AS EUT ON RR.RDS_EUS_UsageType = EUT.ID LEFT OUTER JOIN
                      dbo.T_Attachments ON RR.RDS_MRM_Attachment = dbo.T_Attachments.ID


GO
