/****** Object:  View [dbo].[V_Archive_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Archive_Check_Report
AS
SELECT     T_Dataset.Dataset_Num AS Dataset, T_DatasetArchiveStateName.DASN_StateName AS State, T_Event_Log.Entered, 
                      T_Instrument_Name.IN_name AS Instrument, t_storage_path.SP_machine_name AS [Storage Server], 
                      T_Archive_Path.AP_archive_path AS [Archive Path], dbo.GetArchiveVerificationMachine(T_Dataset.Dataset_Num) AS PrepServer
FROM         T_Dataset_Archive INNER JOIN
                      T_Event_Log ON T_Dataset_Archive.AS_Dataset_ID = T_Event_Log.Target_ID AND 
                      T_Dataset_Archive.AS_state_ID = T_Event_Log.Target_State INNER JOIN
                      T_DatasetArchiveStateName ON T_Dataset_Archive.AS_state_ID = T_DatasetArchiveStateName.DASN_StateID INNER JOIN
                      T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID INNER JOIN
                      T_Archive_Path ON T_Dataset_Archive.AS_storage_path_ID = T_Archive_Path.AP_path_ID INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE     (T_Event_Log.Target_Type = 6) AND (T_Dataset_Archive.AS_state_ID NOT IN (3, 4, 9, 10))


GO
