/****** Object:  View [dbo].[V_Scheduled_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Scheduled_Run_Detail_Report
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       dbo.ExpSampleLocation(RR.Exp_ID) AS [Sample Storage],
       RR.RDS_instrument_name AS Instrument,
       DTN.DST_Name AS Type,
       U.U_Name AS Requester,
       RR.RDS_Oper_PRN AS PRN,
       RR.RDS_created AS Created,
       RR.RDS_instrument_setting AS [Instrument Settings],
       RR.RDS_special_instructions AS [Special Instructions],
       RR.RDS_note AS Note,
       RR.RDS_comment AS Comment,
       RR.RDS_priority AS Priority,
       RR.RDS_WorkPackage AS [Work Package],
       RR.RDS_Well_Plate_Num AS [Wellplate Number],
       RR.RDS_Well_Num AS [Well Number],
       LCCart.Cart_Name AS Cart,
       PreDigestIntStd.Name AS [Predigest Int Std],
       PostDigestIntStd.Name AS [Postdigest Int Std],
       RRB.Batch AS [Batch Name],
       RR.RDS_BatchID AS Batch,
       RR.RDS_Blocking_Factor AS [Blocking Factor],
       RR.RDS_Block AS Block,
       RR.RDS_Run_Order AS [Run Order],
       EUT.Name AS [EUS Usage Type],
       RR.RDS_EUS_Proposal_ID AS [EMSL Proposal],
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'V') AS [EUS Users]
FROM dbo.T_DatasetTypeName DTN
     INNER JOIN dbo.T_Requested_Run RR
                INNER JOIN dbo.T_Experiments E
                  ON RR.Exp_ID = E.Exp_ID
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN dbo.T_Users U
       ON RR.RDS_Oper_PRN = U.U_PRN
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Internal_Standards PreDigestIntStd
       ON E.EX_internal_standard_ID = PreDigestIntStd.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Internal_Standards PostDigestIntStd
       ON E.EX_postdigest_internal_std_ID = PostDigestIntStd.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Requested_Run_Batches RRB
       ON RR.RDS_BatchID = RRB.ID
     INNER JOIN dbo.T_LC_Cart LCCart
       ON RR.RDS_Cart_ID = LCCart.ID
     INNER JOIN dbo.T_EUS_UsageType EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
WHERE (RR.RDS_priority > 0)

GO
