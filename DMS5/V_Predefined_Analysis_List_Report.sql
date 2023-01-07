/****** Object:  View [dbo].[V_Predefined_Analysis_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Predefined_Analysis_List_Report]
AS
SELECT PA.AD_ID AS id,
       PA.AD_instrumentClassCriteria AS instrument_class,
       PA.AD_level AS level,
       PA.AD_sequence AS seq,
       PA.AD_nextLevel AS next_lvl,
	   PA.AD_enabled AS enabled,
       PA.AD_analysisToolName AS analysis_tool,
       CASE WHEN PA.Trigger_Before_Disposition = 1
            THEN 'Before Disposition'
            ELSE 'Normal'
            END AS trigger_mode,
       CASE PA.propagation_mode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS export_mode,
       PA.AD_instrumentNameCriteria AS instrument_crit,
	   PA.AD_instrumentExclCriteria AS instrument_excl,
       PA.AD_organismNameCriteria AS organism_crit,
       PA.AD_campaignNameCriteria AS campaign_crit,
       PA.AD_experimentNameCriteria AS experiment_crit,
       PA.AD_labellingInclCriteria AS exp_labeling_crit,
       PA.AD_labellingExclCriteria AS exp_labeling_excl,
       PA.AD_datasetNameCriteria AS dataset_crit,
       PA.AD_expCommentCriteria AS exp_comment_crit,
       PA.AD_separationTypeCriteria AS separation_crit,
       PA.AD_campaignExclCriteria AS campaign_excl_crit,
       PA.AD_experimentExclCriteria AS experiment_excl_crit,
       PA.AD_datasetExclCriteria AS dataset_excl_crit,
       PA.AD_datasetTypeCriteria AS dataset_type_crit,
	   PA.AD_scanCountMinCriteria AS scan_count_min,
	   PA.AD_scanCountMaxCriteria AS scan_count_max,
       PA.AD_parmFileName AS param_file,
       PA.AD_settingsFileName AS settings_file,
       Org.OG_name AS organism,
       PA.AD_organismDBName AS organism_db,
       PA.AD_proteinCollectionList AS prot_coll_list,
       PA.AD_proteinOptionsList AS prot_opts_list,
       PA.AD_specialProcessing AS special_proc,
       PA.AD_description AS description,
       PA.AD_priority AS priority,
       PA.last_affected
FROM dbo.T_Predefined_Analysis AS PA
     INNER JOIN dbo.T_Organisms AS Org
       ON PA.AD_organism_ID = Org.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_List_Report] TO [DDL_Viewer] AS [dbo]
GO
