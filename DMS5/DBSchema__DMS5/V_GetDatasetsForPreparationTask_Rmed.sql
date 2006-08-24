/****** Object:  View [dbo].[V_GetDatasetsForPreparationTask_Rmed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW dbo.V_GetDatasetsForPreparationTask_Rmed
AS
SELECT     T_Dataset.Dataset_Num AS Dataset, T_Dataset.DS_created AS Created, T_Dataset.DS_folder_name AS Folder, 
                      t_storage_path.SP_machine_name AS StorageServerName, t_storage_path.SP_vol_name_client AS StorageVolClient, 
                      t_storage_path.SP_vol_name_server AS StorageVolServer, t_storage_path.SP_path AS storagePath, T_Dataset.Dataset_ID, 
                      t_storage_path.SP_path_ID AS StorageID, T_Instrument_Name.IN_class AS InstrumentClass, T_Instrument_Name.IN_name AS InstrumentName, 
                      T_Dataset.DS_Comp_State, T_Dataset.DS_Compress_Date
FROM         T_Dataset INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE     (T_Dataset.DS_state_ID = 3) AND (T_Dataset.DS_Comp_State IS NULL) AND (T_Dataset.DS_Compress_Date IS NULL) AND 
                      (T_Instrument_Name.IN_class LIKE '%FT%')



GO
