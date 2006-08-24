/****** Object:  View [dbo].[V_Purgable_Datasets_NoJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Purgable_Datasets_NoJob
AS
SELECT     
	T_Dataset.Dataset_ID, 
	t_storage_path.SP_machine_name AS StorageServerName, 
	t_storage_path.SP_vol_name_server AS ServerVol, 
	T_Dataset.DS_created AS Created,
	T_Instrument_Class.raw_data_type
FROM
	T_Dataset INNER JOIN
	T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID INNER JOIN
	t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
	T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
	T_Instrument_Class ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
WHERE
	(T_Instrument_Class.is_purgable > 0) AND 
	(T_Dataset_Archive.AS_state_ID = 3) AND 
	(T_Dataset.DS_rating <> - 1) AND
	(ISNULL(T_Dataset_Archive.AS_purge_holdoff_date, GETDATE()) <= GETDATE()) AND 
	(T_Dataset.Dataset_ID NOT IN
	(SELECT     AJ_datasetID
	FROM          T_Analysis_Job))

GO
