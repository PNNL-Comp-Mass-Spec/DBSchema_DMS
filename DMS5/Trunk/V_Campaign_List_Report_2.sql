/****** Object:  View [dbo].[V_Campaign_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Campaign_List_Report_2
AS
SELECT     dbo.T_Campaign.Campaign_ID AS ID, dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Campaign.CM_State AS State, 
                      dbo.GetCampaignRolePerson(dbo.T_Campaign.Campaign_ID, 'Technical Lead') AS [Technical Lead], 
                      dbo.GetCampaignRolePerson(dbo.T_Campaign.Campaign_ID, 'PI') AS PI, dbo.GetCampaignRolePerson(dbo.T_Campaign.Campaign_ID, 'Project Mgr') 
                      AS ProjectMgr, dbo.T_Campaign.CM_Project_Num AS Project, dbo.T_Campaign.CM_Description AS Description, 
                      dbo.T_Campaign.CM_created AS Created, dbo.T_Campaign_Tracking.Most_Recent_Activity AS [Most Recent Activity], 
                      dbo.T_Campaign.CM_Organisms AS Organisms, dbo.T_Campaign.CM_Experiment_Prefixes AS [Experiment Prefixes], 
                      dbo.T_Campaign_Tracking.Cell_Culture_Count AS Biomaterial, dbo.T_Campaign_Tracking.Sample_Prep_Request_Count AS [Sample Prep Requests], 
                      dbo.T_Campaign_Tracking.Experiment_Count AS Experiments, dbo.T_Campaign_Tracking.Run_Request_Count AS [Requested Runs], 
                      dbo.T_Campaign_Tracking.Dataset_Count AS Datasets, dbo.T_Campaign_Tracking.Job_Count AS [Analysis Jobs]
FROM         dbo.T_Campaign LEFT OUTER JOIN
                      dbo.T_Campaign_Tracking ON dbo.T_Campaign.Campaign_ID = dbo.T_Campaign_Tracking.C_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_List_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_List_Report_2] TO [PNL\D3M580] AS [dbo]
GO
