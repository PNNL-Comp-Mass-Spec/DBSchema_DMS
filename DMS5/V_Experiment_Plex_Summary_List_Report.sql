/****** Object:  View [dbo].[V_Experiment_Plex_Summary_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Plex_Summary_List_Report]
AS
SELECT PlexMembers.Plex_Exp_ID AS Plex_Exp_ID,
       E.Experiment_Num AS [Plex Experiment],
       C.Campaign_Num AS Campaign,
       Org.OG_name AS Organism,
       Count(*) As Channels, 
       Sum(Case When ChannelTypeName.Channel_Type_Name = 'Reference' Then 1 Else 0 End) As Ref_Channels,
       E.EX_Labelling AS Labelling,
       Min(PlexMembers.Entered) AS Created,
       BTO.Tissue,
       E.EX_sample_prep_request_ID AS Request,
       E.Ex_Created AS [Plex Exp Created]
FROM T_Experiment_Plex_Members PlexMembers
     INNER JOIN dbo.T_Experiment_Plex_Channel_Type_Name ChannelTypeName
       ON PlexMembers.Channel_Type_ID = ChannelTypeName.Channel_Type_ID
     INNER JOIN dbo.T_Experiments E
       ON PlexMembers.Plex_Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID     
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON E.EX_Tissue_ID = BTO.Identifier
     LEFT OUTER JOIN T_Sample_Labelling_Reporter_Ions ReporterIons 
       ON PlexMembers.Channel = ReporterIons.Channel AND
         E.EX_Labelling = ReporterIons.Label
GROUP BY PlexMembers.Plex_Exp_ID,
         E.Experiment_Num,
         Org.OG_name,
         E.EX_Labelling,
         E.Ex_Created,
         C.Campaign_Num,
         BTO.Tissue,
         E.EX_Labelling,
         E.EX_sample_prep_request_ID


GO
