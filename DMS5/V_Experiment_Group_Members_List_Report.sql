/****** Object:  View [dbo].[V_Experiment_Group_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Experiment_Group_Members_List_Report
AS
SELECT     dbo.T_Experiments.Experiment_Num AS Experiment, 
                      CASE WHEN dbo.T_Experiment_Groups.Parent_Exp_ID = T_Experiments.Exp_ID THEN 'Parent' ELSE 'Child' END AS Member, 
                      dbo.T_Experiments.EX_researcher_PRN AS Researcher, dbo.T_Organisms.OG_name AS Organism, dbo.T_Experiments.EX_reason AS Reason, 
                      dbo.T_Experiments.EX_comment AS Comment, dbo.T_Experiment_Groups.Group_ID AS [#Group]
FROM         dbo.T_Experiments INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Experiment_Group_Members ON dbo.T_Experiments.Exp_ID = dbo.T_Experiment_Group_Members.Exp_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID LEFT OUTER JOIN
                      dbo.T_Experiment_Groups ON dbo.T_Experiment_Group_Members.Group_ID = dbo.T_Experiment_Groups.Group_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Group_Members_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Group_Members_List_Report] TO [PNL\D3M580] AS [dbo]
GO
