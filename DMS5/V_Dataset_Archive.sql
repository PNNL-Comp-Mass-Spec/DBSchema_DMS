/****** Object:  View [dbo].[V_Dataset_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Archive]
AS
SELECT DA.AS_Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DA.AS_state_ID,
       DASN.archive_state,
       DA.AS_state_Last_Affected,
       DA.AS_storage_path_ID,
       DA.AS_datetime,
       DA.AS_last_update,
       DA.AS_last_verify,
       DA.AS_update_state_ID,
       AUSN.AUS_name,
       DA.AS_update_state_Last_Affected,
       DA.AS_purge_holdoff_date,
       DA.AS_archive_processor,
       DA.AS_update_processor,
       DA.AS_verification_processor,
       InstName.IN_name AS Instrument,
       DA.AS_instrument_data_purged,
       DA.AS_Last_Successful_Archive,
       DA.AS_StageMD5_Required,
       DA.QC_Data_Purged,
       DA.Purge_Policy,
       DA.Purge_Priority,
       DA.MyEMSLState,
       ISNULL(dbo.combine_paths(SPath.SP_vol_name_client,
              dbo.combine_paths(SPath.SP_path,
                                  ISNULL(DS.DS_folder_name, DS.Dataset_Num))), '') AS Dataset_Folder_Path,
       AP.AP_archive_path,
       AP.AP_network_share_path,
       DS.Dataset_Num,
	   DA.AS_Dataset_ID As Dataset_ID
FROM T_Dataset_Archive DA
     INNER JOIN T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Dataset_Archive_State_Name DASN
       ON DA.AS_state_ID = DASN.archive_state_id
     INNER JOIN T_Archive_Update_State_Name AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
     INNER JOIN T_Archive_Path AP
       ON DA.AS_storage_path_ID = AP.AP_path_ID
     INNER JOIN dbo.T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Archive] TO [DDL_Viewer] AS [dbo]
GO
