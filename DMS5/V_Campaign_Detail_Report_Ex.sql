/****** Object:  View [dbo].[V_Campaign_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Campaign_Detail_Report_Ex]
AS
SELECT C.Campaign_Num AS campaign,
       C.CM_Project_Num AS project,
       C.CM_State AS state,
       RR.Name AS data_release_restrictions,
       C.CM_Description AS description,
       C.CM_comment AS comment,
       dbo.GetResearchTeamMembershipList(C.CM_Research_Team) AS team_members,
       RT.collaborators,
       C.CM_External_Links AS external_links,
       C.CM_EPR_List AS epr_list,
       C.CM_EUS_Proposal_List AS eus_proposal,
       C.CM_Fraction_EMSL_Funded AS fraction_emsl_funded,
       EUT.Name As eus_usage_type,
       C.CM_Organisms AS organisms,
       C.CM_Experiment_Prefixes AS experiment_prefixes,
       C.Campaign_ID AS id,
       C.CM_created AS created,
       CT.Most_Recent_Activity AS most_recent_activity,
       CT.Cell_Culture_Count AS biomaterial,
       CT.Cell_Culture_Most_Recent AS most_recent_biomaterial,
       CT.Sample_Submission_Count As samples_submitted,
       CT.Sample_Submission_Most_Recent As most_recent_sample_submission,
       CT.Sample_Prep_Request_Count AS sample_prep_requests,
       CT.Sample_Prep_Request_Most_Recent AS most_recent_sample_prep_request,
       CT.Experiment_Count AS experiments,
       CT.Experiment_Most_Recent AS most_recent_experiment,
       CT.Run_Request_Count AS run_requests,
       CT.Run_Request_Most_Recent AS most_recent_run_request,
       CT.Dataset_Count AS datasets,
       CT.Dataset_Most_Recent AS most_recent_dataset,
       CT.Job_Count AS analysis_jobs,
       CT.Job_Most_Recent AS most_recent_analysis_job,
	   CT.Data_Package_Count AS data_packages,
       dbo.GetCampaignWorkPackageList(C.Campaign_Num) AS work_packages
FROM T_Campaign AS C
     INNER JOIN T_Data_Release_Restrictions RR
       ON C.CM_Data_Release_Restrictions = RR.ID
     INNER JOIN T_EUS_UsageType EUT
       ON C.CM_EUS_Usage_Type = EUT.ID
     LEFT OUTER JOIN T_Research_Team AS RT
       ON C.CM_Research_Team = RT.ID
     LEFT OUTER JOIN T_Campaign_Tracking AS CT
       ON CT.C_ID = C.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Detail_Report_Ex] TO [DDL_Viewer] AS [dbo]
GO
