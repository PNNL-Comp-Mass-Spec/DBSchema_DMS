/****** Object:  View [dbo].[V_Data_Package_Analysis_Job_PSM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Analysis_Job_PSM_List_Report]
AS
SELECT DPJ.Data_Package_ID As data_pkg,
        AJ.AJ_jobID AS job,
        AJ.AJ_StateNameCached AS state,
        AnalysisTool.AJT_toolName AS tool,
        DS.Dataset_Num AS dataset,
        InstName.IN_name AS instrument,
        PSM.spectra_searched,
        PSM.Total_PSMs AS total_psms_msgf,
        PSM.Unique_Peptides AS unique_peptides_msgf,
        PSM.Unique_Proteins AS unique_proteins_msgf,
        PSM.Total_PSMs_FDR_Filter AS total_psms_fdr,
        PSM.Unique_Peptides_FDR_Filter AS unique_peptides_fdr,
        PSM.Unique_Proteins_FDR_Filter AS unique_proteins_fdr,
        PSM.MSGF_Threshold AS msgf_threshold,
        Convert(decimal(9,2), PSM.FDR_Threshold * 100.0) AS fdr_threshold_pct,
        -- CAST(QCM.P_4A * 100 AS decimal(9,1)) AS pct_tryptic,
        -- CAST(QCM.P_4B * 100 AS decimal(9,1)) AS pct_missed_clvg,
        -- QCM.P_2A AS tryptic_psms,
        -- QCM.Keratin_2A AS keratin_psms,
        -- QCM.Trypsin_2A AS trypsin_psms,
        PSM.Tryptic_Peptides_FDR AS unique_tryptic_peptides,
        CAST(PSM.Tryptic_Peptides_FDR / Cast(NullIf(PSM.unique_peptides_fdr_filter, 0) AS float) * 100 AS decimal(9,1)) AS pct_tryptic,
        CAST(PSM.Missed_Cleavage_Ratio_FDR * 100 AS decimal(9,1)) AS pct_missed_clvg,
        PSM.Keratin_Peptides_FDR AS keratin_pep,
        PSM.Trypsin_Peptides_FDR AS trypsin_pep,
        PSM.Acetyl_Peptides_FDR AS acetyl_pep,
        Convert(decimal(9,2), PSM.Percent_PSMs_Missing_NTermReporterIon) AS pct_missing_nterm_rep_ion,
        Convert(decimal(9,2), PSM.Percent_PSMs_Missing_ReporterIon) AS pct_missing_rep_ion,
        PSM.Last_Affected AS psm_stats_date,
        PhosphoPSM.PhosphoPeptides AS phospho_pep,
        PhosphoPSM.CTermK_Phosphopeptides AS cterm_k_phospho_pep,
        PhosphoPSM.CTermR_Phosphopeptides AS cterm_r_phospho_pep,
        CAST(PhosphoPSM.MissedCleavageRatio * 100 AS decimal(9,1)) AS phospho_pct_missed_clvg,
        C.Campaign_Num AS campaign,
        E.Experiment_Num AS experiment,
        AJ.AJ_parmFileName AS param_file,
        AJ.AJ_settingsFileName AS settings_file,
        Org.OG_name AS organism,
        AJ.AJ_organismDBName AS organism_db,
        AJ.AJ_proteinCollectionList AS protein_collection_list,
        AJ.AJ_proteinOptionsList AS protein_options,
        AJ.AJ_comment AS comment,
        AJ.AJ_finish AS finished,
        CONVERT(DECIMAL(9, 2), AJ.AJ_ProcessingTimeMinutes) AS runtime_minutes,
        AJ.AJ_requestID AS job_request,
        ISNULL(AJ.aj_resultsfoldername, '(none)') AS results_folder,
        CASE WHEN AJ.AJ_Purged = 0
        THEN SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '\' + AJ.aj_resultsfoldername
        ELSE DAP.Archive_Path + '\' + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '\' + AJ.aj_resultsfoldername
        END AS results_folder_path,
        DR.DRN_name AS rating,
        DS.Acq_Length_Minutes AS acq_length,
        DS.dataset_id,
        DS.acq_time_start,
        AJ.AJ_StateID AS state_id,
        CAST(AJ.Progress AS DECIMAL(9,2)) AS job_progress,
        CAST(AJ.ETA_Minutes AS DECIMAL(18,1)) AS job_eta_minutes
FROM dbo.S_V_Data_Package_Analysis_Jobs_Export DPJ
     INNER JOIN dbo.T_Analysis_Job AS AJ
       ON AJ.AJ_JobID = DPJ.Job
     INNER JOIN dbo.T_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.V_Dataset_Archive_Path AS DAP
       ON DAP.Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Dataset_Rating_Name AS DR
       ON DS.DS_rating = DR.DRN_state_ID
     INNER JOIN dbo.T_Organisms AS Org
       ON AJ.AJ_organismID = Org.Organism_ID
     INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Experiments AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats PSM
       ON AJ.AJ_JobID = PSM.Job
     LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats_Phospho PhosphoPSM
       ON PSM.Job = PhosphoPSM.Job
WHERE AJ.AJ_analysisToolID IN ( SELECT AJT_toolID
                                FROM T_Analysis_Tool
                                WHERE AJT_resultType LIKE '%peptide_hit' OR
                                      AJT_resultType = 'Gly_ID' )

GO
