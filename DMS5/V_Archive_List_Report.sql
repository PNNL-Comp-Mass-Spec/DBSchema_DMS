/****** Object:  View [dbo].[V_Archive_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_List_Report]
AS
SELECT DA.AS_Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DASN.DASN_StateName AS State,
       AUS.AUS_name AS [Update],
       DA.AS_datetime AS entered,
       DA.AS_last_update AS Last_Update,
       DA.AS_last_verify AS Last_Verify,
       APath.AP_archive_path AS Archive_Path,
       APath.AP_Server_Name AS Archive_Server,
	   DA.AS_instrument_data_purged AS Instrument_Data_Purged
FROM dbo.T_Dataset_Archive DA
     INNER JOIN dbo.T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_DatasetArchiveStateName DASN
       ON DA.AS_state_ID = DASN.DASN_StateID
     INNER JOIN dbo.T_Archive_Path APath
       ON DA.AS_storage_path_ID = APath.AP_path_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Archive_Update_State_Name AUS
       ON DA.AS_update_state_ID = AUS.AUS_stateID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_List_Report] TO [DDL_Viewer] AS [dbo]
GO
