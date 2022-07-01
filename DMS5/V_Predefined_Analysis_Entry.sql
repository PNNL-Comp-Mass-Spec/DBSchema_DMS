/****** Object:  View [dbo].[V_Predefined_Analysis_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Predefined_Analysis_Entry]
AS
SELECT PA.AD_level AS [level],
       PA.AD_sequence AS sequence,
       PA.AD_instrumentClassCriteria AS instrument_class_criteria,
       PA.AD_campaignNameCriteria AS campaign_name_criteria,
       PA.AD_experimentNameCriteria AS experiment_name_criteria,
       PA.AD_instrumentNameCriteria AS instrument_name_criteria,
	   PA.AD_instrumentExclCriteria AS instrument_excl_criteria,
       PA.AD_organismNameCriteria AS organism_name_criteria,
       PA.AD_datasetNameCriteria AS dataset_name_criteria,
       PA.AD_expCommentCriteria AS exp_comment_criteria,
       PA.AD_labellingInclCriteria AS labelling_incl_criteria,
       PA.AD_labellingExclCriteria AS labelling_excl_criteria,
       PA.AD_separationTypeCriteria AS separation_type_criteria,
       PA.AD_campaignExclCriteria AS campaign_excl_criteria,
       PA.AD_experimentExclCriteria AS experiment_excl_criteria,
       PA.AD_datasetExclCriteria AS dataset_excl_criteria,
       PA.AD_datasetTypeCriteria AS dataset_type_criteria,
       PA.AD_analysisToolName AS analysis_tool_name,
       PA.AD_parmFileName AS param_file_name,
       PA.AD_settingsFileName AS settings_file_name,
       Org.OG_name AS organism_name,
       PA.AD_organismDBName AS organism_db_name,
       PA.AD_proteinCollectionList AS prot_coll_name_list,
       PA.AD_proteinOptionsList AS prot_coll_options_list,
       PA.AD_priority AS priority,
       PA.AD_enabled AS enabled,
       PA.AD_created AS created,
       PA.AD_description AS description,
       PA.AD_creator AS creator,
       PA.AD_ID AS id,
       PA.AD_nextLevel AS next_level,
       PA.Trigger_Before_Disposition AS trigger_before_disposition,
       CASE PA.Propagation_Mode WHEN 0 THEN 'Export' ELSE 'No Export' END AS propagation_mode,
       PA.AD_specialProcessing AS special_processing
FROM dbo.T_Predefined_Analysis AS PA
     INNER JOIN dbo.T_Organisms AS Org
       ON PA.AD_organism_ID = Org.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Entry] TO [DDL_Viewer] AS [dbo]
GO
