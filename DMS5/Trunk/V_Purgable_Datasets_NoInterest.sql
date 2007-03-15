/****** Object:  View [dbo].[V_Purgable_Datasets_NoInterest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Purgable_Datasets_NoInterest
AS
SELECT     dbo.T_Dataset.Dataset_ID, dbo.t_storage_path.SP_machine_name AS StorageServerName, dbo.t_storage_path.SP_vol_name_server AS ServerVol, 
                      dbo.T_Dataset.DS_created AS Created, dbo.T_Instrument_Class.raw_data_type
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class
WHERE     (dbo.T_Instrument_Class.is_purgable > 0) AND (dbo.T_Dataset_Archive.AS_state_ID = 3) AND (dbo.T_Dataset.DS_rating <> - 2) AND 
                      (dbo.T_Dataset.DS_rating < 2) AND (ISNULL(dbo.T_Dataset_Archive.AS_purge_holdoff_date, GETDATE()) <= GETDATE()) AND 
                      (dbo.T_Dataset_Archive.AS_update_state_ID = 4)

GO
