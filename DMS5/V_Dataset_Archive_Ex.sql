/****** Object:  View [dbo].[V_Dataset_Archive_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Archive_Ex]
AS
SELECT DS.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DS.DS_folder_name AS Folder_Name,
       SPath.SP_vol_name_server + SPath.SP_path AS Server_Path,
       SPath.SP_vol_name_client + SPath.SP_path AS Client_Path,
       dbo.T_Archive_Path.AP_archive_path AS Archive_Path,
       dbo.T_Archive_Path.AP_Server_Name AS Archive_Server,
       InstName.IN_class AS Instrument_Class,
       DA.AS_last_update AS Last_Update,
       DA.AS_state_ID AS Archive_State,
       DA.AS_update_state_ID AS Update_State,
       InstName.IN_name AS Instrument_Name,
       DA.AS_last_verify AS Last_Verify,
       InstClass.requires_preparation AS Requires_Prep,
       InstClass.is_purgable AS Is_Purgeable
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_Archive DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
     INNER JOIN dbo.t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Archive_Path
       ON DA.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID
     INNER JOIN dbo.T_Instrument_Class InstClass
       ON InstName.IN_class = InstClass.IN_class


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Archive_Ex] TO [DDL_Viewer] AS [dbo]
GO
