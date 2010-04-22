/****** Object:  View [dbo].[V_GetDatasetsForArchiveUpdateTask_Temp] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetDatasetsForArchiveUpdateTask_Temp
AS 
SELECT     TD.Dataset_Num AS Dataset, TD.Dataset_ID, TD.DS_folder_name AS Folder, dbo.t_storage_path.SP_machine_name AS Storage_Server_Name, 
                      dbo.t_storage_path.SP_vol_name_server AS Storage_Vol, dbo.t_storage_path.SP_path AS Storage_Path, 
                      dbo.T_Archive_Path.AP_archive_path AS Archive_Path, dbo.T_Archive_Path.AP_Server_Name AS Archive_Server_Name, 
                      dbo.T_Instrument_Name.IN_class AS Instrument_Class, dbo.T_Instrument_Name.IN_name AS Instrument_Name, 
                      dbo.t_storage_path.SP_vol_name_client AS Storage_Vol_External, dbo.T_Dataset_Archive.AS_last_update AS Last_Update, 
                      dbo.T_Dataset_Archive.AS_last_verify AS Last_Verify, dbo.T_Dataset_Archive.AS_update_state_ID
FROM         dbo.T_Dataset AS TD INNER JOIN
                      dbo.T_Dataset_Archive ON TD.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.t_storage_path ON TD.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON TD.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID
WHERE     (dbo.T_Dataset_Archive.AS_update_state_ID = 2) AND (dbo.T_Dataset_Archive.AS_state_ID = 3 OR
                      dbo.T_Dataset_Archive.AS_state_ID = 4) AND (NOT EXISTS
                          (SELECT     AJ_jobID, AJ_batchID, AJ_priority, AJ_created, AJ_start, AJ_finish, AJ_analysisToolID, AJ_parmFileName, AJ_settingsFileName, 
                                                   AJ_organismDBName, AJ_organismID, AJ_datasetID, AJ_comment, AJ_owner, AJ_StateID, AJ_Last_Affected, 
                                                   AJ_assignedProcessorName, AJ_resultsFolderName, AJ_proteinCollectionList, AJ_proteinOptionsList, AJ_requestID, 
                                                   AJ_extractionProcessor, AJ_extractionStart, AJ_extractionFinish, AJ_Analysis_Manager_Error, AJ_Data_Extraction_Error, 
                                                   AJ_propagationMode
                            FROM          dbo.T_Analysis_Job
                            WHERE      (AJ_StateID IN (2, 3, 9, 10, 11, 12)) AND (AJ_datasetID = TD.Dataset_ID)))
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetDatasetsForArchiveUpdateTask_Temp] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetDatasetsForArchiveUpdateTask_Temp] TO [PNL\D3M580] AS [dbo]
GO
