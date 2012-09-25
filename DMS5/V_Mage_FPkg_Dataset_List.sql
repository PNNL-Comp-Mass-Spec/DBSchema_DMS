/****** Object:  View [dbo].[V_Mage_FPkg_Dataset_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Mage_FPkg_Dataset_List as
SELECT  DS.Dataset_ID ,
        CASE WHEN ISNULL(DA.AS_instrument_data_purged, 0) = 0
             THEN SPath.SP_vol_name_client + SPath.SP_path 
             ELSE AP.AP_network_share_path + '\'
        END + ISNULL(DS.DS_folder_name, DS.Dataset_Num) AS Folder ,
        SPath.SP_vol_name_client + SPath.SP_path AS Storage_Path ,
        AP.AP_network_share_path + '\' AS Archive_Path ,
        DA.AS_instrument_data_purged AS Purged,
        DS.Dataset_Num AS Dataset ,
        EX.Experiment_Num AS Experiment ,
        C.Campaign_Num AS Campaign ,
        InstName.IN_name AS Instrument ,
        DSN.DSS_name AS State ,
        DS.DS_created AS Created ,
        DS.DS_comment AS Comment ,
        DTN.DST_name AS [Type]
FROM    T_Dataset AS DS
        LEFT OUTER JOIN T_Dataset_Archive AS DA ON DS.Dataset_ID = DA.AS_Dataset_ID
        INNER JOIN T_Archive_Path AS AP ON DA.AS_storage_path_ID = AP.AP_path_ID
        INNER JOIN T_Storage_Path AS SPath ON DS.DS_storage_path_ID = SPath.SP_path_ID
        INNER JOIN T_Experiments AS EX ON DS.Exp_ID = EX.Exp_ID
        INNER JOIN T_Campaign AS C ON EX.EX_campaign_ID = C.Campaign_ID
        INNER JOIN T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
        INNER JOIN T_DatasetTypeName AS DTN ON DS.DS_type_ID = DTN.DST_Type_ID
        RIGHT OUTER JOIN T_DatasetStateName AS DSN ON DSN.Dataset_state_ID = DS.DS_state_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Dataset_List] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Dataset_List] TO [PNL\D3M580] AS [dbo]
GO
