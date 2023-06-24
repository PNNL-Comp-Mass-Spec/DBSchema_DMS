/****** Object:  View [dbo].[V_Find_Archive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Find_Archive
AS
SELECT     dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.Dataset_ID AS ID, dbo.T_Instrument_Name.IN_name AS Instrument,
                      dbo.T_Dataset.DS_created AS Created, dbo.T_Dataset_Archive_State_Name.archive_state AS State,
                      dbo.T_Dataset_Archive_Update_State_Name.AUS_name AS [Update], dbo.T_Dataset_Archive.AS_datetime AS Entered,
                      dbo.T_Dataset_Archive.AS_last_update AS [Last Update], dbo.T_Dataset_Archive.AS_last_verify AS [Last Verify],
                      dbo.T_Archive_Path.AP_archive_path AS [Archive Path], dbo.T_Archive_Path.AP_Server_Name AS [Archive Server]
FROM         dbo.T_Dataset_Archive INNER JOIN
                      dbo.T_Dataset ON dbo.T_Dataset_Archive.AS_Dataset_ID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Dataset_Archive_State_Name ON dbo.T_Dataset_Archive.AS_state_ID = dbo.T_Dataset_Archive_State_Name.archive_state_id INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Dataset_Archive_Update_State_Name ON dbo.T_Dataset_Archive.AS_update_state_ID = dbo.T_Dataset_Archive_Update_State_Name.AUS_stateID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Find_Archive] TO [DDL_Viewer] AS [dbo]
GO
