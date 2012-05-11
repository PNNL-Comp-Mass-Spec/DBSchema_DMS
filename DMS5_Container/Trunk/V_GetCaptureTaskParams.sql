/****** Object:  View [dbo].[V_GetCaptureTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_GetCaptureTaskParams
AS
SELECT 
  dbo.T_Dataset.Dataset_Num                         AS Dataset,
  dbo.v_assigned_storage.IN_name                    AS Instrument,
  dbo.v_assigned_storage.IN_capture_method          AS Method,
  dbo.T_Dataset.DS_created                          AS Created,
  dbo.T_Dataset.DS_folder_name                      AS Folder,
  dbo.v_assigned_storage.sourceVol                  AS SourceVolume,
  dbo.v_assigned_storage.sourcePath,
  dbo.v_assigned_storage.SP_machine_name            AS StorageServerName,
  dbo.v_assigned_storage.clientStorageVol           AS StorageVolClient,
  dbo.v_assigned_storage.serverStorageVol           AS StorageVolServer,
  dbo.v_assigned_storage.storagePath,
  dbo.v_assigned_storage.IN_source_path_ID          AS SourceID,
  dbo.v_assigned_storage.IN_storage_path_ID         AS StorageID,
  dbo.v_assigned_storage.Instrument_ID              AS InstrumentID,
  dbo.T_Dataset.Dataset_ID,
  dbo.T_Dataset.DS_rating,
  dbo.T_Instrument_Name.IN_class                    AS InstrumentClass,
  dbo.Datasetpreference(dbo.T_Dataset.Dataset_Num)  AS Preference,
  dbo.T_Instrument_Name.Instrument_ID
FROM   
  dbo.T_Dataset
  INNER JOIN dbo.v_assigned_storage
    ON dbo.T_Dataset.DS_instrument_name_ID = dbo.v_assigned_storage.Instrument_ID
  INNER JOIN dbo.T_Instrument_Name
    ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
                                             


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetCaptureTaskParams] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetCaptureTaskParams] TO [PNL\D3M580] AS [dbo]
GO
