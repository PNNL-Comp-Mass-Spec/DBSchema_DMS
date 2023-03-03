/****** Object:  View [dbo].[V_Archive_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_List_Report_2]
AS
SELECT DA.AS_Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       TIN.IN_name AS instrument,
       DASN.archive_state AS state,
       AUS.AUS_name AS update_state,
       DA.AS_datetime AS entered,
       DA.AS_state_Last_Affected AS state_last_affected,
       DA.AS_update_state_Last_Affected AS update_state_last_affected,
       TAP.AP_archive_path AS archive_path,
       TAP.AP_Server_Name AS archive_server,
       SPath.SP_machine_name AS storage_server,
       DA.AS_instrument_data_purged AS instrument_data_purged
FROM dbo.T_Dataset_Archive AS DA
     INNER JOIN dbo.T_Dataset AS DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_Dataset_Archive_State_Name AS DASN
       ON DA.AS_state_ID = DASN.archive_state_id
     INNER JOIN dbo.T_Archive_Path AS TAP
       ON DA.AS_storage_path_ID = TAP.AP_path_ID
     INNER JOIN dbo.T_Instrument_Name AS TIN
       ON DS.DS_instrument_name_ID = TIN.Instrument_ID
     INNER JOIN dbo.T_Archive_Update_State_Name AS AUS
       ON DA.AS_update_state_ID = AUS.AUS_stateID
     INNER JOIN dbo.T_Storage_Path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
