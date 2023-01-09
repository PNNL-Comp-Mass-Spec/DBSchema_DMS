/****** Object:  View [dbo].[V_Experiment_Plex_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Plex_Members_List_Report]
AS
SELECT PlexMembers.Plex_Exp_ID AS plex_exp_id,
       E.Experiment_Num AS plex_experiment,
       Org.OG_name AS organism,
       PlexMembers.channel,
       ReporterIons.Tag_Name As tag,
       PlexMembers.Exp_ID AS exp_id,
       ChannelExperiment.Experiment_Num AS channel_experiment,
       ChannelTypeName.Channel_Type_Name AS channel_type,
       PlexMembers.comment,
       E.Ex_Created AS created,
       C.Campaign_Num AS campaign,
       BTO.tissue,
       E.EX_Labelling AS labelling,
       ReporterIons.masic_name
FROM T_Experiment_Plex_Members PlexMembers
     INNER JOIN dbo.T_Experiment_Plex_Channel_Type_Name ChannelTypeName
       ON PlexMembers.Channel_Type_ID = ChannelTypeName.channel_type_id
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
