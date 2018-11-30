/****** Object:  View [dbo].[V_Experiment_Plex_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Plex_Members_List_Report]
As
SELECT PlexMembers.Plex_Exp_ID AS Plex_Exp_ID,
       E.Experiment_Num AS [Plex Experiment],
       Org.OG_name AS Organism,
       PlexMembers.Channel,
       ReporterIons.Tag_Name As [Tag],
       PlexMembers.Exp_ID AS Exp_ID,
       ChannelExperiment.Experiment_Num AS [Channel Experiment],
       ChannelTypeName.Channel_Type_Name [Channel Type],
       PlexMembers.[Comment],
       E.Ex_Created AS Created,
       C.Campaign_Num AS Campaign,
       BTO.Tissue,
       E.EX_Labelling AS Labelling,
       ReporterIons.MASIC_Name
FROM T_Experiment_Plex_Members PlexMembers
     INNER JOIN dbo.T_Experiment_Plex_Channel_Type_Name ChannelTypeName
       ON PlexMembers.Channel_Type_ID = ChannelTypeName.Channel_Type_ID
     INNER JOIN dbo.T_Experiments E
       ON PlexMembers.Plex_Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Experiments ChannelExperiment
       ON PlexMembers.Exp_ID = ChannelExperiment.Exp_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID     
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON E.EX_Tissue_ID = BTO.Identifier
     LEFT OUTER JOIN T_Sample_Labelling_Reporter_Ions ReporterIons 
       ON PlexMembers.Channel = ReporterIons.Channel AND
         E.EX_Labelling = ReporterIons.Label


GO
