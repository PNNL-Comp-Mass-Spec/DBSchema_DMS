/****** Object:  View [dbo].[V_Campaign_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Campaign_Entry as 
SELECT     T_Campaign.Campaign_Num AS campaignNum, T_Campaign.CM_Project_Num AS projectNum, 
                      dbo.GetCampaignRolePersonList(T_Campaign.Campaign_ID, 'PI', 'PRN') AS piPRN, dbo.GetCampaignRolePersonList(T_Campaign.Campaign_ID, 
                      'Project Mgr', 'PRN') AS progmgrPRN, dbo.GetCampaignRolePersonList(T_Campaign.Campaign_ID, 'Technical Lead', 'PRN') AS TechnicalLead, 
                      dbo.GetCampaignRolePersonList(T_Campaign.Campaign_ID, 'Sample Preparation', 'PRN') AS SamplePreparationStaff, 
                      dbo.GetCampaignRolePersonList(T_Campaign.Campaign_ID, 'Dataset Acquisition', 'PRN') AS DatasetAcquisitionStaff, 
                      dbo.GetCampaignRolePersonList(T_Campaign.Campaign_ID, 'Informatics', 'PRN') AS InformaticsStaff, T_Research_Team.Collaborators, 
                      T_Campaign.CM_comment AS comment, T_Campaign.CM_State AS State, T_Campaign.CM_Description AS Description, 
                      T_Campaign.CM_External_Links AS ExternalLinks, T_Campaign.CM_EPR_List AS EPRList, T_Campaign.CM_EUS_Proposal_List AS EUSProposalList, 
                      T_Campaign.CM_Organisms AS Organisms, T_Campaign.CM_Experiment_Prefixes AS ExperimentPrefixes, 
                      T_Data_Release_Restrictions.Name AS DataReleaseRestrictions
FROM         T_Campaign INNER JOIN
                      T_Data_Release_Restrictions ON T_Campaign.CM_Data_Release_Restrictions = T_Data_Release_Restrictions.ID LEFT OUTER JOIN
                      T_Research_Team ON T_Campaign.CM_Research_Team = T_Research_Team.ID

GO
