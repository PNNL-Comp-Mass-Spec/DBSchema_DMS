/****** Object:  View [dbo].[V_Mage_FPkg_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mage_FPkg_Dataset_List]
AS
/*
 * This view was used by the File Packager tool written by Gary Kiebel in 2012
 * As of September 2013 this tool is not in use and thus this view could likely be deleted in the future
 */
SELECT DL.Dataset_ID,
       DL.Folder,
       SPath.SP_vol_name_client + SPath.SP_path AS Storage_Path,
       AP.AP_network_share_path + '\' AS Archive_Path,
       DA.AS_instrument_data_purged AS Purged,
       DL.Dataset,
       DL.Experiment,
       DL.Campaign,
       DL.Instrument,
       DL.State,
       DL.Created,
       DL.Comment,
       DL.Dataset_Type
FROM T_Dataset DS
     INNER JOIN V_Mage_Dataset_List DL
       ON DS.Dataset_ID = DL.Dataset_ID
     INNER JOIN T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN T_Dataset_Archive DA
                     INNER JOIN T_Archive_Path AP
                       ON DA.AS_storage_path_ID = AP.AP_path_ID
       ON DS.Dataset_ID = DA.AS_Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Dataset_List] TO [DDL_Viewer] AS [dbo]
GO
