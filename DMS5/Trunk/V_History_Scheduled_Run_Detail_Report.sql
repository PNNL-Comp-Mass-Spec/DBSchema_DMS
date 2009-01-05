/****** Object:  View [dbo].[V_History_Scheduled_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_History_Scheduled_Run_Detail_Report
AS
SELECT     RRH.ID AS Request, RRH.RDS_Name AS Name, RRH.RDS_created AS [Request Created], E.Experiment_Num AS Experiment, 
                      DS.Dataset_Num AS Dataset, DS.DS_created AS [Dataset Created], dbo.T_Users.U_Name + ' (' + RRH.RDS_Oper_PRN + ')' AS Requestor, 
                      RRH.RDS_instrument_name AS Instrument, DTN.DST_Name AS [Run Type], RRH.RDS_Sec_Sep AS [Separation Type], 
                      RRH.RDS_instrument_setting AS [Instrument Settings], RRH.RDS_special_instructions AS [Special Instructions], RRH.RDS_comment AS COMMENT, 
                      RRH.RDS_note AS Note, RRH.RDS_internal_standard AS [Internal Standard], LCCart.Cart_Name AS Cart, RRH.RDS_Run_Start AS [Run Start], 
                      RRH.RDS_Run_Finish AS [Run Finish], DATEDIFF(MINUTE, RRH.RDS_Run_Start, RRH.RDS_Run_Finish) AS [Run Length], 
                      RRH.RDS_WorkPackage AS [Work Package], RRH.RDS_BatchID AS Batch, RRH.RDS_Blocking_Factor AS [Blocking Factor], 
                      RRH.RDS_Block AS BLOCK, RRH.RDS_Run_Order AS [Run Order], EUT.Name AS [EUS Usage Type], RRH.RDS_EUS_Proposal_ID AS [EMSL Proposal], 
                      dbo.GetRequestedRunHistoryEUSUsersList(RRH.ID, 'V') AS [EUS Users]
FROM         dbo.T_Requested_Run_History AS RRH INNER JOIN
                      dbo.T_Dataset AS DS ON RRH.DatasetID = DS.Dataset_ID INNER JOIN
                      dbo.T_DatasetTypeName AS DTN ON RRH.RDS_type_ID = DTN.DST_Type_ID INNER JOIN
                      dbo.T_Experiments AS E ON RRH.Exp_ID = E.Exp_ID INNER JOIN
                      dbo.T_EUS_UsageType AS EUT ON RRH.RDS_EUS_UsageType = EUT.ID INNER JOIN
                      dbo.T_LC_Cart AS LCCart ON RRH.RDS_Cart_ID = LCCart.ID INNER JOIN
                      dbo.T_Users ON RRH.RDS_Oper_PRN = dbo.T_Users.U_PRN

GO
