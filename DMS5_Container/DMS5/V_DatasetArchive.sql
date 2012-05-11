/****** Object:  View [dbo].[V_DatasetArchive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DatasetArchive]
AS
SELECT DS.Dataset_Num AS Dataset_Number,
       DS.DS_folder_name AS Folder_Name,
       SPath.SP_vol_name_server AS Server_Vol,
       SPath.SP_vol_name_client AS Client_Vol,
       SPath.SP_path AS Storage_Path,
       ArchPath.AP_archive_path AS Archive_Path,
       InstName.IN_class AS Instrument_Class,
       DA.AS_last_update AS Last_Update,
       DA.AS_state_ID AS Archive_State,
       InstName.IN_name AS Instrument_Name,
       DA.AS_last_verify AS Last_Verify
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_Archive DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
     INNER JOIN dbo.t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Archive_Path ArchPath
       ON DA.AS_storage_path_ID = ArchPath.AP_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetArchive] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetArchive] TO [PNL\D3M580] AS [dbo]
GO
