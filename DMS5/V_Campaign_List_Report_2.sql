/****** Object:  View [dbo].[V_Campaign_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Campaign_List_Report_2]
AS
SELECT C.Campaign_ID AS id,
       C.Campaign_Num AS campaign,
       C.CM_State AS state,
       dbo.get_campaign_role_person(C.Campaign_ID, 'Technical Lead') AS technical_lead,
       dbo.get_campaign_role_person(C.Campaign_ID, 'PI') AS pi,
       dbo.get_campaign_role_person(C.Campaign_ID, 'Project Mgr') AS project_mgr,
       C.CM_Project_Num AS project,
       C.CM_Description AS description,
       C.CM_created AS created,
       CT.Most_Recent_Activity AS most_recent_activity,
       C.CM_Organisms AS organisms,
       C.CM_Experiment_Prefixes AS experiment_prefixes,
       C.CM_Fraction_EMSL_Funded AS fraction_emsl_funded,
       C.CM_EUS_Proposal_List AS eus_proposals,
       EUT.Name As eus_usage_type,
       CT.Cell_Culture_Count AS biomaterial,
       CT.Sample_Prep_Request_Count AS sample_prep_requests,
       CT.Experiment_Count AS experiments,
       CT.Run_Request_Count AS requested_runs,
       CT.Dataset_Count AS datasets,
       CT.Job_Count AS analysis_jobs,
	   CT.Data_Package_Count AS data_packages
FROM dbo.T_Campaign C
     INNER JOIN T_EUS_UsageType EUT
       ON C.CM_EUS_Usage_Type = EUT.ID
     LEFT OUTER JOIN dbo.T_Campaign_Tracking CT
       ON C.Campaign_ID = CT.C_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
