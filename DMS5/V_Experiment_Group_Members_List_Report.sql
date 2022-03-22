/****** Object:  View [dbo].[V_Experiment_Group_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Group_Members_List_Report]
AS
SELECT E.Experiment_Num AS Experiment,
       E.Exp_ID AS ID,
       CASE
           WHEN EG.Parent_Exp_ID = E.Exp_ID THEN 'Parent'
           ELSE 'Child'
       END AS Member,
       E.EX_researcher_PRN AS Researcher,
       Org.OG_name AS Organism,
       E.EX_reason AS Reason,
       E.EX_comment AS [Comment],
       Count(DISTINCT DS.Dataset_ID) AS Datasets,
       EG.Group_ID AS Group_ID
FROM dbo.T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Experiment_Group_Members EGM
       ON E.Exp_ID = EGM.Exp_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.Ex_organism_ID = Org.Organism_ID
     LEFT OUTER JOIN dbo.T_Experiment_Groups EG
       ON EGM.Group_ID = EG.Group_ID
     LEFT OUTER JOIN dbo.T_Dataset DS
       ON EGM.Exp_ID = DS.Exp_ID
GROUP BY E.Experiment_Num, E.Exp_ID, EG.Parent_Exp_ID, 
         E.EX_researcher_PRN, Org.OG_name, 
         E.EX_reason, E.EX_comment, EG.Group_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Group_Members_List_Report] TO [DDL_Viewer] AS [dbo]
GO
