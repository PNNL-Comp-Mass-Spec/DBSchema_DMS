/****** Object:  View [dbo].[V_Scheduled_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Scheduled_Run_List_Report
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RR.RDS_priority AS Priority,
       RR.RDS_instrument_name AS Instrument,
       DTN.DST_Name AS Type,
       RR.RDS_Sec_Sep AS [Separation Type],
       E.Experiment_Num AS Experiment,
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       RR.RDS_comment AS Comment_____________,
       RR.RDS_note AS Note,
       RR.RDS_WorkPackage AS [Work Package],
       EUT.Name AS Usage,
       RR.RDS_EUS_Proposal_ID AS Proposal,
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well,
       PreDigestIntStd.Name AS [Predigest Int Std],
       PostDigestIntStd.Name AS [Postdigest Int Std],
       LCCart.Cart_Name AS [Cart Name],
       RR.RDS_BatchID AS Batch,
       RR.RDS_Blocking_Factor AS [Blocking Factor],
       RR.RDS_Block AS Block,
       RR.RDS_Run_Order AS [Run Order]
FROM dbo.T_DatasetTypeName DTN
     INNER JOIN dbo.T_Requested_Run RR
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN dbo.T_Users U
       ON RR.RDS_Oper_PRN = U.U_PRN
     INNER JOIN dbo.T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Internal_Standards PreDigestIntStd
       ON E.EX_internal_standard_ID = PreDigestIntStd.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Internal_Standards PostDigestIntStd
       ON E.EX_postdigest_internal_std_ID = PostDigestIntStd.Internal_Std_Mix_ID
     INNER JOIN dbo.T_EUS_UsageType EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     INNER JOIN dbo.T_LC_Cart LCCart
       ON RR.RDS_Cart_ID = LCCart.ID
WHERE (RR.RDS_priority > 0)

GO
