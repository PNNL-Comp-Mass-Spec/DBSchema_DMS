/****** Object:  View [dbo].[V_Analysis_Job_Detail_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Detail_Report_2]
AS
SELECT AJ.AJ_jobID AS job,
       DS.Dataset_Num AS dataset,
       E.Experiment_Num AS experiment,
       DS.DS_folder_name AS dataset_folder,
       DFP.Dataset_Folder_Path AS dataset_folder_path,
       CASE
           WHEN ISNULL(DA.MyEmslState, 0) > 1 THEN ''
           ELSE DFP.Archive_Folder_Path
       END AS archive_folder_path,
       InstName.IN_name AS instrument,
       AnalysisTool.AJT_toolName AS tool_name,
       AJ.AJ_parmFileName AS param_file,
       AnalysisTool.AJT_parmFileStoragePath AS param_file_storage_path,
       AJ.AJ_settingsFileName AS settings_file,
       ExpOrg.OG_Name As organism,
       BTO.Tissue AS experiment_tissue,
       JobOrg.OG_name AS job_organism,
       AJ.AJ_organismDBName AS organism_db,
       dbo.get_fasta_file_path(AJ.AJ_organismDBName, JobOrg.OG_name) AS organism_db_storage_path,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       AJ.AJ_proteinOptionsList AS protein_options_list,
       CASE WHEN AJ.AJ_StateID = 2 THEN ASN.AJS_name + ': ' +
              CAST(CAST(IsNull(AJ.Progress, 0) AS DECIMAL(9,2)) AS VARCHAR(12)) + '%, ETA ' +
              CASE
                WHEN AJ.ETA_Minutes IS NULL THEN '??'
                WHEN AJ.ETA_Minutes > 3600 THEN CAST(CAST(AJ.ETA_Minutes/1440.0 AS DECIMAL(18,1)) AS VARCHAR(12)) + ' days'
                WHEN AJ.ETA_Minutes > 90 THEN CAST(CAST(AJ.ETA_Minutes/60.0 AS DECIMAL(18,1)) AS VARCHAR(12)) + ' hours'
                ELSE CAST(CAST(AJ.ETA_Minutes AS DECIMAL(18,1)) AS VARCHAR(12)) + ' minutes'
              END
           ELSE ASN.AJS_name
           END AS state,
       CONVERT(decimal(9, 2), AJ.AJ_ProcessingTimeMinutes) AS runtime_minutes,
       AJ.AJ_owner AS owner,
       AJ.AJ_comment AS comment,
       AJ.AJ_specialProcessing AS special_processing,
       CASE
           WHEN AJ.AJ_Purged = 0 THEN dbo.combine_paths(DFP.Dataset_Folder_Path, AJ.AJ_resultsFolderName)
           ELSE 'Purged: ' + dbo.combine_paths(DFP.Dataset_Folder_Path, AJ.AJ_resultsFolderName)
       END AS results_folder_path,
       CASE
           WHEN AJ.AJ_MyEMSLState > 0 OR ISNULL(DA.MyEmslState, 0) > 1 THEN ''
           ELSE dbo.combine_paths(DFP.Archive_Folder_Path, AJ.AJ_resultsFolderName)
       END AS archive_results_folder_path,
       CASE
           WHEN AJ.AJ_Purged = 0 THEN DFP.Dataset_URL + AJ.AJ_resultsFolderName + '/'
           ELSE DFP.Dataset_URL
       END AS data_folder_link,
       dbo.get_job_psm_stats(AJ.AJ_JobID) AS psm_stats,
       ISNULL(MTSPT.PT_DB_Count, 0) AS mts_pt_db_count,
       ISNULL(MTSMT.MT_DB_Count, 0) AS mts_mt_db_count,
       ISNULL(PMTaskCountQ.PMTasks, 0) AS peak_matching_results,
       AJ.AJ_created AS created,
       AJ.AJ_start AS started,
       AJ.AJ_finish AS finished,
       AJ.AJ_requestID AS request,
       AJ.AJ_priority AS priority,
       AJ.AJ_assignedProcessorName AS assigned_processor,
       AJ.AJ_Analysis_Manager_Error AS am_code,
       dbo.get_dem_code_string(AJ.AJ_Data_Extraction_Error) AS dem_code,
       CASE AJ.AJ_propagationMode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS export_mode,
       T_YesNo.Description AS dataset_unreviewed,
       T_MyEMSLState.StateName AS myemsl_state,
      AJPG.Group_Name AS processor_group
FROM S_V_BTO_ID_to_Name AS BTO
     RIGHT OUTER JOIN T_Analysis_Job AS AJ
                      INNER JOIN T_Dataset AS DS
                        ON AJ.AJ_datasetID = DS.Dataset_ID
                      INNER JOIN T_Experiments AS E
                        ON DS.Exp_ID = E.Exp_ID
                      INNER JOIN T_Organisms ExpOrg
                        ON E.EX_organism_ID = ExpOrg.Organism_ID
                      LEFT OUTER JOIN V_Dataset_Folder_Paths AS DFP
                        ON DFP.Dataset_ID = DS.Dataset_ID
                      INNER JOIN T_Storage_Path AS SPath
                        ON DS.DS_storage_path_ID = SPath.SP_path_ID
                      INNER JOIN T_Analysis_Tool AS AnalysisTool
                        ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
                      INNER JOIN T_Analysis_State_Name AS ASN
                        ON AJ.AJ_StateID = ASN.AJS_stateID
                      INNER JOIN T_Instrument_Name AS InstName
                        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                      INNER JOIN T_Organisms AS JobOrg
                        ON JobOrg.Organism_ID = AJ.AJ_organismID
                      INNER JOIN T_YesNo
                        ON AJ.AJ_DatasetUnreviewed = T_YesNo.Flag
                      INNER JOIN T_MyEMSLState
                        ON AJ.AJ_MyEMSLState = T_MyEMSLState.MyEMSLState
       ON BTO.Identifier = E.EX_Tissue_ID
     LEFT OUTER JOIN T_Analysis_Job_Processor_Group AS AJPG
                     INNER JOIN T_Analysis_Job_Processor_Group_Associations AS AJPJA
                       ON AJPG.ID = AJPJA.Group_ID
       ON AJ.AJ_jobID = AJPJA.Job_ID
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) AS MT_DB_Count
                       FROM T_MTS_MT_DB_Jobs_Cached
                       GROUP BY Job ) AS MTSMT
       ON AJ.AJ_jobID = MTSMT.Job
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) AS PT_DB_Count
                       FROM T_MTS_PT_DB_Jobs_Cached
                       GROUP BY Job ) AS MTSPT
       ON AJ.AJ_jobID = MTSPT.Job
     LEFT OUTER JOIN ( SELECT DMS_Job,
                              COUNT(*) AS PMTasks
                       FROM T_MTS_Peak_Matching_Tasks_Cached AS PM
                       GROUP BY DMS_Job ) AS PMTaskCountQ
       ON PMTaskCountQ.DMS_Job = AJ.AJ_jobID
     LEFT OUTER JOIN T_Dataset_Archive AS DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Detail_Report_2] TO [DDL_Viewer] AS [dbo]
GO
