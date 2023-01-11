/****** Object:  View [dbo].[V_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job]
AS
SELECT AJ.AJ_jobID AS job,
       Tool.AJT_toolName AS tool,
       DS.Dataset_Num AS dataset,
       DFP.Dataset_Folder_Path AS dataset_storage_path,
	   DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName As results_folder_path,
       AJ.AJ_parmFileName AS param_file_name,
       AJ.AJ_settingsFileName AS settings_file_name,
       Tool.AJT_parmFileStoragePath AS param_file_storage_path,
       AJ.AJ_organismDBName AS organism_db_name,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       AJ.AJ_proteinOptionsList AS protein_options,
       O.OG_organismDBPath AS organism_db_storage_path,
       AJ.AJ_StateID AS state_id,
       AJ.AJ_priority AS priority,
       AJ.AJ_comment AS [comment],
       InstName.IN_class AS inst_class,
       AJ.AJ_datasetID AS dataset_id,
       AJ.AJ_requestID AS request_id,
       DFP.archive_folder_path,
       DFP.myemsl_path_flag,
       DFP.instrument_data_purged,
	   E.Experiment_Num As experiment,
	   C.Campaign_Num As campaign,
	   InstName.IN_name AS instrument,
	   AJ.AJ_StateNameCached AS state,
	   DS.DS_rating AS rating,
       AJ.AJ_created AS created,
       AJ.AJ_start AS started,
       AJ.AJ_finish AS finished,
	   CONVERT(DECIMAL(9, 2), AJ.AJ_ProcessingTimeMinutes) AS runtime,
	   AJ.AJ_specialProcessing AS special_processing,
	   AJ.aj_jobid,                                 -- This column is obsolete
	   AJ.aj_datasetid,                             -- This column is obsolete
	   AJ.AJ_batchID,                               -- This column is obsolete
	   AJ.AJ_organismDBName AS OrganismDBName,      -- This column is obsolete
       DS.DS_Comp_State AS comp_state               -- This column is obsolete
FROM T_Analysis_Job AJ
     INNER JOIN T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Organisms O
       ON AJ.AJ_organismID = O.Organism_ID
     INNER JOIN T_Analysis_Tool Tool
       ON AJ.AJ_analysisToolID = Tool.AJT_toolID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
