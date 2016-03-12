/****** Object:  View [dbo].[V_Experiment_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_Detail_Report
AS
SELECT     dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Experiments.EX_researcher_PRN AS Researcher, 
                      dbo.T_Organisms.OG_name AS Organism, dbo.T_Experiments.EX_reason AS Reason, dbo.T_Experiments.EX_comment AS Comment, 
                      dbo.T_Experiments.EX_created AS Created, dbo.T_Experiments.EX_sample_concentration AS [Sample Concentration], 
                      dbo.T_Experiments.EX_lab_notebook_ref AS [Lab Notebook], dbo.T_Campaign.Campaign_Num AS Campaign, 
                      dbo.T_Experiments.EX_Labelling AS Labelling
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
