/****** Object:  View [dbo].[V_RequestArchiveTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_RequestArchiveTask
AS
SELECT     dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.Dataset_ID AS DatasetID, dbo.T_Dataset.DS_folder_name AS DatasetFolder, 
                      dbo.t_storage_path.SP_vol_name_server AS StorageVol, dbo.t_storage_path.SP_path AS StoragePath, 
                      dbo.T_Archive_Path.AP_archive_path AS ArchivePath, dbo.T_Archive_Path.AP_Server_Name AS ArchiveServer, 
                      dbo.t_storage_path.SP_vol_name_client AS StorageVolExternal, dbo.T_Instrument_Name.IN_class AS InstrumentClass, 
                      dbo.T_Instrument_Name.IN_name AS InstrumentName, dbo.T_Dataset_Archive.AS_last_update AS LastUpdate
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID

GO
