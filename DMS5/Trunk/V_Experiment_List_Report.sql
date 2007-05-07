/****** Object:  View [dbo].[V_Experiment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Experiment_List_Report
as
SELECT 
  T_Experiments.Experiment_Num                                 AS Experiment,
  T_Users.U_Name + ' (' + T_Experiments.EX_researcher_PRN + ')' AS Researcher,
  T_Organisms.OG_name                                          AS Organism,
  T_Experiments.EX_reason                                      AS Reason,
  T_Experiments.EX_comment                                     AS COMMENT,
  T_Experiments.EX_created                                     AS Created,
  T_Campaign.Campaign_Num                                      AS Campaign,
  T_Experiments.EX_cell_culture_list                           AS [Cell Cultures],
  T_Experiments.Exp_ID                                         AS [#ID]
FROM   
  T_Experiments
  INNER JOIN T_Campaign
    ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
  INNER JOIN T_Organisms
    ON T_Experiments.EX_organism_ID = T_Organisms.Organism_ID
  INNER JOIN T_Users
    ON T_Experiments.EX_researcher_PRN = T_Users.U_PRN

GO
