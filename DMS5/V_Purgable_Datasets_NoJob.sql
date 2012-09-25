/****** Object:  View [dbo].[V_Purgable_Datasets_NoJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Purgable_Datasets_NoJob]
AS
SELECT DS.Dataset_ID,
       SPath.SP_machine_name AS StorageServerName,
       SPath.SP_vol_name_server AS ServerVol,
       DS.DS_created AS Created,
       InstClass.raw_data_type,
       DA.AS_StageMD5_Required AS StageMD5_Required,
       DA.Purge_Priority
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
      (DA.AS_state_ID = 3 OR 
       DA.AS_state_ID = 14 And DA.AS_state_Last_Affected < DATEADD(DAY, -90, GETDATE()) OR
       DA.AS_state_ID = 15 And Purge_Policy = 2
      ) AND
      (DS.DS_rating NOT IN (-2, -10)) AND
      (ISNULL(DA.AS_purge_holdoff_date, GETDATE()) <= GETDATE() OR 
       DA.AS_StageMD5_Required > 0
      ) AND
      (
        -- Select a dataset if the Update State is 4=UpdateRequired, or if the state is between 2 and 5 and the Update State was changed over 60 days ago
        DA.AS_update_state_ID = 4 Or
        DA.AS_update_state_ID IN (2,3,5) And AS_update_state_Last_Affected < DATEADD(DAY, -60, GETDATE())
      ) AND
      (DS.Dataset_ID NOT IN ( SELECT AJ_datasetID
                              FROM dbo.T_Analysis_Job ))





GO
GRANT VIEW DEFINITION ON [dbo].[V_Purgable_Datasets_NoJob] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Purgable_Datasets_NoJob] TO [PNL\D3M580] AS [dbo]
GO
