/****** Object:  View [dbo].[V_Experiment_Dataset_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Dataset_Tracking
AS
SELECT dbo.T_Dataset.Dataset_Num AS dataset,
       COUNT(dbo.T_Analysis_Job.AJ_jobID) AS jobs,
       dbo.T_Instrument_Name.IN_name AS instrument,
       dbo.T_Campaign.Campaign_Num AS campaign,
       dbo.T_Dataset.DS_created AS created,
       dbo.T_Experiments.Experiment_Num AS experiment
FROM dbo.T_Experiments
     INNER JOIN dbo.T_Dataset
       ON dbo.T_Experiments.Exp_ID = dbo.T_Dataset.Exp_ID
     INNER JOIN dbo.T_Campaign
       ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID
     INNER JOIN dbo.T_Instrument_Name
       ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
     LEFT OUTER JOIN dbo.T_Analysis_Job
       ON dbo.T_Dataset.Dataset_ID = dbo.T_Analysis_Job.AJ_datasetID
GROUP BY dbo.T_Dataset.Dataset_Num, dbo.T_Campaign.Campaign_Num, dbo.T_Experiments.Experiment_Num,
         dbo.T_Instrument_Name.IN_name, dbo.T_Dataset.DS_created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Dataset_Tracking] TO [DDL_Viewer] AS [dbo]
GO
