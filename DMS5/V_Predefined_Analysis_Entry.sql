/****** Object:  View [dbo].[V_Predefined_Analysis_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Predefined_Analysis_Entry
AS
SELECT     AD_level AS [level],
	AD_sequence AS sequence,
	AD_instrumentClassCriteria AS instrumentClassCriteria,
	AD_campaignNameCriteria AS campaignNameCriteria,
	AD_experimentNameCriteria AS experimentNameCriteria,
	AD_instrumentNameCriteria AS instrumentNameCriteria,
	AD_organismNameCriteria AS organismNameCriteria,
	AD_datasetNameCriteria AS datasetNameCriteria,
	AD_expCommentCriteria AS expCommentCriteria,
	AD_labellingInclCriteria AS labellingInclCriteria,
	AD_labellingExclCriteria AS labellingExclCriteria,
	AD_analysisToolName AS analysisToolName,
	AD_parmFileName AS parmFileName,
	AD_settingsFileName AS settingsFileName,
	AD_organismName AS organismName,
	AD_organismDBName AS organismDBName,
	AD_proteinCollectionList AS protCollNameList,
	AD_proteinOptionsList AS protCollOptionsList,
	AD_priority AS priority,
	AD_enabled AS enabled,
	AD_created AS created,
	AD_description AS description,
	AD_creator AS creator,
	AD_ID AS ID,
	AD_nextLevel AS nextLevel
FROM         dbo.T_Predefined_Analysis


GO
