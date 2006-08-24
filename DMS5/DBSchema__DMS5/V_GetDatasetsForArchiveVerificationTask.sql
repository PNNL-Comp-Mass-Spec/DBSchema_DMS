/****** Object:  View [dbo].[V_GetDatasetsForArchiveVerificationTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_GetDatasetsForArchiveVerificationTask
AS
SELECT     TOP 100 PERCENT TD.Dataset_Num AS Dataset, TD.Dataset_ID AS Dataset_ID, TD.DS_folder_name AS Folder, 
                      t_storage_path.SP_machine_name AS Storage_Server_Name, t_storage_path.SP_vol_name_server AS Storage_Vol, 
                      t_storage_path.SP_path AS Storage_Path, T_Archive_Path.AP_archive_path AS Archive_Path, T_Instrument_Name.IN_class AS Instrument_Class, 
                      T_Instrument_Name.IN_name AS Instrument_Name, t_storage_path.SP_vol_name_client AS Storage_Vol_External, 
                      T_Dataset_Archive.AS_last_update AS Last_Update, T_Dataset_Archive.AS_last_verify AS Last_Verify, MIN(ISNULL(T_Analysis_Job.AJ_priority, 99)) 
                      AS priority
FROM         T_Dataset TD INNER JOIN
                      T_Dataset_Archive ON TD.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      t_storage_path ON TD.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
                      T_Instrument_Name ON TD.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
                      T_Archive_Path ON T_Dataset_Archive.AS_storage_path_ID = T_Archive_Path.AP_path_ID LEFT OUTER JOIN
                      T_Analysis_Job ON TD.Dataset_ID = T_Analysis_Job.AJ_datasetID
GROUP BY TD.Dataset_Num, TD.Dataset_ID, TD.DS_folder_name, t_storage_path.SP_machine_name, t_storage_path.SP_vol_name_server, 
                      t_storage_path.SP_path, T_Archive_Path.AP_archive_path, T_Instrument_Name.IN_class, T_Instrument_Name.IN_name, 
                      t_storage_path.SP_vol_name_client, T_Dataset_Archive.AS_last_update, T_Dataset_Archive.AS_last_verify, T_Analysis_Job.AJ_StateID, 
                      T_Dataset_Archive.AS_state_ID
HAVING      (NOT (ISNULL(T_Analysis_Job.AJ_StateID, 0) IN (2, 3, 9, 10, 11, 12))) AND (T_Dataset_Archive.AS_state_ID = 11)
ORDER BY MIN(ISNULL(T_Analysis_Job.AJ_priority, 99))

GO
