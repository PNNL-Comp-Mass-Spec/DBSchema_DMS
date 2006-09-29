/****** Object:  View [dbo].[V_Dataset_Folder_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Dataset_Folder_Paths
AS
SELECT T_Dataset.Dataset_Num AS Dataset, 
    T_Dataset.Dataset_ID, 
    t_storage_path.SP_vol_name_client + t_storage_path.SP_path
     + T_Dataset.Dataset_Num AS Dataset_Folder_Path, 
    REPLACE(REPLACE(T_Archive_Path.AP_archive_path, 
    '/nwfs/dmsarch/', '\\n2.emsl.pnl.gov\dmsarch\'), '/', '\') 
    + '\' + T_Dataset.Dataset_Num AS Archive_Folder_Path
FROM T_Dataset INNER JOIN
    t_storage_path ON 
    T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID
     INNER JOIN
    T_Dataset_Archive ON 
    T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
     INNER JOIN
    T_Archive_Path ON 
    T_Dataset_Archive.AS_storage_path_ID = T_Archive_Path.AP_path_ID


GO
