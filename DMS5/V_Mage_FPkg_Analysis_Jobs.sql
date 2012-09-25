/****** Object:  View [dbo].[V_Mage_FPkg_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Mage_FPkg_Analysis_Jobs as
SELECT  AJ.AJ_jobID AS Job ,
        CASE WHEN ISNULL(AJ.AJ_Purged, 0) = 0
             THEN SPath.SP_vol_name_client + SPath.SP_path
             ELSE AP.AP_network_share_path + '\'
        END + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\'
        + AJ.AJ_resultsFolderName AS Folder ,
        SPath.SP_vol_name_client + SPath.SP_path AS Storage_Path ,
        AP.AP_network_share_path + '\' AS Archive_Path ,
        AJ.AJ_Purged AS Purged ,
        AJ.AJ_StateNameCached AS State ,
        DS.Dataset_Num AS Dataset ,
        DS.Dataset_ID ,
        AJT.AJT_toolName AS Tool ,
        AJ.AJ_parmFileName AS Parameter_File ,
        AJ.AJ_settingsFileName AS Settings_File ,
        InstName.IN_name AS Instrument ,
        EX.Experiment_Num AS Experiment ,
        C.Campaign_Num AS Campaign ,
        Org.OG_name AS Organism ,
        AJ.AJ_organismDBName AS [Organism DB] ,
        AJ.AJ_proteinCollectionList AS [Protein Collection List] ,
        AJ.AJ_proteinOptionsList AS [Protein Options] ,
        AJ.AJ_comment AS Comment ,
        AJ.AJ_finish AS Job_Finish
FROM    T_Analysis_Job AS AJ
        INNER JOIN dbo.T_Analysis_Tool AS AJT ON AJ.AJ_analysisToolID = AJT.AJT_toolID
        INNER JOIN T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID
        LEFT OUTER JOIN T_Dataset_Archive AS DA ON DS.Dataset_ID = DA.AS_Dataset_ID
        INNER JOIN T_Archive_Path AS AP ON DA.AS_storage_path_ID = AP.AP_path_ID
        INNER JOIN T_Storage_Path AS SPath ON DS.DS_storage_path_ID = SPath.SP_path_ID
        INNER JOIN T_Experiments AS EX ON DS.Exp_ID = EX.Exp_ID
        INNER JOIN T_Campaign AS C ON EX.EX_campaign_ID = C.Campaign_ID
        INNER JOIN T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
        INNER JOIN T_DatasetTypeName AS DTN ON DS.DS_type_ID = DTN.DST_Type_ID
        INNER JOIN T_Organisms AS Org ON AJ.AJ_organismID = Org.Organism_ID
        RIGHT OUTER JOIN T_DatasetStateName AS DSN ON DSN.Dataset_state_ID = DS.DS_state_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Analysis_Jobs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Analysis_Jobs] TO [PNL\D3M580] AS [dbo]
GO
