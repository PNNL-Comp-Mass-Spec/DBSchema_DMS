/****** Object:  View [dbo].[V_Dataset_Tracking_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_Tracking_Ex
AS
SELECT     dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_DatasetStateName.DSS_name AS State, dbo.T_Dataset.DS_created AS Created, 
                      dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures], A.Jobs AS Analyses, 
                      dbo.T_Campaign.Campaign_Num AS Campaign
FROM         dbo.T_Campaign INNER JOIN
                      dbo.T_Experiments ON dbo.T_Campaign.Campaign_ID = dbo.T_Experiments.EX_campaign_ID INNER JOIN
                      dbo.T_Dataset ON dbo.T_Experiments.Exp_ID = dbo.T_Dataset.Exp_ID INNER JOIN
                      dbo.T_DatasetStateName ON dbo.T_Dataset.DS_state_ID = dbo.T_DatasetStateName.Dataset_state_ID LEFT OUTER JOIN
                          (SELECT     AJ_datasetID AS ID, COUNT(*) AS Jobs
                            FROM          T_Analysis_Job
                            GROUP BY AJ_datasetID) A ON A.ID = dbo.T_Dataset.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Tracking_Ex] TO [DDL_Viewer] AS [dbo]
GO
