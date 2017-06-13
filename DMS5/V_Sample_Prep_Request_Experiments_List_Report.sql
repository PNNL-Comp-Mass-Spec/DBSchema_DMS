/****** Object:  View [dbo].[V_Sample_Prep_Request_Experiments_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Experiments_List_Report]
AS
SELECT E.Experiment_Num AS Experiment,
       E.EX_researcher_PRN AS Researcher,
       O.OG_name AS Organism,
       E.EX_reason AS Reason,
       E.EX_comment AS [Comment],
       E.EX_created AS Created,
       C.Campaign_Num AS Campaign,
       -- Deprecated in June 2017: E.EX_cell_culture_list AS [Cell Cultures], 
       E.EX_sample_prep_request_ID AS [#ID]
FROM dbo.T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Organisms O
       ON E.Ex_organism_ID = O.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Experiments_List_Report] TO [DDL_Viewer] AS [dbo]
GO
