/****** Object:  View [dbo].[V_Campaign_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Campaign_Entry]
AS
SELECT C.Campaign_Num AS campaign,
       C.CM_Project_Num AS project,
       dbo.get_campaign_role_person_list(C.Campaign_ID, 'PI', 'PRN') AS pi_username,
       dbo.get_campaign_role_person_list(C.Campaign_ID, 'Project Mgr', 'PRN') AS project_mgr,
       dbo.get_campaign_role_person_list(C.Campaign_ID, 'Technical Lead', 'PRN') AS technical_lead,
       dbo.get_campaign_role_person_list(C.Campaign_ID, 'Sample Preparation', 'PRN') AS sample_preparation_staff,
       dbo.get_campaign_role_person_list(C.Campaign_ID, 'Dataset Acquisition', 'PRN') AS dataset_acquisition_staff,
       dbo.get_campaign_role_person_list(C.Campaign_ID, 'Informatics', 'PRN') AS informatics_staff,
       T_Research_Team.collaborators,
       C.CM_comment AS [comment],
       C.CM_State AS state,
       C.CM_Description AS description,
       C.CM_External_Links AS external_links,
       C.CM_EPR_List AS epr_list,
       C.CM_EUS_Proposal_List AS eus_proposal_list,
       C.CM_Fraction_EMSL_Funded AS fraction_emsl_funded,
       EUT.Name As eus_usage_type,
       C.CM_Organisms AS organisms,
       C.CM_Experiment_Prefixes AS experiment_prefixes,
       DRR.Name AS data_release_restriction
FROM T_Campaign C
     INNER JOIN T_Data_Release_Restrictions DRR
       ON C.CM_Data_Release_Restriction = DRR.ID
     INNER JOIN T_EUS_UsageType EUT
       ON C.CM_EUS_Usage_Type = EUT.ID
     LEFT OUTER JOIN T_Research_Team
       ON C.CM_Research_Team = T_Research_Team.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Entry] TO [DDL_Viewer] AS [dbo]
GO
