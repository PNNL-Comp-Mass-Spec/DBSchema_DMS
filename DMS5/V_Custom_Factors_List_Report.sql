/****** Object:  View [dbo].[V_Custom_Factors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Custom_Factors_List_Report] as
SELECT RR.RDS_BatchID AS Batch,
       RR.ID AS Request,
       F.Name AS Factor,
       F.Value AS [Value],
       RR.DatasetID AS Dataset_ID,
       DS.Dataset_Num AS Dataset,
       COALESCE(DSExp.Exp_ID, RRExp.Exp_ID) AS Experiment_ID,
       COALESCE(DSExp.Experiment_Num, RRExp.Experiment_Num) AS Experiment,
       COALESCE(DSCampaign.Campaign_Num, RRCampaign.Campaign_Num) AS Campaign
FROM T_Requested_Run AS RR
     INNER JOIN T_Factor AS F
       ON F.TargetID = RR.ID AND
          F.Type = 'Run_Request'
     INNER JOIN T_Experiments RRExp
       ON RR.Exp_ID = RRExp.Exp_ID
     INNER JOIN T_Campaign RRCampaign
       ON RRCampaign.Campaign_ID = RRExp.EX_campaign_ID
     LEFT OUTER JOIN T_Dataset DS
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN T_Experiments DSExp
       ON DS.Exp_ID = DSExp.Exp_ID
     LEFT OUTER JOIN T_Campaign DSCampaign
       ON DSExp.EX_campaign_ID = DSCampaign.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Custom_Factors_List_Report] TO [DDL_Viewer] AS [dbo]
GO
