/****** Object:  View [dbo].[V_Dataset_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Dataset_Tracking
AS
SELECT dbo.T_Dataset.Dataset_Num AS Dataset, 
   dbo.T_DatasetStateName.DSS_name AS State, 
   dbo.T_Dataset.DS_created AS Created, 
   dbo.T_Experiments.Experiment_Num AS Experiment, 
   dbo.T_Experiments.EX_created AS [Created (Ex)], 
   dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures], 
   dbo.T_Campaign.Campaign_Num AS Campaign, 
   dbo.T_Dataset.Dataset_ID AS #ID
FROM dbo.T_Dataset INNER JOIN
   dbo.T_Experiments ON 
   dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
   dbo.T_Campaign ON 
   dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID
    INNER JOIN
   dbo.T_DatasetStateName ON 
   dbo.T_Dataset.DS_state_ID = dbo.T_DatasetStateName.Dataset_state_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Tracking] TO [DDL_Viewer] AS [dbo]
GO
