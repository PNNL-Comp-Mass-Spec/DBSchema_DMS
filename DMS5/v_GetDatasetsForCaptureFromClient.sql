/****** Object:  View [dbo].[v_GetDatasetsForCaptureFromClient] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/****** Object:  View dbo.v_GetDatasetsForCaptureFromClient ******/

/****** Object:  View dbo.v_GetDatasetsForCaptureFromClient    Script Date: 1/17/2001 2:15:34 PM ******/
CREATE VIEW dbo.v_GetDatasetsForCaptureFromClient
AS
SELECT T_Dataset.Dataset_Num AS Dataset, 
   v_assigned_storage.IN_name AS Instrument, 
   v_assigned_storage.IN_capture_method AS Method, 
   T_Dataset.DS_created AS Created, 
   T_Dataset.DS_folder_name AS Folder, 
   v_assigned_storage.sourceVol AS SourceVolume, 
   v_assigned_storage.sourcePath AS SourcePath, 
   v_assigned_storage.clientStorageVol AS StorageVol, 
   v_assigned_storage.storagePath, 
   v_assigned_storage.IN_source_path_ID AS SourceID, 
   v_assigned_storage.IN_storage_path_ID AS StorageID, 
   v_assigned_storage.Instrument_ID AS InstrumentID
FROM T_Dataset INNER JOIN
   v_assigned_storage ON 
   T_Dataset.DS_instrument_name_ID = v_assigned_storage.Instrument_ID
WHERE (T_Dataset.DS_state_ID = 1)
GO
