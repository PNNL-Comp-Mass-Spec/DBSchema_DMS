/****** Object:  View [dbo].[V_Dataset_Restore_Request_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Dataset_Restore_Request_List_Report
AS
SELECT T_Dataset.Dataset_ID AS ID,
       T_Dataset.Dataset_Num AS Dataset,
       T_Dataset_State_Name.DSS_name AS State,
       T_Dataset_Archive_State_Name.archive_state AS [Archive State],
       T_Storage_Path.SP_vol_name_client + T_Storage_Path.SP_path + T_Dataset.DS_folder_name AS [Dataset Folder Path],
       T_Archive_Path.AP_archive_path AS [Archive Path]
FROM T_Dataset_Archive
     INNER JOIN T_Dataset
       ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
     INNER JOIN T_Dataset_State_Name
       ON T_Dataset.DS_state_ID = T_Dataset_State_Name.Dataset_state_ID
     INNER JOIN T_Dataset_Archive_State_Name
       ON T_Dataset_Archive.AS_state_ID = T_Dataset_Archive_State_Name.archive_state_id
     INNER JOIN T_Storage_Path
       ON T_Dataset.DS_storage_path_ID = T_Storage_Path.SP_path_ID
     INNER JOIN T_Archive_Path
       ON T_Dataset_Archive.AS_storage_path_ID = T_Archive_Path.AP_path_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Restore_Request_List_Report] TO [DDL_Viewer] AS [dbo]
GO
