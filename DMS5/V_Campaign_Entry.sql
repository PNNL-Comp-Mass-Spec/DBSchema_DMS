/****** Object:  View [dbo].[V_Campaign_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Campaign_Entry] as 
SELECT C.Campaign_Num AS campaignNum,
       C.CM_Project_Num AS projectNum,
       dbo.GetCampaignRolePersonList(C.Campaign_ID, 'PI', 'PRN') AS piPRN,
       dbo.GetCampaignRolePersonList(C.Campaign_ID, 'Project Mgr', 'PRN') AS progmgrPRN,
       dbo.GetCampaignRolePersonList(C.Campaign_ID, 'Technical Lead', 'PRN') AS TechnicalLead,
       dbo.GetCampaignRolePersonList(C.Campaign_ID, 'Sample Preparation', 'PRN') AS SamplePreparationStaff,
       dbo.GetCampaignRolePersonList(C.Campaign_ID, 'Dataset Acquisition', 'PRN') AS DatasetAcquisitionStaff,
       dbo.GetCampaignRolePersonList(C.Campaign_ID, 'Informatics', 'PRN') AS InformaticsStaff,
       T_Research_Team.Collaborators,
       C.CM_comment AS [Comment],
       C.CM_State AS State,
       C.CM_Description AS Description,
       C.CM_External_Links AS ExternalLinks,
       C.CM_EPR_List AS EPRList,
       C.CM_EUS_Proposal_List AS EUSProposalList,
       C.CM_Fraction_EMSL_Funded AS FractionEMSLFunded,
       C.CM_Organisms AS Organisms,
       C.CM_Experiment_Prefixes AS ExperimentPrefixes,
       T_Data_Release_Restrictions.Name AS DataReleaseRestrictions
FROM T_Campaign C
     INNER JOIN T_Data_Release_Restrictions
       ON C.CM_Data_Release_Restrictions = T_Data_Release_Restrictions.ID
     LEFT OUTER JOIN T_Research_Team
       ON C.CM_Research_Team = T_Research_Team.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Entry] TO [DDL_Viewer] AS [dbo]
GO
