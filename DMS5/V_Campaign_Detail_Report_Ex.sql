/****** Object:  View [dbo].[V_Campaign_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Campaign_Detail_Report_Ex]
AS
SELECT C.Campaign_Num AS Campaign,
       C.CM_Project_Num AS Project,
       C.CM_State AS State,
       T_Data_Release_Restrictions.Name AS [Data Release Restrictions],
       C.CM_Description AS Description,
       C.CM_comment AS [Comment],
       dbo.GetResearchTeamMembershipList(C.CM_Research_Team) AS [Team Members],
       RT.Collaborators,
       C.CM_External_Links AS [External Links],
       C.CM_EPR_List AS [EPR List],
       C.CM_EUS_Proposal_List AS [EUS Proposal],
       C.CM_Fraction_EMSL_Funded AS [Fraction EMSL Funded],
       C.CM_Organisms AS Organisms,
       C.CM_Experiment_Prefixes AS [Experiment Prefixes],
       C.Campaign_ID AS ID,
       C.CM_created AS Created,
       CT.Most_Recent_Activity AS [Most Recent Activity],
       CT.Cell_Culture_Count AS Biomaterial,
       CT.Cell_Culture_Most_Recent AS [Most Recent Biomaterial],
       CT.Sample_Submission_Count As [Samples Submitted],
       CT.Sample_Submission_Most_Recent As [Most Recent Sample Submission],
       CT.Sample_Prep_Request_Count AS [Sample Prep Requests],
       CT.Sample_Prep_Request_Most_Recent AS [Most Recent Sample Prep Request],
       CT.Experiment_Count AS Experiments,
       CT.Experiment_Most_Recent AS [Most Recent Experiment],
       CT.Run_Request_Count AS [Run Requests],
       CT.Run_Request_Most_Recent AS [Most Recent Run Request],
       CT.Dataset_Count AS Datasets,
       CT.Dataset_Most_Recent AS [Most Recent Dataset],
       CT.Job_Count AS [Analysis Jobs],
       CT.Job_Most_Recent AS [Most Recent Analysis Job],
	   CT.Data_Package_Count AS [Data Packages]
FROM T_Campaign AS C
     LEFT OUTER JOIN T_Research_Team AS RT
       ON C.CM_Research_Team = RT.ID
     LEFT OUTER JOIN T_Campaign_Tracking AS CT
       ON CT.C_ID = C.Campaign_ID
     INNER JOIN T_Data_Release_Restrictions
       ON C.CM_Data_Release_Restrictions = T_Data_Release_Restrictions.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Detail_Report_Ex] TO [DDL_Viewer] AS [dbo]
GO
