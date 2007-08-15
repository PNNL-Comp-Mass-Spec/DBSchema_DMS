/****** Object:  View [dbo].[V_Experiment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_List_Report
AS
SELECT dbo.T_Experiments.Experiment_Num AS Experiment, 
    dbo.T_Users.U_Name + ' (' + dbo.T_Experiments.EX_researcher_PRN 
     + ')' AS Researcher, 
    dbo.T_Organisms.OG_name AS Organism,
    dbo.T_Experiments.EX_reason AS Reason, 
    dbo.T_Experiments.EX_comment AS Comment,
    dbo.T_Experiments.EX_sample_concentration AS Concentration, 
    dbo.T_Experiments.EX_created AS Created,
    dbo.T_Campaign.Campaign_Num AS Campaign, 
    dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures], 
    dbo.T_Experiments.Exp_ID AS [#ID]
FROM dbo.T_Experiments
     INNER JOIN dbo.T_Campaign
      ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID
     INNER JOIN dbo.T_Organisms
      ON dbo.T_Experiments.EX_organism_ID = dbo.T_Organisms.Organism_ID
     INNER JOIN dbo.T_Users
      ON dbo.T_Experiments.EX_researcher_PRN = dbo.T_Users.U_PRN

GO
