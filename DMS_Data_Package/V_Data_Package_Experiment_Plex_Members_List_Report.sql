/****** Object:  View [dbo].[V_Data_Package_Experiment_Plex_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Experiment_Plex_Members_List_Report]
AS
SELECT DPE.Data_Package_ID AS ID,
       DPE.Experiment,
       PM.Plex_Exp_ID,
       PM.Organism,
       PM.Channel,
       PM.Tag,
       PM.Exp_ID,
       PM.[Channel Experiment],
       PM.[Channel Type],
       PM.Comment,
       PM.Created,
       PM.Campaign,
       PM.Tissue,
       PM.Labelling,
       PM.MASIC_Name,
       [Item Added]
FROM dbo.T_Data_Package_Experiments DPE
     Inner Join [S_V_Experiment_Plex_Members_List_Report] PM
       ON PM.Plex_Exp_ID = DPE.Experiment_ID

GO
