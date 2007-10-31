/****** Object:  View [dbo].[V_GetDatasetsForArchiveTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetDatasetsForArchiveTask
AS
SELECT     TD.Dataset_Num AS Dataset, TD.Dataset_ID, TD.DS_folder_name AS Folder, dbo.t_storage_path.SP_machine_name AS Storage_Server_Name, 
                      dbo.t_storage_path.SP_vol_name_server AS Storage_Vol, dbo.t_storage_path.SP_path AS Storage_Path, 
                      dbo.T_Archive_Path.AP_archive_path AS Archive_Path, dbo.T_Archive_Path.AP_network_share_path AS Archive_Network_Share_Path, 
                      dbo.T_Instrument_Name.IN_class AS Instrument_Class, dbo.T_Instrument_Name.IN_name AS Instrument_Name, 
                      dbo.t_storage_path.SP_vol_name_client AS Storage_Vol_External, dbo.T_Dataset_Archive.AS_last_update AS Last_Update, 
                      dbo.T_Dataset_Archive.AS_last_verify AS Last_Verify
FROM         dbo.T_Dataset AS TD INNER JOIN
                      dbo.T_Dataset_Archive ON TD.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.t_storage_path ON TD.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON TD.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID

GO
