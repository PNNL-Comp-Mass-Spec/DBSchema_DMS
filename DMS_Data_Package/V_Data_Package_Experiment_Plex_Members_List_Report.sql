/****** Object:  View [dbo].[V_Data_Package_Experiment_Plex_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Experiment_Plex_Members_List_Report]
AS
SELECT DPE.Data_Package_ID AS id,
       DPE.experiment,
       PM.plex_exp_id,
       PM.organism,
       PM.channel,
       PM.tag,
       PM.exp_id,
       PM.channel_experiment,
       PM.channel_type,
       PM.comment,
       PM.created,
       PM.campaign,
       PM.tissue,
       PM.labelling,
       PM.masic_name,
       Item_Added
FROM dbo.T_Data_Package_Experiments DPE
     Inner Join S_V_Experiment_Plex_Members_List_Report PM
       ON PM.Plex_Exp_ID = DPE.experiment_id


GO
