/****** Object:  View [dbo].[V_DatasetArchive_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DatasetArchive_Ex
AS
SELECT     dbo.T_Dataset.Dataset_ID, dbo.T_Dataset.Dataset_Num AS Dataset_Number, dbo.T_Dataset.DS_folder_name AS Folder_Name, 
                      dbo.t_storage_path.SP_vol_name_server + dbo.t_storage_path.SP_path AS ServerPath, 
                      dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path AS ClientPath, dbo.T_Archive_Path.AP_archive_path AS Archive_Path, 
                      dbo.T_Archive_Path.AP_Server_Name AS Archive_Server, dbo.T_Instrument_Name.IN_class AS Instrument_Class, 
                      dbo.T_Dataset_Archive.AS_last_update AS Last_Update, dbo.T_Dataset_Archive.AS_state_ID AS Archive_State, 
                      dbo.T_Dataset_Archive.AS_update_state_ID AS Update_State, dbo.T_Instrument_Name.IN_name AS Instrument_Name, 
                      dbo.T_Dataset_Archive.AS_last_verify AS Last_Verify, dbo.T_Instrument_Class.requires_preparation AS Requires_Prep, 
                      dbo.T_Instrument_Class.is_purgable AS Is_Purgeable
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset_Archive.AS_storage_path_ID = dbo.T_Archive_Path.AP_path_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class

GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetArchive_Ex] TO [PNL\D3M578] AS [dbo]
GO
