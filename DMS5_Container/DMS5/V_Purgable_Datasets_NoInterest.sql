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
       InstClass.raw_data_type,
       DA.AS_StageMD5_Required AS StageMD5_Required,
       MAX(COALESCE(AJ.AJ_Start, AJ.AJ_created, DS.DS_Created)) AS MostRecentJob	-- Note: Do not use AJ_Finish since numerous old jobs were re-run in December 2011
FROM dbo.T_Dataset AS DS
     INNER JOIN dbo.T_Dataset_Archive AS DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
     INNER JOIN dbo.t_storage_path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Instrument_Class AS InstClass
       ON InstName.IN_class = InstClass.IN_class
     LEFT OUTER JOIN dbo.T_Analysis_Job AS AJ
       ON DS.Dataset_ID = AJ.AJ_datasetID
WHERE (InstClass.is_purgable > 0) AND
      (DA.AS_state_ID = 3) AND
      (DS.DS_rating NOT IN (- 2, - 10)) AND
      (ISNULL(DA.AS_purge_holdoff_date, GETDATE()) <= GETDATE() OR
       DA.AS_StageMD5_Required > 0) AND
      (DA.AS_update_state_ID = 4) AND
      (DS.DS_rating < 2)
GROUP BY DS.Dataset_ID, SPath.SP_machine_name, SPath.SP_vol_name_server, 
         DS.DS_created, InstClass.raw_data_type, DA.AS_StageMD5_Required



GO
GRANT VIEW DEFINITION ON [dbo].[V_Purgable_Datasets_NoInterest] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Purgable_Datasets_NoInterest] TO [PNL\D3M580] AS [dbo]
GO
