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
       E.EX_cell_culture_list AS [Cell Cultures],
       E.Exp_ID AS ID
FROM dbo.T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Users U
       ON E.EX_researcher_PRN = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Experiment] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Experiment] TO [PNL\D3M580] AS [dbo]
GO
