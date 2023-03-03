/****** Object:  View [dbo].[V_Analysis_Job_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_List_Report_2]
AS
SELECT AJ.AJ_jobID AS job,
       AJ.AJ_priority AS pri,
       AJ.AJ_StateNameCached AS state,
       AJ.Aj_ToolNameCached AS tool,
       DS.Dataset_Num AS dataset,
       C.Campaign_Num AS campaign,
       E.Experiment_Num AS experiment,
       InstName.IN_name AS instrument,
       AJ.AJ_parmFileName AS param_file,
       AJ.AJ_settingsFileName AS settings_file,
       ExpOrg.OG_Name As organism,
       BTO.Tissue AS tissue,
       JobOrg.OG_name AS job_organism,
       AJ.AJ_organismDBName AS organism_db,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       AJ.AJ_proteinOptionsList AS protein_options,
       AJ.AJ_comment AS comment,
       DS.Dataset_ID AS dataset_id,
       AJ.AJ_created AS created,
       AJ.AJ_start AS started,
       AJ.AJ_finish AS finished,
       CAST(AJ.AJ_ProcessingTimeMinutes AS DECIMAL(9, 2)) AS runtime_minutes,
       CAST(AJ.Progress AS DECIMAL(9,2)) AS progress,
       CAST(AJ.ETA_Minutes AS DECIMAL(18,1)) AS eta_minutes,
       AJ.AJ_requestID AS job_request,
       ISNULL(AJ.AJ_resultsFolderName, '(none)') AS results_folder,
       CASE WHEN AJ.AJ_Purged = 0
       THEN SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName
       ELSE 'Purged'
       END AS results_folder_path,
       CASE
           WHEN AJ.AJ_Purged = 0 THEN DFP.Dataset_URL + AJ.AJ_resultsFolderName + '/'
           ELSE DFP.Dataset_URL
       END AS results_url,
       AJ.AJ_Last_Affected AS last_affected,
       DR.DRN_name AS rating
FROM T_Analysis_Job AJ
     INNER JOIN T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_Dataset_Rating_Name DR
       ON DS.DS_rating = DR.DRN_state_ID
     INNER JOIN T_Organisms JobOrg
       ON AJ.AJ_organismID = JobOrg.Organism_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Organisms ExpOrg
       ON E.EX_organism_ID = ExpOrg.Organism_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     LEFT OUTER JOIN T_Cached_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
       ON BTO.Identifier = E.EX_Tissue_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
