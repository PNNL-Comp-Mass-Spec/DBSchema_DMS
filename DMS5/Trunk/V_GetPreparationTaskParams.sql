/****** Object:  View [dbo].[V_GetPreparationTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetPreparationTaskParams
AS
SELECT     TOP 100 PERCENT dbo.T_Dataset.Dataset_ID, dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.DS_folder_name AS Folder, 
                      dbo.t_storage_path.SP_vol_name_client AS StorageVolClient, dbo.t_storage_path.SP_vol_name_server AS StorageVolServer, 
                      dbo.t_storage_path.SP_path AS storagePath, dbo.T_Instrument_Class.IN_class AS InstrumentClass
FROM         dbo.T_Dataset INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class
ORDER BY dbo.T_Dataset.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPreparationTaskParams] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPreparationTaskParams] TO [PNL\D3M580] AS [dbo]
GO
