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
   dbo.T_Storage_Path.SP_vol_name_client + dbo.T_Storage_Path.SP_path
    AS Storage, dbo.T_Dataset.DS_created AS Created,
   dbo.T_Dataset.Dataset_ID,
   dbo.T_Dataset_Archive.AS_datetime AS ArchDate,
   dbo.T_Dataset.DS_Comp_State AS CompState
FROM dbo.T_Dataset INNER JOIN
   dbo.T_Dataset_State_Name ON
   dbo.T_Dataset.DS_state_ID = dbo.T_Dataset_State_Name.Dataset_state_ID
    INNER JOIN
   dbo.T_Instrument_Name ON
   dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
    INNER JOIN
   dbo.T_Storage_Path ON
   dbo.T_Dataset.DS_storage_path_ID = dbo.T_Storage_Path.SP_path_ID
    INNER JOIN
   dbo.T_Dataset_Archive ON
   dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID
    INNER JOIN
   dbo.T_Dataset_Archive_State_Name ON
   dbo.T_Dataset_Archive.AS_state_ID = dbo.T_Dataset_Archive_State_Name.archive_state_id
WHERE (dbo.T_Dataset_State_Name.DSS_name = 'complete') AND
   (dbo.T_Dataset_Archive_State_Name.archive_state = 'complete')
    AND (dbo.T_Instrument_Name.IN_name LIKE '%FTICR%')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Datasets_For_Compression] TO [DDL_Viewer] AS [dbo]
GO
