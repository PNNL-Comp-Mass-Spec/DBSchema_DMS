/****** Object:  View [dbo].[V_Sample_Prep_Request_Experiments_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Experiments_List_Report]
AS
SELECT E.Experiment_Num AS experiment,
       E.EX_researcher_PRN AS researcher,
       O.OG_name AS organism,
       E.EX_reason AS reason,
       E.EX_comment AS comment,
       E.EX_created AS created,
       C.Campaign_Num AS campaign,
       E.EX_sample_prep_request_ID AS id
FROM dbo.T_Experiments E
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Organisms O
       ON E.Ex_organism_ID = O.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Experiments_List_Report] TO [DDL_Viewer] AS [dbo]
GO
