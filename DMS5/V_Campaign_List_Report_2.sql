/****** Object:  View [dbo].[V_Campaign_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Campaign_List_Report_2]
AS
SELECT C.Campaign_ID AS ID,
       C.Campaign_Num AS Campaign,
       C.CM_State AS State,
       dbo.GetCampaignRolePerson(C.Campaign_ID, 'Technical Lead') AS [Technical Lead],
       dbo.GetCampaignRolePerson(C.Campaign_ID, 'PI') AS PI,
       dbo.GetCampaignRolePerson(C.Campaign_ID, 'Project Mgr') AS ProjectMgr,
       C.CM_Project_Num AS Project,
       C.CM_Description AS Description,
       C.CM_created AS Created,
       CT.Most_Recent_Activity AS [Most Recent Activity],
       C.CM_Organisms AS Organisms,
       C.CM_Experiment_Prefixes AS [Experiment Prefixes],
       C.CM_Fraction_EMSL_Funded AS [Fraction EMSL Funded],
       C.CM_EUS_Proposal_List AS [EUS Proposals],
       EUT.Name As [EUS Usage Type],
       CT.Cell_Culture_Count AS Biomaterial,
       CT.Sample_Prep_Request_Count AS [Sample Prep Requests],
       CT.Experiment_Count AS Experiments,
       CT.Run_Request_Count AS [Requested Runs],
       CT.Dataset_Count AS Datasets,
       CT.Job_Count AS [Analysis Jobs],
	   CT.Data_Package_Count AS [Data Packages]
FROM dbo.T_Campaign C
     INNER JOIN T_EUS_UsageType EUT
       ON C.CM_EUS_Usage_Type = EUT.ID
     LEFT OUTER JOIN dbo.T_Campaign_Tracking CT
       ON C.Campaign_ID = CT.C_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
