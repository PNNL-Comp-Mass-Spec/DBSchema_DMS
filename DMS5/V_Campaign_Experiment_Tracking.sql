/****** Object:  View [dbo].[V_Campaign_Experiment_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Campaign_Experiment_Tracking
AS
SELECT     dbo.T_Experiments.Experiment_Num AS Experiment, COUNT(dbo.T_Dataset.Dataset_ID) AS Datasets, dbo.T_Experiments.EX_reason AS Reason,
                      dbo.T_Experiments.EX_created AS Created, dbo.T_Campaign.Campaign_Num AS campaign
FROM         dbo.T_Campaign INNER JOIN
                      dbo.T_Experiments ON dbo.T_Campaign.Campaign_ID = dbo.T_Experiments.EX_campaign_ID INNER JOIN
                      dbo.T_Dataset ON dbo.T_Experiments.Exp_ID = dbo.T_Dataset.Exp_ID
GROUP BY dbo.T_Campaign.Campaign_Num, dbo.T_Experiments.Experiment_Num, dbo.T_Experiments.EX_reason, dbo.T_Experiments.EX_created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Experiment_Tracking] TO [DDL_Viewer] AS [dbo]
GO
