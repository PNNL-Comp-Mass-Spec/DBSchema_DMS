/****** Object:  View [dbo].[V_Data_Package_Dataset_PSM_And_PM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Dataset_PSM_And_PM_List_Report]
AS
SELECT PSM.data_pkg,
        PSM.dataset,
        PSM.Unique_Peptides_FDR AS unique_peptides,
        CAST(QCM.XIC_FWHM_Q3 AS decimal(9,2)) AS xic_fwhm_q3,
        QCM.mass_error_ppm,
        ISNULL(QCM.mass_error_ppm_viper, -PM.PPM_Shift) AS mass_error_amts,
        ISNULL(QCM.amts_10pct_fdr, PM.AMTs_10pct_FDR) AS amts_10pct_fdr,
        ISNULL(QCM.amts_25pct_fdr, PM.AMTs_25pct_FDR) AS amts_25pct_fdr,
        DFP.Dataset_URL + 'QC/index.html' AS qc_link,
        PM.Results_URL AS pm_results_url,
        -- CAST(QCM.P_4A * 100 AS decimal(9,1)) AS pct_tryptic,
        -- CAST(QCM.P_4B * 100 AS decimal(9,1)) AS pctmissed_clvg,
        -- QCM.Keratin_2A AS keratin_psms,
        -- QCM.Phos_2C AS phospho_pep,
        -- QCM.Trypsin_2A AS trypsin_psms,
        PSM.pct_tryptic,
        PSM.pct_missed_clvg,
        PSM.Total_PSMs_FDR AS psms,
        PSM.keratin_pep,
        PSM.phospho_pep,
        PSM.trypsin_pep,
        PSM.instrument,
        PSM.dataset_id,
        DTN.DST_name AS dataset_type,
        DS.DS_sec_sep AS separation_type,
        PSM.Rating AS ds_rating,
        PSM.Acq_Length AS ds_acq_length,
        PSM.Acq_Time_Start AS acq_start,
        PSM.Job AS psm_job,
        PSM.Tool AS psm_tool,
        PSM.job_progress,
        PSM.job_eta_minutes,
        PSM.campaign,
        PSM.experiment,
        PSM.Param_File AS psm_job_param_file,
        PSM.Settings_File AS psm_job_settings_file,
        PSM.organism,
        PSM.Organism_DB AS psm_job_org_db,
        PSM.Protein_Collection_List AS psm_job_protein_collection,
        PSM.results_folder_path,
        PM.Task_ID AS pm_task_id,
        PM.Task_Server AS pm_server,
        PM.Task_Database AS pm_database,
        PM.Ini_File_Name AS pm_ini_file_name
FROM V_Data_Package_Analysis_Job_PSM_List_Report PSM
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON PSM.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON PSM.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN V_Dataset_QC_Metrics QCM
       ON PSM.Dataset_ID = QCM.Dataset_ID
     LEFT OUTER JOIN V_MTS_PM_Results_List_Report PM
       ON PSM.Dataset_ID = PM.Dataset_ID
WHERE PSM.State_ID NOT IN (5, 14)

GO
