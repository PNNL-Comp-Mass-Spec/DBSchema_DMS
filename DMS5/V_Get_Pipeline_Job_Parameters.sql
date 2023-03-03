/****** Object:  View [dbo].[V_Get_Pipeline_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Get_Pipeline_Job_Parameters]
AS
SELECT AJ.AJ_jobID AS job,
       DS.Dataset_Num AS dataset,
       DS.DS_folder_name AS dataset_folder_name,
       Coalesce(ArchPath.AP_network_share_path, '') AS archive_folder_path,
       AJ.AJ_parmFileName AS param_file_name,
       AJ.AJ_settingsFileName AS settings_file_name,
       Tool.AJT_parmFileStoragePath AS param_file_storage_path,
       AJ.AJ_organismDBName AS organism_db_name,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       AJ.AJ_proteinOptionsList AS protein_options_list,
       InstName.IN_class AS instrument_class,
       InstName.IN_Group AS instrument_group,
       InstName.IN_Name AS instrument,
       InstClass.raw_data_type AS raw_data_type,
       Tool.AJT_searchEngineInputFileFormats AS search_engine_input_file_formats,
       Org.OG_name AS organism,
       Tool.AJT_orgDbReqd AS org_db_required,
       Tool.AJT_toolName AS tool_name,
       Tool.AJT_resultType AS result_type,
       DS.dataset_id,
       SP.SP_vol_name_client + SP.SP_path AS dataset_storage_path,
       SP.SP_vol_name_client + ( SELECT Client
                                 FROM dbo.T_MiscPaths
                                 WHERE ([Function] = 'AnalysisXfer') ) AS transfer_folder_path,
       AJ.AJ_resultsFolderName AS results_folder_name,
       AJ.AJ_specialProcessing AS special_processing,
       DTN.DST_name AS dataset_type,
       Ex.Experiment_Num AS experiment,
       Coalesce(DSArch.AS_instrument_data_purged, 0) AS instrument_data_purged
FROM
	dbo.T_Analysis_Job AS AJ
	INNER JOIN dbo.T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID
	INNER JOIN dbo.T_Organisms AS Org ON AJ.AJ_organismID = Org.Organism_ID
	INNER JOIN dbo.t_storage_path AS SP ON DS.DS_storage_path_ID = SP.SP_path_ID
	INNER JOIN dbo.T_Analysis_Tool AS Tool ON AJ.AJ_analysisToolID = Tool.AJT_toolID
	INNER JOIN dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
	INNER JOIN dbo.T_Instrument_Class AS InstClass ON InstName.IN_class = InstClass.IN_class
	INNER JOIN dbo.T_Dataset_Type_Name DTN ON DS.DS_type_ID = DTN.DST_Type_ID
	INNER JOIN dbo.T_Experiments Ex ON DS.Exp_ID = Ex.Exp_ID
	LEFT OUTER JOIN dbo.T_Dataset_Archive AS DSArch ON DS.Dataset_ID = DSArch.AS_Dataset_ID
	LEFT OUTER JOIN dbo.T_Archive_Path AS ArchPath ON DSArch.AS_storage_path_ID = ArchPath.AP_path_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Get_Pipeline_Job_Parameters] TO [DDL_Viewer] AS [dbo]
GO
