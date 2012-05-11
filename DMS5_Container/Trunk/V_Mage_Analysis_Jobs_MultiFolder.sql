/****** Object:  View [dbo].[V_Mage_Analysis_Jobs_MultiFolder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_Mage_Analysis_Jobs_MultiFolder] as 
SELECT  AJ.AJ_jobID AS Job ,
        AJ.AJ_StateNameCached AS State ,
        DS.Dataset_Num AS Dataset ,
        DS.Dataset_ID ,
        AnalysisTool.AJT_toolName AS Tool ,
        AJ.AJ_parmFileName AS Parameter_File ,
        AJ.AJ_settingsFileName AS Settings_File ,
        InstName.IN_name AS Instrument ,
        E.Experiment_Num AS Experiment ,
        C.Campaign_Num AS Campaign ,
        Org.OG_name AS Organism ,
        AJ.AJ_organismDBName AS [Organism DB] ,
        AJ.AJ_proteinCollectionList AS [Protein Collection List] ,
        AJ.AJ_proteinOptionsList AS [Protein Options] ,
        AJ.AJ_comment AS Comment ,
        ISNULL(AJ.AJ_resultsFolderName, '(none)') AS [Results Folder] ,         
        ISNULL(SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName, '') + '|' + 
        ISNULL(DAP.Archive_Path + '\' + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName, '') AS Folder
FROM    V_Dataset_Archive_Path AS DAP
        RIGHT OUTER JOIN T_Analysis_Job AS AJ
        INNER JOIN T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID
        INNER JOIN T_Organisms AS Org ON AJ.AJ_organismID = Org.Organism_ID
        INNER JOIN T_Analysis_Tool AS AnalysisTool ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
        INNER JOIN T_Instrument_Name AS InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
        INNER JOIN T_Experiments AS E ON DS.Exp_ID = E.Exp_ID
        INNER JOIN T_Campaign AS C ON E.EX_campaign_ID = C.Campaign_ID ON DAP.Dataset_ID = DS.Dataset_ID
        INNER JOIN dbo.T_Storage_Path SPath ON DS.DS_storage_path_ID = SPath.SP_path_ID




GO
