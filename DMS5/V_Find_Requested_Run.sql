/****** Object:  View [dbo].[V_Find_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Find_Requested_Run]
AS
SELECT RR.ID AS Request_ID,
       RR.RDS_Name AS Request_Name,
       E.Experiment_Num AS Experiment,
       RR.RDS_instrument_name AS Instrument,
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       RR.RDS_WorkPackage AS Work_Package,
       EUT.Name AS [Usage],
       RR.RDS_EUS_Proposal_ID AS Proposal,
       RR.RDS_comment AS [Comment],
       RR.RDS_note AS Note,
       DTN.DST_name AS Run_Type,
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well,
       RR.Vialing_Conc,
       RR.Vialing_Vol,
       RR.RDS_BatchID AS Batch,
       RR.RDS_Blocking_Factor AS Blocking_Factor,
       RR.RDS_priority AS Priority,
       LC.Cart_Name AS [LC Cart]
FROM T_DatasetTypeName DTN
     INNER JOIN T_Requested_Run RR
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users U
       ON RR.RDS_Oper_PRN = U.U_PRN
     INNER JOIN T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_EUS_UsageType EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     INNER JOIN T_LC_Cart LC
       ON RR.RDS_Cart_ID = LC.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Requested_Run] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Requested_Run] TO [PNL\D3M580] AS [dbo]
GO
