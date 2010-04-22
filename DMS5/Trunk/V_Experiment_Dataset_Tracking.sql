/****** Object:  View [dbo].[V_Experiment_Dataset_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Dataset_Tracking
AS
SELECT     dbo.T_Dataset.Dataset_Num AS Dataset, COUNT(dbo.T_Analysis_Job.AJ_jobID) AS Jobs, dbo.T_Instrument_Name.IN_name AS Instrument, 
                      dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Dataset.DS_created AS Created, 
                      dbo.T_Experiments.Experiment_Num AS [#ExperimentNum]
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Dataset ON dbo.T_Experiments.Exp_ID = dbo.T_Dataset.Exp_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID LEFT OUTER JOIN
                      dbo.T_Analysis_Job ON dbo.T_Dataset.Dataset_ID = dbo.T_Analysis_Job.AJ_datasetID
GROUP BY dbo.T_Dataset.Dataset_Num, dbo.T_Campaign.Campaign_Num, dbo.T_Experiments.Experiment_Num, dbo.T_Instrument_Name.IN_name, 
                      dbo.T_Dataset.DS_created

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Dataset_Tracking] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Dataset_Tracking] TO [PNL\D3M580] AS [dbo]
GO
