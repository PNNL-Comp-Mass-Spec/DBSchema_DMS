/****** Object:  View [dbo].[V_Find_Experiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Find_Experiment
as
SELECT 
  dbo.T_Experiments.Experiment_Num       AS Experiment,
  T_Users.U_Name + ' (' + T_Experiments.EX_researcher_PRN + ')' AS Researcher,
  dbo.T_Organisms.OG_name                AS Organism,
  dbo.T_Experiments.EX_reason            AS Reason,
  dbo.T_Experiments.EX_comment           AS COMMENT,
  dbo.T_Experiments.EX_created           AS Created,
  dbo.T_Campaign.Campaign_Num            AS Campaign,
  dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures],
  dbo.T_Experiments.Exp_ID               AS ID
FROM   
  dbo.T_Experiments
  INNER JOIN dbo.T_Campaign
    ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID
  INNER JOIN dbo.T_Organisms
    ON dbo.T_Experiments.EX_organism_ID = dbo.T_Organisms.Organism_ID
  INNER JOIN T_Users
    ON T_Experiments.EX_researcher_PRN = T_Users.U_PRN

GO
