/****** Object:  View [dbo].[V_RequestAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_RequestAnalysisJob
AS
SELECT CONVERT(varchar(32), AJ.AJ_jobID) AS JobNum,
       DS.Dataset_Num AS DatasetNum,
       DS.DS_folder_name AS DatasetFolderName,
       ArchPath.AP_network_share_path AS DatasetStoragePath,
       AJ.AJ_parmFileName AS ParamFileName,
       AJ.AJ_settingsFileName AS SettingsFileName,
       Tool.AJT_parmFileStoragePath AS ParamFileStoragePath,
       AJ.AJ_organismDBName AS legacyFastaFileName,
       AJ.AJ_proteinCollectionList AS ProteinCollectionList,
       AJ.AJ_proteinOptionsList AS ProteinOptions,
       AJ.AJ_comment AS Comment,
       Inst.IN_class AS InstClass,
       Tool.AJT_parmFileStoragePath + 'SettingsFiles\' AS SettingsFileStoragePath,
       InstClass.raw_data_type AS RawDataType,
       Tool.AJT_searchEngineInputFileFormats AS SearchEngineInputFileFormats,
       Org.OG_name AS OrganismName,
       Tool.AJT_orgDbReqd AS OrgDbReqd,
       SP.SP_vol_name_client + ( SELECT Client
                                 FROM dbo.T_MiscPaths
                                 WHERE ([Function] = 'AnalysisXfer') ) AS transferFolderPath,
       Tool.AJT_toolName AS ToolName
FROM dbo.T_Analysis_Job AS AJ
     INNER JOIN dbo.T_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Organisms AS Org
       ON AJ.AJ_organismID = Org.Organism_ID
     INNER JOIN dbo.t_storage_path AS SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
     INNER JOIN dbo.T_Analysis_Tool AS Tool
       ON AJ.AJ_analysisToolID = Tool.AJT_toolID
     INNER JOIN dbo.T_Instrument_Name AS Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
     INNER JOIN dbo.T_Instrument_Class AS InstClass
       ON Inst.IN_class = InstClass.IN_class
     INNER JOIN dbo.T_Dataset_Archive AS DSArch
       ON DS.Dataset_ID = DSArch.AS_Dataset_ID
     INNER JOIN dbo.T_Archive_Path AS ArchPath
       ON DSArch.AS_storage_path_ID = ArchPath.AP_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_RequestAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
