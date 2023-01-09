/****** Object:  View [dbo].[V_RequestPurgeTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_RequestPurgeTask
AS
SELECT dbo.T_Dataset.Dataset_Num AS dataset,
       dbo.T_Dataset.DS_folder_name AS folder,
       dbo.T_Archive_Path.AP_network_share_path + '\' AS sambastoragepath,
       dbo.t_storage_path.SP_machine_name AS storageservername,
       dbo.T_Dataset.Dataset_ID AS datasetid,
       dbo.t_storage_path.SP_vol_name_server AS storagevol,
       dbo.t_storage_path.SP_path AS storagePath,
       dbo.t_storage_path.SP_vol_name_client AS storagevolexternal
FROM dbo.T_Dataset
     INNER JOIN dbo.t_storage_path
       ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID
     INNER JOIN dbo.T_Dataset_Archive
       ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID
     INNER JOIN dbo.T_Archive_Path
       ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_RequestPurgeTask] TO [DDL_Viewer] AS [dbo]
GO
