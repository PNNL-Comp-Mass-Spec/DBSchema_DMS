/****** Object:  View [dbo].[V_Experiment_Plex_Members_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Plex_Members_Entry]
As
SELECT PM.Plex_Exp_ID AS Exp_ID,
       E.Experiment_Num AS Experiment,
       dbo.GetExperimentPlexMembersForEntry(PM.Plex_Exp_ID) AS Plex_Members
FROM T_Experiment_Plex_Members PM
     INNER JOIN T_Experiments E
       ON PM.Plex_Exp_ID = E.Exp_ID


GO
