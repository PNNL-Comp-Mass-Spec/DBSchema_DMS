/****** Object:  View [dbo].[V_Run_Assignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Assignment] 
AS 
SELECT RR.ID AS Request,
       '' AS [Sel.],
       RR.RDS_Name AS Name,
       RR.RDS_internal_standard AS [Internal Standard],
       RR.RDS_WorkPackage AS [Work Package],
       EUT.Name AS [Usage],
       RR.RDS_EUS_Proposal_ID AS Proposal,
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       RR.RDS_comment AS [Comment],
       E.Experiment_Num AS Experiment,
       RR.RDS_instrument_name AS Instrument,
       DTN.DST_Name AS [Type],
       RR.RDS_Sec_Sep AS [Separation Group],
       RR.RDS_instrument_setting AS [Inst. Settings],
       RR.RDS_priority AS Priority,
       RR.RDS_Well_Plate_Num AS [Well Plate],
       RR.RDS_BatchID AS Batch,
       RR.RDS_Blocking_Factor AS [Blocking Factor],
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS [Run Order],
       RR.RDS_Status AS Status,
       RR.RDS_NameCode AS [Request Name Code],
       E.Exp_ID AS [Experiment ID]
FROM T_DatasetTypeName AS DTN
     INNER JOIN T_Requested_Run AS RR
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users AS U
       ON RR.RDS_Oper_PRN = U.U_PRN
     INNER JOIN T_Experiments AS E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
WHERE (RR.DatasetID IS NULL)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Assignment] TO [PNL\D3M578] AS [dbo]
GO
