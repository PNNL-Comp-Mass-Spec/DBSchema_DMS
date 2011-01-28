/****** Object:  View [dbo].[V_Custom_Factors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Custom_Factors_List_Report as
SELECT RR.RDS_BatchID AS Batch,
       RR.ID AS Request,
       F.Factor,
       F.Value AS [Value],			
       RR.DatasetID AS Dataset_ID,
       DS.Dataset_Num AS Dataset,
       ISNULL(DSExp.Exp_ID, RRExp.Exp_ID) AS Experiment_ID,
       ISNULL(DSExp.Experiment_Num, RRExp.Experiment_Num) AS Experiment,
       ISNULL(DSCampaign.Campaign_Num, RRCampaign.Campaign_Num) AS Campaign,
       ROW_NUMBER() OVER (ORDER BY RDS_BatchID, RR.ID) AS SortKey
FROM (SELECT TargetID AS RequestID,
             Name AS Factor,
             Value AS [Value]
      FROM T_Factor F
      WHERE (TYPE = 'Run_Request')      
     ) F
     INNER JOIN T_Requested_Run RR
       ON F.RequestID = RR.ID
     LEFT OUTER JOIN T_Dataset DS
       ON RR.DatasetID = DS.Dataset_ID
     INNER JOIN T_Campaign RRCampaign
                INNER JOIN T_Experiments RRExp
                  ON RRCampaign.Campaign_ID = RRExp.EX_campaign_ID
       ON RR.Exp_ID = RRExp.Exp_ID
     LEFT OUTER JOIN T_Experiments DSExp
       ON DS.Exp_ID = DSExp.Exp_ID
     LEFT OUTER JOIN T_Campaign DSCampaign
       ON DSExp.EX_campaign_ID = DSCampaign.Campaign_ID

GO
