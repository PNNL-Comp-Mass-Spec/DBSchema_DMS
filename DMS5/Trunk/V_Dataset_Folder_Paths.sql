/****** Object:  View [dbo].[V_Dataset_Folder_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Folder_Paths]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       ISNULL(SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num), '') AS Dataset_Folder_Path,
       ISNULL(DAP.Archive_Path + '\' + ISNULL(DS.DS_folder_name, DS.Dataset_Num), '') AS Archive_Folder_Path,
       SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/' AS Dataset_URL,
       DAP.Instrument_Data_Purged
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path DAP
       ON DS.Dataset_ID = DAP.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Folder_Paths] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Folder_Paths] TO [PNL\D3M580] AS [dbo]
GO
