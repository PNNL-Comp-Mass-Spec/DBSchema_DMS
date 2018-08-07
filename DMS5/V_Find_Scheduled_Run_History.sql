/****** Object:  View [dbo].[V_Find_Scheduled_Run_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Find_Scheduled_Run_History]
AS
SELECT RR.ID AS Request_ID,
       RR.RDS_Name AS Request_Name,
       RR.RDS_created AS Req_Created,
       E.Experiment_Num AS Experiment,
       DS.Dataset_Num AS Dataset,
       DS.DS_created,
       RR.RDS_WorkPackage AS Work_Package,
       dbo.T_Campaign.Campaign_Num AS Campaign,
       RR.RDS_Requestor_PRN AS Requestor,
       RR.RDS_instrument_name AS Instrument,
       DTN.DST_Name AS Run_Type,
       RR.RDS_comment AS [Comment],
       RR.RDS_BatchID AS Batch,
       RR.RDS_Blocking_Factor AS Blocking_Factor
FROM dbo.T_Requested_Run RR
     INNER JOIN dbo.T_Dataset DS
       ON RR.DatasetID = DS.Dataset_ID
     INNER JOIN dbo.T_DatasetTypeName DTN
       ON RR.RDS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Campaign
       ON E.EX_campaign_ID = dbo.T_Campaign.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Scheduled_Run_History] TO [DDL_Viewer] AS [dbo]
GO
