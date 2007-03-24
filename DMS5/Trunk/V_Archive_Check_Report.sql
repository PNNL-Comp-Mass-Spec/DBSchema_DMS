/****** Object:  View [dbo].[V_Archive_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archive_Check_Report
AS
SELECT     dbo.T_Dataset.Dataset_ID AS [Dataset ID], dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_DatasetArchiveStateName.DASN_StateName AS State, 
                      dbo.T_Event_Log.Entered, dbo.T_Instrument_Name.IN_name AS Instrument, dbo.t_storage_path.SP_machine_name AS [Storage Server], 
                      dbo.T_Archive_Path.AP_archive_path AS [Archive Path], dbo.GetArchiveVerificationMachine(dbo.T_Dataset.Dataset_Num) AS PrepServer
FROM         dbo.T_Dataset_Archive INNER JOIN
                      dbo.T_Event_Log ON dbo.T_Dataset_Archive.AS_Dataset_ID = dbo.T_Event_Log.Target_ID AND 
                      dbo.T_Dataset_Archive.AS_state_ID = dbo.T_Event_Log.Target_State INNER JOIN
                      dbo.T_DatasetArchiveStateName ON dbo.T_Dataset_Archive.AS_state_ID = dbo.T_DatasetArchiveStateName.DASN_StateID INNER JOIN
                      dbo.T_Dataset ON dbo.T_Dataset_Archive.AS_Dataset_ID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE     (dbo.T_Event_Log.Target_Type = 6) AND (dbo.T_Dataset_Archive.AS_state_ID NOT IN (3, 4, 9, 10))

GO
