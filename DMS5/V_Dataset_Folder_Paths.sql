/****** Object:  View [dbo].[V_Dataset_Folder_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Folder_Paths]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       DFPCache.Dataset_Folder_Path,
       DFPCache.Archive_Folder_Path,
       DFPCache.MyEMSL_Path_Flag,
       DFPCache.Dataset_URL,
       DA.AS_instrument_data_purged AS Instrument_Data_Purged
FROM dbo.T_Dataset DS
     INNER JOIN T_Cached_Dataset_Folder_Paths DFPCache
       ON DS.Dataset_ID = DFPCache.Dataset_ID
     LEFT OUTER JOIN dbo.T_Dataset_Archive DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Folder_Paths] TO [DDL_Viewer] AS [dbo]
GO
