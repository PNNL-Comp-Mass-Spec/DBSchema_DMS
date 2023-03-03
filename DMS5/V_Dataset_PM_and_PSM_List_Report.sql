/****** Object:  View [dbo].[V_Dataset_PM_and_PSM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_PM_and_PSM_List_Report]
AS
SELECT
       PM.dataset,
       PSM.Unique_Peptides_FDR AS unique_peptides,
       CONVERT(decimal(9,2), QCM.XIC_FWHM_Q3) AS xic_fwhm_q3,
       QCM.mass_error_ppm,
       ISNULL(QCM.mass_error_ppm_viper, -PM.PPM_Shift) AS mass_error_amts,
       ISNULL(QCM.amts_10pct_fdr, PM.AMTs_10pct_FDR) AS amts_10pct_fdr,
	   ISNULL(QCM.amts_25pct_fdr, PM.AMTs_25pct_FDR) AS amts_25pct_fdr,
       DFP.Dataset_URL + 'QC/index.html' AS qc_link,
       PM.Results_URL AS pm_results_url,
	   -- QCM.Phos_2C PhosphoPep,
	   PSM.phospho_pep,
       PM.instrument,
       PM.dataset_id,
       DTN.DST_name AS dataset_type,
       DS.DS_sec_sep AS separation_type,
       DR.DRN_name AS ds_rating,
       PM.Acq_Length AS ds_acq_length,
       PM.Acq_Time_Start AS acq_start,
       PSM.Job AS psm_job,
       PSM.Tool AS psm_tool,
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
FROM V_MTS_PM_Results_List_Report PM
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON PM.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON PM.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Dataset_Rating_Name DR
       ON DS.DS_rating = DR.DRN_state_ID
     LEFT OUTER JOIN V_Dataset_QC_Metrics QCM
       ON PM.Dataset_ID = QCM.Dataset_ID
     LEFT OUTER JOIN V_Analysis_Job_PSM_List_Report PSM
       ON PSM.Dataset_ID = PM.Dataset_ID AND PSM.State_ID NOT IN (5, 14)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_PM_and_PSM_List_Report] TO [DDL_Viewer] AS [dbo]
GO
