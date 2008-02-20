/****** Object:  View [dbo].[V_Purgable_Datasets_NoInterest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Purgable_Datasets_NoInterest]
AS
SELECT DS.Dataset_ID,
       SPath.SP_machine_name AS StorageServerName,
       SPath.SP_vol_name_server AS ServerVol,
       DS.DS_created AS Created,
       InstClass.raw_data_type
FROM dbo.T_Dataset AS DS
     INNER JOIN dbo.T_Dataset_Archive AS DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
     INNER JOIN dbo.t_storage_path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Instrument_Class AS InstClass
       ON InstName.IN_class = InstClass.IN_class
WHERE (InstClass.is_purgable > 0) AND
      (DA.AS_state_ID = 3) AND
      (DS.DS_rating NOT IN (-2, -10)) AND
      (ISNULL(DA.AS_purge_holdoff_date, GETDATE()) <= GETDATE()) AND
      (DA.AS_update_state_ID = 4) AND
      (DS.DS_rating < 2)

GO
