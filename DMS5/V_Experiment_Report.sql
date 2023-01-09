/****** Object:  View [dbo].[V_Experiment_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Report
AS
SELECT dbo.T_Experiments.Experiment_Num AS experiment,
       dbo.T_Experiments.EX_researcher_PRN AS researcher,
       dbo.T_Organisms.OG_name AS organism,
       dbo.T_Experiments.EX_comment AS comment,
       dbo.T_Experiments.EX_created AS created,
       dbo.T_Campaign.Campaign_Num AS campaign,
       dbo.T_Experiments.Exp_ID AS id
FROM dbo.T_Experiments
     INNER JOIN dbo.T_Campaign
       ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID
     INNER JOIN dbo.T_Organisms
       ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Report] TO [DDL_Viewer] AS [dbo]
GO
