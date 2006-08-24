/****** Object:  View [dbo].[V_Sample_Prep_Request_Experiments_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Sample_Prep_Request_Experiments_List_Report
AS
SELECT     dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Experiments.EX_researcher_PRN AS Researcher, 
                      dbo.T_Experiments.EX_organism_name AS Organism, dbo.T_Experiments.EX_reason AS Reason, dbo.T_Experiments.EX_comment AS Comment, 
                      dbo.T_Experiments.EX_created AS Created, dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Experiments.EX_cell_culture_list AS [Cell Cultures], 
                      dbo.T_Experiments.EX_sample_prep_request_ID AS [#ID]
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID

GO
