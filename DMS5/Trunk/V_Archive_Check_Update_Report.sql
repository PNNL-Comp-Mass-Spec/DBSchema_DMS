/****** Object:  View [dbo].[V_Archive_Check_Update_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archive_Check_Update_Report
AS
SELECT DA.AS_Dataset_ID AS [Dataset ID],
       DS.Dataset_Num AS Dataset,
       InstName.IN_name AS Instrument,
       SP.SP_machine_name AS [Storage Server],
       DS.DS_created AS [DS Created],
       AUSN.AUS_name AS [Archive Update State],
       DA.AS_update_state_Last_Affected AS [Update Last Affected],
       DA.AS_last_update AS [Last Update],
       DASN.DASN_StateName AS [Archive State],
       DA.AS_state_Last_Affected AS [Last Affected],
       AP.AP_archive_path AS [Archive Path],
       AP.AP_Server_Name AS [Archive Server]
FROM dbo.T_Dataset_Archive DA
     INNER JOIN dbo.T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_DatasetArchiveStateName DASN
       ON DA.AS_state_ID = DASN.DASN_StateID
     INNER JOIN dbo.T_Archive_Path AP
       ON DA.AS_storage_path_ID = AP.AP_path_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Archive_Update_State_Name AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
     INNER JOIN dbo.t_storage_path SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
WHERE (NOT (DA.AS_update_state_ID IN (4, 6)))

GO
