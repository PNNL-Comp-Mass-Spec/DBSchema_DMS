/****** Object:  View [dbo].[V_Analysis_Job_PSM_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_PSM_Detail_Report]
AS
SELECT AJ.AJ_jobID AS job,
       DS.Dataset_Num AS dataset,
       E.Experiment_Num AS experiment,
       InstName.IN_name AS instrument,
       CASE WHEN AJ.AJ_Purged = 0
            THEN DFP.Dataset_Folder_Path + '\' + AJ.aj_resultsfoldername
            ELSE 'Purged: ' + DFP.Dataset_Folder_Path + '\' + AJ.aj_resultsfoldername
       END AS results_folder_path,
       CASE WHEN AJ.AJ_Purged = 0
            THEN DFP.Dataset_URL + AJ.AJ_resultsFolderName + '/'
            ELSE DFP.dataset_url
       END AS data_folder_link,
       PSM.Spectra_Searched AS spectra_searched,
       PSM.Total_PSMs AS total_psms_msgf_filtered,
       PSM.Unique_Peptides AS unique_peptides_msgf_filtered,
       PSM.Unique_Proteins AS unique_proteins_msgf_filtered,
       PSM.Total_PSMs_FDR_Filter AS total_psms_fdr_filtered,
       PSM.Unique_Peptides_FDR_Filter AS unique_peptides_fdr_filtered,
       PSM.Unique_Proteins_FDR_Filter AS unique_proteins_fdr_filtered,
       PSM.MSGF_Threshold AS msgf_threshold,
       CONVERT(varchar(12), CONVERT(decimal(5,2), PSM.FDR_Threshold * 100)) + '%' AS fdr_threshold,
	   PSM.Tryptic_Peptides_FDR AS unique_tryptic_peptides,
	   CAST(PSM.Tryptic_Peptides_FDR / Cast(NullIf(PSM.Unique_Peptides_FDR_Filter, 0) AS float) * 100 AS decimal(9,1)) AS pct_tryptic,
	   CAST(PSM.Missed_Cleavage_Ratio_FDR * 100 AS decimal(9,1)) AS pct_missed_cleavage,
	   PSM.Keratin_Peptides_FDR AS unique_keratin_peptides,
	   PSM.Trypsin_Peptides_FDR AS unique_trypsin_peptides,
       Convert(decimal(9,2), PSM.Percent_PSMs_Missing_NTermReporterIon) AS pct_missing_nterm_reporter_ions,
       Convert(decimal(9,2), PSM.Percent_PSMs_Missing_ReporterIon) AS pct_missing_reporter_ions,
       PSM.Last_Affected AS psm_stats_date,
       PhosphoPSM.PhosphoPeptides AS phospho_pep,
       PhosphoPSM.CTermK_Phosphopeptides AS cterm_k_phospho_pep,
       PhosphoPSM.CTermR_Phosphopeptides AS cterm_r_phospho_pep,
	   CAST(PhosphoPSM.MissedCleavageRatio * 100 AS decimal(9,1)) AS phospho_pct_missed_cleavage,
       ISNULL(MTSPT.PT_DB_Count, 0) AS mts_pt_db_count,
       ISNULL(MTSMT.MT_DB_Count, 0) AS mts_mt_db_count,
       ISNULL(PMTaskCountQ.PMTasks, 0) AS peak_matching_results,
       AnalysisTool.AJT_toolName AS tool_name,
       AJ.AJ_parmFileName AS param_file,
       AnalysisTool.AJT_parmFileStoragePath AS param_file_storage_path,
       AJ.AJ_settingsFileName AS settings_file,
       Org.OG_name AS organism,
       AJ.AJ_organismDBName AS organism_db,
       dbo.GetFASTAFilePath(AJ.AJ_organismDBName, Org.OG_name) AS organism_db_storage_path,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       AJ.AJ_proteinOptionsList AS protein_options_list,
       ASN.AJS_name AS state,
       CONVERT(decimal(9, 2), AJ.AJ_ProcessingTimeMinutes) AS runtime_minutes,
       AJ.AJ_owner AS owner,
       AJ.AJ_comment AS comment,
       AJ.AJ_specialProcessing AS special_processing,
       AJ.AJ_created AS created,
       AJ.AJ_start AS started,
       AJ.AJ_finish AS finished,
       AJ.AJ_requestID AS request,
       AJ.AJ_priority AS priority,
       AJ.AJ_assignedProcessorName AS assigned_processor,
       AJ.AJ_Analysis_Manager_Error AS am_code,
       dbo.GetDEMCodeString(AJ.AJ_Data_Extraction_Error) AS dem_code,
       CASE AJ.AJ_propagationMode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS export_mode,
       T_YesNo.Description AS dataset_unreviewed
FROM dbo.T_Analysis_Job AS AJ
     INNER JOIN dbo.T_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Experiments AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN dbo.V_Dataset_Folder_Paths AS DFP
       ON DFP.Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.t_storage_path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN dbo.T_Analysis_State_Name AS ASN
       ON AJ.AJ_StateID = ASN.AJS_stateID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Organisms AS Org
       ON Org.Organism_ID = AJ.AJ_organismID
     INNER JOIN dbo.T_YesNo
       ON AJ.AJ_DatasetUnreviewed = T_YesNo.Flag
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) AS MT_DB_Count
                       FROM dbo.T_MTS_MT_DB_Jobs_Cached
                       GROUP BY Job ) AS MTSMT
       ON AJ.AJ_jobID = MTSMT.Job
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) AS PT_DB_Count
                       FROM dbo.T_MTS_PT_DB_Jobs_Cached
                       GROUP BY Job ) AS MTSPT
       ON AJ.AJ_jobID = MTSPT.Job
     LEFT OUTER JOIN ( SELECT DMS_Job,
                              COUNT(*) AS PMTasks
                       FROM dbo.T_MTS_Peak_Matching_Tasks_Cached AS PM
                       GROUP BY DMS_Job ) AS PMTaskCountQ
       ON PMTaskCountQ.DMS_Job = AJ.AJ_jobID
     LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats AS PSM
       ON AJ.AJ_JobID = PSM.Job
	 LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats_Phospho PhosphoPSM
	   ON PSM.Job = PhosphoPSM.Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_PSM_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
