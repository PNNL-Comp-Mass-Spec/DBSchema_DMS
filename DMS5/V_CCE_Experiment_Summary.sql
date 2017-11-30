/****** Object:  View [dbo].[V_CCE_Experiment_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_CCE_Experiment_Summary]
AS
SELECT E.Experiment_Num AS Experiment,
       E.EX_reason AS [Exp Reason],
       E.EX_comment AS [Exp Comment],
       C.Campaign_Num AS Campaign,
       Org.OG_name AS Organism,
       CCE.Cell_Culture_List AS [Cell Cultures]
FROM T_Experiments E
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     LEFT OUTER JOIN T_Cached_Experiment_Components CCE
       ON E.Exp_ID = CCE.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_CCE_Experiment_Summary] TO [DDL_Viewer] AS [dbo]
GO
