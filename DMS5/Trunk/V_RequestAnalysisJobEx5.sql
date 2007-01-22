/****** Object:  View [dbo].[V_RequestAnalysisJobEx5] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_RequestAnalysisJobEx5
AS
SELECT     CONVERT(varchar(32), dbo.T_Analysis_Job.AJ_jobID) AS JobNum, dbo.T_Dataset.Dataset_Num AS DatasetNum, 
                      dbo.T_Dataset.DS_folder_name AS DatasetFolderName, dbo.ConvertFtpArchivePathToSamba(dbo.T_Archive_Path.AP_archive_path) 
                      + '\' AS DatasetStoragePath, dbo.T_Analysis_Job.AJ_parmFileName AS ParmFileName, 
                      dbo.T_Analysis_Job.AJ_settingsFileName AS SettingsFileName, dbo.T_Analysis_Tool.AJT_parmFileStoragePath AS ParmFileStoragePath, 
                      dbo.T_Analysis_Job.AJ_organismDBName AS legacyFastaFileName, dbo.T_Analysis_Job.AJ_proteinCollectionList AS ProteinCollectionList, 
                      dbo.T_Analysis_Job.AJ_proteinOptionsList AS ProteinOptions, dbo.T_Analysis_Job.AJ_comment AS Comment, 
                      dbo.T_Instrument_Name.IN_class AS InstClass, dbo.T_Analysis_Tool.AJT_parmFileStoragePath + 'SettingsFiles\' AS SettingsFileStoragePath, 
                      dbo.T_Instrument_Class.raw_data_type AS RawDataType, dbo.T_Analysis_Tool.AJT_searchEngineInputFileFormats AS SearchEngineInputFileFormats, 
                      dbo.T_Organisms.OG_name AS OrganismName, dbo.T_Analysis_Tool.AJT_orgDbReqd AS OrgDbReqd, 
                      dbo.t_storage_path.SP_vol_name_client +
                          (SELECT     Client
                            FROM          T_MiscPaths
                            WHERE      ([FUNCTION] = 'AnalysisXfer')) AS transferFolderPath
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID

GO
