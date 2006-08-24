/****** Object:  View [dbo].[V_Predefined_Analysis_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Predefined_Analysis_Detail_Report
AS
SELECT     
  AD_ID AS ID,
	AD_level AS [Level],
	AD_sequence AS Sequence,
	AD_instrumentClassCriteria AS [Instrument Class Criteria],
	AD_nextLevel AS [Next Level],
	AD_campaignNameCriteria AS [Campaign Criteria],
	AD_experimentNameCriteria AS [Experiment Criteria],
	AD_instrumentNameCriteria AS [Instrument Criteria],
	AD_organismNameCriteria AS [Organism Criteria],
	AD_datasetNameCriteria AS [Dataset Criteria],
	AD_expCommentCriteria AS [Experiment Comment Criteria],
	AD_labellingInclCriteria AS [Experiment Labelling Criteria],
	AD_analysisToolName AS [Analysis Tool Name],
	AD_parmFileName AS [Parmfile Name],
	AD_settingsFileName AS [Settings File Name],
	AD_organismName AS [Organism Name],
	AD_organismDBName AS [Organism Db Name],
	AD_proteinCollectionList AS [Protein Collection List],
	AD_proteinOptionsList AS [Protein Options List],
	AD_priority AS priority,
	AD_enabled AS enabled,
	AD_created AS created,
	AD_description AS Description,
	AD_creator AS Creator
FROM         dbo.T_Predefined_Analysis


GO
