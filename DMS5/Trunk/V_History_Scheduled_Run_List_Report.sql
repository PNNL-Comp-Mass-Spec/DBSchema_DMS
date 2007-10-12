/****** Object:  View [dbo].[V_History_Scheduled_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_History_Scheduled_Run_List_Report]
AS
SELECT RRH.ID AS Request,
       RRH.RDS_Name AS Name,
       RRH.RDS_created AS [Req. Created],
       E.Experiment_Num AS Experiment,
       DS.Dataset_Num AS Dataset,
       DS.DS_created AS [DS Created],
       RRH.RDS_WorkPackage AS [Work Package],
       C.Campaign_Num AS Campaign,
       RRH.RDS_Oper_PRN AS Requestor,
       RRH.RDS_instrument_name AS Instrument,
       DTN.DST_Name AS [Run Type],
       RRH.RDS_comment AS Comment,
       RRH.RDS_Run_Start AS [Run Start],
       DATEDIFF(minute, RRH.RDS_Run_Start, RRH.RDS_Run_Finish) AS [Run Length],
       RRH.RDS_BatchID AS Batch,
       RRH.RDS_Blocking_Factor AS [Blocking Factor],
       RRH.RDS_Block AS Block,
       RRH.RDS_Run_Order AS [Run Order],
       RRH.RDS_EUS_Proposal_ID AS Proposal
FROM dbo.T_Requested_Run_History RRH
     INNER JOIN dbo.T_Dataset DS
       ON RRH.DatasetID = DS.Dataset_ID
     INNER JOIN dbo.T_DatasetTypeName DTN
       ON RRH.RDS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Experiments E
       ON RRH.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID

GO
