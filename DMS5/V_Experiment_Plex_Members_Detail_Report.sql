/****** Object:  View [dbo].[V_Experiment_Plex_Members_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Experiment_Plex_Members_Detail_Report]
AS
SELECT PlexMembers.Plex_Exp_ID AS exp_id,
       E.Experiment_Num AS experiment,
       U.Name_with_PRN AS researcher,
       Org.OG_name AS organism,
       E.EX_reason AS reason_for_experiment,
       E.EX_comment AS comment,
       C.Campaign_Num AS campaign,
       BTO.Tissue AS plant_or_animal_tissue,
       E.EX_Labelling AS labelling,
       Min(PlexMembers.Entered) AS created,
       E.EX_Alkylation AS alkylated,
       E.EX_sample_prep_request_ID AS request,
       E.EX_created AS plex_exp_created,
	   BTO.Identifier AS tissue_id,
       dbo.get_experiment_plex_members(PlexMembers.Plex_Exp_ID) AS plex_members,
       ISNULL(CES.dataset_count, 0) AS datasets,
       CES.Most_Recent_Dataset AS most_recent_dataset,
       ISNULL(CES.factor_count, 0) AS factors,
       E.Exp_ID AS id,
       MC.Tag AS container,
       ML.Tag AS location,
       E.Ex_Material_Active AS material_status,
       E.Last_Used AS last_used,
       E.EX_Barcode AS barcode
FROM T_Experiment_Plex_Members PlexMembers
     INNER JOIN dbo.T_Experiments E
       ON PlexMembers.Plex_Exp_ID = E.exp_id
     INNER JOIN dbo.T_Experiments ChannelExperiment
       ON PlexMembers.Exp_ID = ChannelExperiment.exp_id
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Users AS U ON E.EX_researcher_PRN = U.U_PRN
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON E.EX_Tissue_ID = BTO.Identifier
 INNER JOIN T_Material_Containers AS MC ON E.EX_Container_ID = MC.ID
        INNER JOIN T_Material_Locations AS ML ON MC.Location_ID = ML.ID
        LEFT OUTER JOIN T_Cached_Experiment_Stats AS CES ON CES.Exp_ID = E.Exp_ID
GROUP BY PlexMembers.Plex_Exp_ID,
       E.Experiment_Num,
       U.Name_with_PRN,
       Org.OG_name,
       E.EX_reason,
       E.EX_comment,
       E.EX_created,
       C.Campaign_Num,
       BTO.Tissue,
       E.EX_Labelling,
       E.EX_Alkylation,
       E.EX_sample_prep_request_ID,
	   BTO.Identifier,
       CES.Dataset_Count,
       CES.Most_Recent_Dataset,
       CES.Factor_Count,
       E.Exp_ID,
       MC.Tag,
       ML.Tag,
       E.Ex_Material_Active,
       E.Last_Used,
       E.EX_Barcode

GO
