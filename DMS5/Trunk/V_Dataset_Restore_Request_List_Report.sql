/****** Object:  View [dbo].[V_Dataset_Restore_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Dataset_Restore_Request_List_Report
as
SELECT     TOP 100 PERCENT T_Dataset.Dataset_ID AS ID, T_Dataset.Dataset_Num AS Dataset, T_DatasetStateName.DSS_name AS State, 
                      T_DatasetArchiveStateName.DASN_StateName AS [Archive State], 
                      t_storage_path.SP_vol_name_client + t_storage_path.SP_path + T_Dataset.DS_folder_name AS [Dataset Folder Path], 
                      T_Archive_Path.AP_archive_path AS [Archive Path]
FROM         T_Dataset_Archive INNER JOIN
                      T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID INNER JOIN
                      T_DatasetStateName ON T_Dataset.DS_state_ID = T_DatasetStateName.Dataset_state_ID INNER JOIN
                      T_DatasetArchiveStateName ON T_Dataset_Archive.AS_state_ID = T_DatasetArchiveStateName.DASN_StateID INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
                      T_Archive_Path ON T_Dataset_Archive.AS_storage_path_ID = T_Archive_Path.AP_path_ID
ORDER BY T_Dataset.Dataset_ID DESC

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Restore_Request_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Restore_Request_List_Report] TO [PNL\D3M580] AS [dbo]
GO
