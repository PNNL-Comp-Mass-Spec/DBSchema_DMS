/****** Object:  View [dbo].[V_CCE_Experiment_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_CCE_Experiment_Summary
AS
SELECT     dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Experiments.EX_reason AS [Exp Reason], 
                      dbo.T_Experiments.EX_comment AS [Exp Comment], dbo.T_Campaign.Campaign_Num AS Campaign, 
                      dbo.T_Experiments.EX_organism_name AS Organism, dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures]
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID

GO
