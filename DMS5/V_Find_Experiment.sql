/****** Object:  View [dbo].[V_Find_Experiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Find_Experiment]
AS
SELECT E.Experiment_Num AS Experiment,
       U.Name_with_PRN AS Researcher,
       Org.OG_name AS Organism,
       E.EX_reason AS Reason,
       E.EX_comment AS [Comment],
       E.EX_created AS Created,
       C.Campaign_Num AS Campaign,
       CCE.Cell_culture_list AS [Cell Cultures],
       E.Exp_ID AS ID
FROM dbo.T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Users U
       ON E.EX_researcher_PRN = U.U_PRN
     LEFT OUTER JOIN T_Cached_Experiment_Components CCE
       ON E.Exp_ID = CCE.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Experiment] TO [DDL_Viewer] AS [dbo]
GO
