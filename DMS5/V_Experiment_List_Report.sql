/****** Object:  View [dbo].[V_Experiment_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_List_Report]
AS
SELECT E.Experiment_Num AS Experiment,
       U.Name_with_PRN AS Researcher,
       Org.OG_name AS Organism,
       E.EX_reason AS Reason,
       E.EX_comment AS [Comment],
       E.EX_sample_concentration AS Concentration,
       E.EX_created AS Created,
       Campaign.Campaign_Num AS Campaign,
       CEC.Cell_Culture_List AS [Cell Cultures],
       CEC.Reference_Compound_List AS [Ref Compounds],
       E.Exp_ID AS id
FROM T_Experiments E
     INNER JOIN T_Campaign Campaign
       ON E.EX_campaign_ID = Campaign.Campaign_ID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN T_Users U
       ON E.EX_researcher_PRN = U.U_PRN
     LEFT OUTER JOIN T_Cached_Experiment_Components CEC
       ON E.Exp_ID = CEC.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_List_Report] TO [DDL_Viewer] AS [dbo]
GO
