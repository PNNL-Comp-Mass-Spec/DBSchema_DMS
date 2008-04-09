/****** Object:  View [dbo].[V_Requested_Run_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Requested_Run_List_Report_2
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       E.Experiment_Num AS Experiment,
       RR.RDS_instrument_name AS Instrument,
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       RR.RDS_WorkPackage AS [Work Package],
       EUT.Name AS Usage,
       RR.RDS_EUS_Proposal_ID AS Proposal,
       RR.RDS_comment AS Comment_____________,
       RR.RDS_note AS Note,
       DTN.DST_Name AS Type,
       RR.RDS_Sec_Sep AS [Separation Type],
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well,
       RR.RDS_BatchID AS Batch,
       RR.RDS_Blocking_Factor AS [Blocking Factor],
       RR.RDS_Block AS Block,
       RR.RDS_Run_Order AS [Run Order]
FROM dbo.T_DatasetTypeName AS DTN
     INNER JOIN dbo.T_Requested_Run AS RR
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN dbo.T_Users AS U
       ON RR.RDS_Oper_PRN = U.U_PRN
     INNER JOIN dbo.T_Experiments AS E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
WHERE (RR.RDS_priority = 0)

GO
