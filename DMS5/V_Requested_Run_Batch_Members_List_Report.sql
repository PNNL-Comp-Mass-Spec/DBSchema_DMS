/****** Object:  View [dbo].[V_Requested_Run_Batch_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Members_List_Report]
As
-- March 2019: This view appears to be unused
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RRB.Batch,
       RR.RDS_Blocking_Factor AS [Blocking Factor],
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS [Run Order],
       E.Experiment_Num AS Experiment,
       RR.RDS_instrument_group AS Instrument,
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       RR.RDS_priority AS Pri,
       RR.RDS_comment AS Comment,
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well,
       RR.RDS_BatchID AS batch_id
FROM T_Requested_Run RR
     INNER JOIN T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_Requested_Run_Batches RRB
       ON RR.RDS_BatchID = RRB.ID
     INNER JOIN T_Users U
       ON E.EX_researcher_PRN = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Members_List_Report] TO [DDL_Viewer] AS [dbo]
GO
