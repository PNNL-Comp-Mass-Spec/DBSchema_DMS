/****** Object:  View [dbo].[V_Purgable_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Purgable_Datasets
AS
SELECT     TD.Dataset_ID, dbo.t_storage_path.SP_machine_name AS StorageServerName, dbo.t_storage_path.SP_vol_name_server AS ServerVol, 
                      MAX(dbo.T_Analysis_Job.AJ_created) AS MostRecentJob, dbo.T_Instrument_Class.raw_data_type
FROM         dbo.T_Dataset TD INNER JOIN
                      dbo.T_Dataset_Archive ON TD.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.T_Instrument_Name ON TD.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Analysis_Job ON TD.Dataset_ID = dbo.T_Analysis_Job.AJ_datasetID INNER JOIN
                      dbo.t_storage_path ON TD.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class
WHERE     (dbo.T_Instrument_Class.is_purgable > 0) AND (dbo.T_Dataset_Archive.AS_state_ID = 3) AND (TD.DS_rating <> - 2) AND 
                      (ISNULL(dbo.T_Dataset_Archive.AS_purge_holdoff_date, GETDATE()) <= GETDATE()) AND (NOT EXISTS
                          (SELECT     *
                            FROM          T_Analysis_Job
                            WHERE      AJ_StateID IN (1, 2, 3, 8, 9, 10, 11, 12) AND AJ_datasetID = TD.Dataset_ID)) AND (dbo.T_Dataset_Archive.AS_update_state_ID = 4)
GROUP BY TD.Dataset_ID, dbo.t_storage_path.SP_machine_name, dbo.t_storage_path.SP_vol_name_server, dbo.T_Instrument_Class.raw_data_type

GO
