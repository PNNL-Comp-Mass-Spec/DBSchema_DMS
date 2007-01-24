/****** Object:  View [dbo].[V_Dataset_Folder_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Folder_Paths
AS
SELECT     dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.Dataset_ID, 
                      dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path + dbo.T_Dataset.Dataset_Num AS Dataset_Folder_Path, 
                      REPLACE(REPLACE(dbo.T_Archive_Path.AP_archive_path, '/nwfs/dmsarch/', '\\n2.emsl.pnl.gov\dmsarch\'), '/', '\') 
                      + '\' + dbo.T_Dataset.Dataset_Num AS Archive_Folder_Path
FROM         dbo.T_Dataset INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID LEFT OUTER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID LEFT OUTER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID

GO
