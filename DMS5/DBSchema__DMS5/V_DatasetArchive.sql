/****** Object:  View [dbo].[V_DatasetArchive] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  View dbo.V_DatasetArchive    Script Date: 1/23/2001 3:26:00 PM *****
***** Object:  View dbo.V_DatasetArchive    Script Date: 1/17/2001 2:15:34 PM ******/
CREATE VIEW dbo.V_DatasetArchive
AS
SELECT     dbo.T_Dataset.Dataset_Num AS Dataset_Number, dbo.T_Dataset.DS_folder_name AS Folder_Name, 
                      dbo.t_storage_path.SP_vol_name_server AS Server_Vol, dbo.t_storage_path.SP_vol_name_client AS Client_Vol, 
                      dbo.t_storage_path.SP_path AS Storage_Path, dbo.T_Archive_Path.AP_archive_path AS Archive_Path, 
                      dbo.T_Instrument_Name.IN_class AS Instrument_Class, dbo.T_Dataset_Archive.AS_last_update AS Last_Update, 
                      dbo.T_Dataset_Archive.AS_state_ID AS Archive_State, dbo.T_Instrument_Name.IN_name AS Instrument_Name, 
                      dbo.T_Dataset_Archive.AS_last_verify AS Last_Verify
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Archive_Path ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Archive_Path.AP_instrument_name_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID

GO
