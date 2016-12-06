/****** Object:  View [dbo].[V_Analysis_Job_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Analysis_Job_List_Report_2] as
SELECT  AJ.AJ_jobID AS Job ,
        AJ.AJ_priority AS Pri ,
        AJ.AJ_StateNameCached AS State ,
		AJ.Aj_ToolNameCached AS Tool,
        DS.Dataset_Num AS Dataset ,
        C.Campaign_Num AS Campaign ,
        E.Experiment_Num AS Experiment ,
        InstName.IN_name AS Instrument ,
        AJ.AJ_parmFileName AS [Parm File] ,
        AJ.AJ_settingsFileName AS Settings_File ,
        Org.OG_name AS Organism ,
        AJ.AJ_organismDBName AS [Organism DB] ,
        AJ.AJ_proteinCollectionList AS [Protein Collection List] ,
        AJ.AJ_proteinOptionsList AS [Protein Options] ,
        AJ.AJ_comment AS Comment,
        AJ.AJ_created AS Created ,
        AJ.AJ_start AS Started ,
        AJ.AJ_finish AS Finished ,
        CAST(AJ.AJ_ProcessingTimeMinutes AS DECIMAL(9, 2)) AS Runtime ,
		CAST(AJ.Progress AS DECIMAL(9,2)) AS Progress,
	    CAST(AJ.ETA_Minutes AS DECIMAL(18,1)) AS ETA_Minutes,
        AJ.AJ_requestID AS [Job Request] ,
        ISNULL(AJ.AJ_resultsFolderName, '(none)') AS [Results Folder] ,
        CASE WHEN AJ.AJ_Purged = 0
        THEN SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName 
        ELSE 'Purged'
        END AS [Results Folder Path],
        AJ.AJ_Last_Affected AS Last_Affected,
        DR.DRN_name AS Rating
FROM T_Analysis_Job AJ INNER JOIN
   T_Dataset DS ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
   T_Storage_Path SPath ON DS.DS_storage_path_ID = SPath.SP_path_ID INNER JOIN
   T_DatasetRatingName DR ON DS.DS_rating = DR.DRN_state_ID INNER JOIN
   T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID INNER JOIN
   T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN
   T_Experiments E ON DS.Exp_ID = E.Exp_ID INNER JOIN
   T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID




GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
