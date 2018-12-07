/****** Object:  View [dbo].[V_Experiment_Plex_Members_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Plex_Members_Detail_Report]
AS
SELECT PlexMembers.Plex_Exp_ID AS [Exp_ID],
       E.Experiment_Num AS [Experiment],
       U.Name_with_PRN AS Researcher,
       Org.OG_name AS Organism,
       E.EX_reason AS [Reason for Experiment],
       E.EX_comment AS [Comment],
       C.Campaign_Num AS Campaign,
       BTO.Tissue AS [Plant/Animal Tissue],
       E.EX_Labelling AS Labelling,
       Min(PlexMembers.Entered) AS Created,
       E.EX_Alkylation AS Alkylated,
       E.EX_sample_prep_request_ID AS Request,
       E.EX_created AS [Plex Exp Created],
	   BTO.Identifier AS [Tissue ID],
       dbo.GetExperimentPlexMembers(PlexMembers.Plex_Exp_ID) AS [Plex Members],
       ISNULL(DSCountQ.Datasets, 0) AS Datasets,
       DSCountQ.Most_Recent_Dataset AS [Most Recent Dataset],
       ISNULL(FC.Factor_Count, 0) AS Factors,
       E.Exp_ID AS ID,
       MC.Tag AS Container,
       ML.Tag AS Location,
       E.Ex_Material_Active AS [Material Status],
       E.Last_Used AS [Last Used],
       E.EX_Barcode AS Barcode
FROM T_Experiment_Plex_Members PlexMembers
     INNER JOIN dbo.T_Experiments E
       ON PlexMembers.Plex_Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Experiments ChannelExperiment
       ON PlexMembers.Exp_ID = ChannelExperiment.Exp_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Users AS U ON E.EX_researcher_PRN = U.U_PRN
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON E.EX_Tissue_ID = BTO.Identifier
 INNER JOIN T_Material_Containers AS MC ON E.EX_Container_ID = MC.ID
        INNER JOIN T_Material_Locations AS ML ON MC.Location_ID = ML.ID
        LEFT OUTER JOIN ( SELECT    COUNT(*) AS Datasets ,
                                    MAX(DS_created) AS Most_Recent_Dataset ,
                                    Exp_ID
                          FROM      T_Dataset
                          GROUP BY  Exp_ID
                        ) AS DSCountQ ON DSCountQ.Exp_ID = E.Exp_ID
        LEFT OUTER JOIN V_Factor_Count_By_Experiment AS FC ON FC.Exp_ID = E.Exp_ID
Group By PlexMembers.Plex_Exp_ID,
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
       DSCountQ.Datasets,
       DSCountQ.Most_Recent_Dataset,
       FC.Factor_Count,
       E.Exp_ID,
       MC.Tag,
       ML.Tag,
       E.Ex_Material_Active,
       E.Last_Used,
       E.EX_Barcode


GO
