/****** Object:  View [dbo].[V_Archive_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Archive_List_Report]
AS
SELECT DA.AS_Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
       DS.DS_created AS created,
       DASN.archive_state AS state,
       AUSN.AUS_name AS [update],
       DA.AS_datetime AS entered,
       DA.AS_last_update AS last_update,
       DA.AS_last_verify AS last_verify,
       APath.AP_archive_path AS archive_path,
       APath.AP_Server_Name AS archive_server,
	   DA.AS_instrument_data_purged AS instrument_data_purged
FROM dbo.T_Dataset_Archive DA
     INNER JOIN dbo.T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_Dataset_Archive_State_Name DASN
       ON DA.AS_state_ID = DASN.archive_state_id
     INNER JOIN dbo.T_Archive_Path APath
       ON DA.AS_storage_path_ID = APath.AP_path_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Dataset_Archive_Update_State_Name AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_List_Report] TO [DDL_Viewer] AS [dbo]
GO
