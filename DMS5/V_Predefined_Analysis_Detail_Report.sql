/****** Object:  View [dbo].[V_Predefined_Analysis_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Predefined_Analysis_Detail_Report]
AS
SELECT PA.AD_ID AS id,
    PA.AD_instrumentClassCriteria AS instrument_class_criteria,
    PA.AD_level AS level,
    PA.AD_sequence AS sequence,
    PA.AD_nextLevel AS next_level,
    CASE WHEN PA.Trigger_Before_Disposition = 1
		THEN 'Before Disposition'
		ELSE 'Normal'
		END AS trigger_mode,
	CASE PA.propagation_mode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS export_mode,
    PA.AD_instrumentNameCriteria AS instrument_criteria,
	PA.AD_instrumentExclCriteria AS instrument_exclusion,
    PA.AD_organismNameCriteria AS organism_criteria,
    PA.AD_campaignNameCriteria AS campaign_criteria,
    PA.AD_campaignExclCriteria AS campaign_exclusion,
    PA.AD_experimentNameCriteria AS experiment_criteria,
    PA.AD_experimentExclCriteria AS experiment_exclusion,
    PA.AD_expCommentCriteria AS experiment_comment_criteria,
    PA.AD_datasetNameCriteria AS dataset_criteria,
    PA.AD_datasetExclCriteria AS dataset_exclusion,
    PA.AD_datasetTypeCriteria AS dataset_type_criteria,
    PA.AD_scanTypeCriteria AS scan_type_criteria,
    PA.AD_scanTypeExclCriteria AS scan_type_exclusion,
    PA.AD_labellingInclCriteria AS experiment_labelling_criteria,
    PA.AD_labellingExclCriteria AS experiment_labelling_exclusion,
    PA.AD_separationTypeCriteria AS separation_criteria,
	PA.AD_scanCountMinCriteria AS scan_count_min_criteria,
	PA.AD_scanCountMaxCriteria AS scan_count_max_criteria,
    PA.AD_analysisToolName AS analysis_tool_name,
    PA.AD_parmFileName AS param_file_name,
    PA.AD_settingsFileName AS settings_file_name,
    Org.OG_name AS organism_name,
    PA.AD_organismDBName AS organism_db_name,
    PA.AD_proteinCollectionList AS protein_collection_list,
    PA.AD_proteinOptionsList AS protein_options_list,
    PA.AD_priority AS priority,
    PA.AD_enabled AS enabled,
    PA.AD_description AS description,
    PA.AD_specialProcessing AS special_processing,
    PA.AD_created AS created,
    PA.AD_creator AS creator,
    PA.last_affected
FROM T_Predefined_Analysis PA INNER JOIN
     T_Organisms Org ON PA.AD_organism_ID = Org.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
