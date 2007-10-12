/****** Object:  View [dbo].[V_RequestAnalysisJobEx5] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_RequestAnalysisJobEx5]
AS
SELECT CONVERT(varchar(32), AJ.AJ_jobID) AS JobNum, 
    DS.Dataset_Num AS DatasetNum, 
    DS.DS_folder_name AS DatasetFolderName, 
    dbo.ConvertFtpArchivePathToSamba(ArchPath.AP_archive_path) + '\' AS DatasetStoragePath, 
    AJ.AJ_parmFileName AS ParmFileName, 
    AJ.AJ_settingsFileName AS SettingsFileName, 
    Tool.AJT_parmFileStoragePath AS ParmFileStoragePath, 
    AJ.AJ_organismDBName AS legacyFastaFileName, 
    AJ.AJ_proteinCollectionList AS ProteinCollectionList, 
    AJ.AJ_proteinOptionsList AS ProteinOptions, 
    AJ.AJ_comment AS Comment, Inst.IN_class AS InstClass, 
    Tool.AJT_parmFileStoragePath + 'SettingsFiles\' AS SettingsFileStoragePath,
    InstClass.raw_data_type AS RawDataType, 
    Tool.AJT_searchEngineInputFileFormats AS SearchEngineInputFileFormats,
    Org.OG_name AS OrganismName, 
    Tool.AJT_orgDbReqd AS OrgDbReqd, 
    SP.SP_vol_name_client + (SELECT Client FROM T_MiscPaths WHERE ([FUNCTION] = 'AnalysisXfer')) AS transferFolderPath, 
    Tool.AJT_toolName AS ToolName
FROM dbo.T_Analysis_Job AJ INNER JOIN
    dbo.T_Dataset DS ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
    dbo.T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID INNER JOIN
    dbo.t_storage_path SP ON DS.DS_storage_path_ID = SP.SP_path_ID INNER JOIN
    dbo.T_Analysis_Tool Tool ON AJ.AJ_analysisToolID = Tool.AJT_toolID INNER JOIN
    dbo.T_Instrument_Name Inst ON DS.DS_instrument_name_ID = Inst.Instrument_ID INNER JOIN
    dbo.T_Instrument_Class InstClass ON Inst.IN_class = InstClass.IN_class INNER JOIN
    dbo.T_Dataset_Archive DSArch ON DS.Dataset_ID = DSArch.AS_Dataset_ID INNER JOIN
    dbo.T_Archive_Path ArchPath ON DSArch.AS_storage_path_ID = ArchPath.AP_path_ID

GO
