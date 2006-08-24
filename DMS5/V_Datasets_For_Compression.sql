/****** Object:  View [dbo].[V_Datasets_For_Compression] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Datasets_For_Compression
AS
SELECT dbo.T_Dataset.Dataset_Num AS Dataset, 
   dbo.T_Instrument_Name.IN_name AS Instrument, 
   dbo.T_Dataset.DS_folder_name AS FolderName, 
   dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path
    AS Storage, dbo.T_Dataset.DS_created AS Created, 
   dbo.T_Dataset.Dataset_ID, 
   dbo.T_Dataset_Archive.AS_datetime AS ArchDate, 
   dbo.T_Dataset.DS_Comp_State AS CompState
FROM dbo.T_Dataset INNER JOIN
   dbo.T_DatasetStateName ON 
   dbo.T_Dataset.DS_state_ID = dbo.T_DatasetStateName.Dataset_state_ID
    INNER JOIN
   dbo.T_Instrument_Name ON 
   dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
    INNER JOIN
   dbo.t_storage_path ON 
   dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID
    INNER JOIN
   dbo.T_Dataset_Archive ON 
   dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID
    INNER JOIN
   dbo.T_DatasetArchiveStateName ON 
   dbo.T_Dataset_Archive.AS_state_ID = dbo.T_DatasetArchiveStateName.DASN_StateID
WHERE (dbo.T_DatasetStateName.DSS_name = 'complete') AND 
   (dbo.T_DatasetArchiveStateName.DASN_StateName = 'complete')
    AND (dbo.T_Instrument_Name.IN_name LIKE '%FTICR%')
GO
