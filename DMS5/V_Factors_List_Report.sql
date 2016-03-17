/****** Object:  View [dbo].[V_Factors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Factors_List_Report] as
SELECT F.Factor,
       F.Value AS [Value],
       RR.ID AS Request,
       RR.RDS_BatchID AS Batch,
       RR.DatasetID,
       DS.Dataset_Num AS Dataset,
       ISNULL(DSExp.Exp_ID, RRExp.Exp_ID) AS ExperimentID,
       ISNULL(DSExp.Experiment_Num, RRExp.Experiment_Num) AS Experiment,
       ISNULL(DSCampaign.Campaign_Num, RRCampaign.Campaign_Num) AS Campaign
FROM (SELECT TargetID AS RequestID,
             Name AS Factor,
             Value AS [Value]
      FROM T_Factor F
      WHERE (TYPE = 'Run_Request')
      UNION
      SELECT ID AS RequestID,
             'Block' AS Factor,
             CONVERT(varchar(12), RDS_Block) AS [Value]
      FROM T_Requested_Run
      WHERE NOT RDS_Block IS NULL
      UNION
      SELECT ID AS RequestID,
             'Requested_Run_Order' AS Factor,
             CONVERT(varchar(12), RDS_Run_Order) AS [Value]
      FROM T_Requested_Run
      WHERE NOT RDS_Run_Order IS NULL 
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
GRANT VIEW DEFINITION ON [dbo].[V_Factors_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Factors_List_Report] TO [PNL\D3M580] AS [dbo]
GO
