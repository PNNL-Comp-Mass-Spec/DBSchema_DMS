/****** Object:  View [dbo].[V_Dataset_Tracking_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Tracking_Ex]
AS
SELECT DS.Dataset_Num AS Dataset,
       DSN.DSS_name AS State,
       DS.DS_created AS Created,
       E.Experiment_Num AS Experiment,
       CCE.Cell_Culture_List AS [Cell Cultures],
       JobsPerDataset.Jobs AS Analyses,
       C.Campaign_Num AS Campaign
FROM T_Campaign C
     INNER JOIN T_Experiments E
       ON C.Campaign_ID = E.EX_campaign_ID
     INNER JOIN T_Dataset DS
       ON E.Exp_ID = DS.Exp_ID
     INNER JOIN T_Dataset_State_Name DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     LEFT OUTER JOIN T_Cached_Experiment_Components CCE
       ON E.Exp_ID = CCE.Exp_ID
     LEFT OUTER JOIN ( SELECT AJ_datasetID AS ID,
                              COUNT(*) AS Jobs
                       FROM T_Analysis_Job
                       GROUP BY AJ_datasetID ) JobsPerDataset
       ON JobsPerDataset.ID = DS.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Tracking_Ex] TO [DDL_Viewer] AS [dbo]
GO
