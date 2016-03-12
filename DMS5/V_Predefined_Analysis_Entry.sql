/****** Object:  View [dbo].[V_Predefined_Analysis_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Predefined_Analysis_Entry]
AS
SELECT PA.AD_level AS [level],
       PA.AD_sequence AS sequence,
       PA.AD_instrumentClassCriteria AS instrumentClassCriteria,
       PA.AD_campaignNameCriteria AS campaignNameCriteria,
       PA.AD_experimentNameCriteria AS experimentNameCriteria,
       PA.AD_instrumentNameCriteria AS instrumentNameCriteria,
       PA.AD_organismNameCriteria AS organismNameCriteria,
       PA.AD_datasetNameCriteria AS datasetNameCriteria,
       PA.AD_expCommentCriteria AS expCommentCriteria,
       PA.AD_labellingInclCriteria AS labellingInclCriteria,
       PA.AD_labellingExclCriteria AS labellingExclCriteria,
       PA.AD_separationTypeCriteria AS separationTypeCriteria,
       PA.AD_campaignExclCriteria AS campaignExclCriteria,
       PA.AD_experimentExclCriteria AS experimentExclCriteria,
       PA.AD_datasetExclCriteria AS datasetExclCriteria,
       PA.AD_datasetTypeCriteria AS datasetTypeCriteria,
       PA.AD_analysisToolName AS analysisToolName,
       PA.AD_parmFileName AS parmFileName,
       PA.AD_settingsFileName AS settingsFileName,
       Org.OG_name AS organismName,
       PA.AD_organismDBName AS organismDBName,
       PA.AD_proteinCollectionList AS protCollNameList,
       PA.AD_proteinOptionsList AS protCollOptionsList,
       PA.AD_priority AS priority,
       PA.AD_enabled AS enabled,
       PA.AD_created AS created,
       PA.AD_description AS description,
       PA.AD_creator AS creator,
       PA.AD_ID AS ID,
       PA.AD_nextLevel AS nextLevel,
       PA.Trigger_Before_Disposition AS TriggerBeforeDisposition,
       CASE PA.Propagation_Mode WHEN 0 THEN 'Export' ELSE 'No Export' END AS PropagationMode,
       PA.AD_specialProcessing as specialProcessing
FROM dbo.T_Predefined_Analysis AS PA
     INNER JOIN dbo.T_Organisms AS Org
       ON PA.AD_organism_ID = Org.Organism_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Entry] TO [PNL\D3M578] AS [dbo]
GO
