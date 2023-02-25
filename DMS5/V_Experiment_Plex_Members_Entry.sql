/****** Object:  View [dbo].[V_Experiment_Plex_Members_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Experiment_Plex_Members_Entry]
As
SELECT PM.Plex_Exp_ID AS exp_id,
       E.Experiment_Num AS experiment,
       dbo.get_experiment_plex_members_for_entry(PM.Plex_Exp_ID) AS plex_members
FROM T_Experiment_Plex_Members PM
     INNER JOIN T_Experiments E
       ON PM.Plex_Exp_ID = E.Exp_ID

GO
