/****** Object:  View [dbo].[V_Archive_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archive_List_Report_2]
AS
SELECT DA.AS_Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       TIN.IN_name AS Instrument,
       DASN.DASN_StateName AS State,
       AUS.AUS_name AS [Update],
       DA.AS_datetime AS Entered,
       DA.AS_state_Last_Affected AS [State Last Affected],
       DA.AS_update_state_Last_Affected AS [Update State Last Affected],
       TAP.AP_archive_path AS [Archive Path],
       TAP.AP_Server_Name AS [Archive Server],
       SPath.SP_machine_name AS [Storage Server],
       DA.AS_instrument_data_purged AS [Instrument Data Purged]     
FROM dbo.T_Dataset_Archive AS DA
     INNER JOIN dbo.T_Dataset AS DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_DatasetArchiveStateName AS DASN
       ON DA.AS_state_ID = DASN.DASN_StateID
     INNER JOIN dbo.T_Archive_Path AS TAP
       ON DA.AS_storage_path_ID = TAP.AP_path_ID
     INNER JOIN dbo.T_Instrument_Name AS TIN
       ON DS.DS_instrument_name_ID = TIN.Instrument_ID
     INNER JOIN dbo.T_Archive_Update_State_Name AS AUS
       ON DA.AS_update_state_ID = AUS.AUS_stateID
     INNER JOIN dbo.t_storage_path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
