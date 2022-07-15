/****** Object:  View [dbo].[V_GetPipelineJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_GetPipelineJobParameters] as 
SELECT AJ.AJ_jobID AS Job,
       DS.Dataset_Num AS Dataset,
       DS.DS_folder_name AS Dataset_Folder_Name,
       Coalesce(ArchPath.AP_network_share_path, '') AS Archive_Folder_Path,
       AJ.AJ_parmFileName AS ParamFileName,
       AJ.AJ_settingsFileName AS SettingsFileName,
       Tool.AJT_parmFileStoragePath AS ParamFileStoragePath,
       AJ.AJ_organismDBName AS OrganismDBName,
       AJ.AJ_proteinCollectionList AS ProteinCollectionList,
       AJ.AJ_proteinOptionsList AS ProteinOptionsList,
       InstName.IN_class AS InstrumentClass,
       InstName.IN_Group AS InstrumentGroup,
       InstName.IN_Name AS Instrument,
       InstClass.raw_data_type AS RawDataType,
       Tool.AJT_searchEngineInputFileFormats AS SearchEngineInputFileFormats,
       Org.OG_name AS Organism,
       Tool.AJT_orgDbReqd AS OrgDBRequired,
       Tool.AJT_toolName AS ToolName,
       Tool.AJT_resultType AS ResultType,
       DS.Dataset_ID,
       SP.SP_vol_name_client + SP.SP_path AS Dataset_Storage_Path,
       SP.SP_vol_name_client + ( SELECT Client
                                 FROM dbo.T_MiscPaths
                                 WHERE ([Function] = 'AnalysisXfer') ) AS Transfer_Folder_Path,
       AJ.AJ_resultsFolderName AS Results_Folder_Name,
       AJ.AJ_specialProcessing AS Special_Processing,
       DTN.DST_name AS DatasetType,
       Ex.Experiment_Num AS Experiment,
       Coalesce(DSArch.AS_instrument_data_purged, 0) AS InstrumentDataPurged
FROM
	dbo.T_Analysis_Job AS AJ
	INNER JOIN dbo.T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID
	INNER JOIN dbo.T_Organisms AS Org ON AJ.AJ_organismID = Org.Organism_ID
	INNER JOIN dbo.t_storage_path AS SP ON DS.DS_storage_path_ID = SP.SP_path_ID
	INNER JOIN dbo.T_Analysis_Tool AS Tool ON AJ.AJ_analysisToolID = Tool.AJT_toolID
	INNER JOIN dbo.T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
	INNER JOIN dbo.T_Instrument_Class AS InstClass ON InstName.IN_class = InstClass.IN_class
	INNER JOIN dbo.T_DatasetTypeName DTN ON DS.DS_type_ID = DTN.DST_Type_ID
	INNER JOIN dbo.T_Experiments Ex ON DS.Exp_ID = Ex.Exp_ID
	LEFT OUTER JOIN dbo.T_Dataset_Archive AS DSArch ON DS.Dataset_ID = DSArch.AS_Dataset_ID
	LEFT OUTER JOIN dbo.T_Archive_Path AS ArchPath ON DSArch.AS_storage_path_ID = ArchPath.AP_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineJobParameters] TO [DDL_Viewer] AS [dbo]
GO
