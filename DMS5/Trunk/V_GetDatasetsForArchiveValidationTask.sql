/****** Object:  View [dbo].[V_GetDatasetsForArchiveValidationTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_GetDatasetsForArchiveValidationTask
AS
SELECT  TD.Dataset_Num AS Dataset, TD.Dataset_ID AS Dataset_ID, 
	TD.DS_folder_name AS Folder, 
	sp.SP_machine_name AS Storage_Server_Name, 
	sp.SP_vol_name_server AS Storage_Vol, 
	sp.SP_path AS Storage_Path, 
	ap.AP_archive_path AS Archive_Path, 
	ap.AP_Server_Name AS Server_Name, 
	sp.SP_vol_name_client AS Storage_Vol_External, 
	i.IN_class AS Instrument_Class, 
	i.IN_name AS Instrument_Name, 
	c.raw_data_type AS Data_Type
FROM	T_Dataset TD INNER JOIN T_Dataset_Archive da ON TD.Dataset_ID = da.AS_Dataset_ID 
	INNER JOIN t_storage_path sp ON TD.DS_storage_path_ID = sp.SP_path_ID 
	INNER JOIN T_Instrument_Name i ON TD.DS_instrument_name_ID = i.Instrument_ID 
	INNER JOIN T_Archive_Path ap ON da.AS_storage_path_ID = ap.AP_path_ID 
	INNER JOIN T_Instrument_Class c on c.IN_Class = i.IN_Class

GO
