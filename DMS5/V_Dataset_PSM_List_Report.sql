/****** Object:  View [dbo].[V_Dataset_PSM_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_PSM_List_Report]
AS
SELECT PSM.dataset,
       PSM.Unique_Peptides_FDR AS unique_peptides,
       CAST(QCM.XIC_FWHM_Q3 AS decimal(9,2)) AS xic_fwhm_q3,
       QCM.mass_error_ppm,
       DFP.Dataset_URL + 'QC/index.html' AS qc_link,
       -- CAST(QCM.P_4A * 100 AS decimal(9,1)) AS pct_tryptic,
       -- CAST(QCM.P_4B * 100 AS decimal(9,1)) AS pct_missed_clvg,
       -- QCM.Keratin_2A AS keratin_psms,
       -- QCM.Phos_2C Phospho_Pep,
       -- QCM.Trypsin_2A AS trypsin_psms,
       PSM.pct_tryptic,
       PSM.pct_missed_clvg,
       PSM.Total_PSMs_FDR AS psms,
       PSM.keratin_pep,
       PSM.phospho_pep,
       PSM.trypsin_pep,
       PSM.acetyl_pep,
       PSM.ubiquitin_pep,
       PSM.instrument,
       PSM.dataset_id,
       DTN.DST_name AS dataset_type,
       DS.DS_sec_sep AS separation_type,
       PSM.Rating AS ds_rating,
       PSM.Acq_Length AS ds_acq_length,
       PSM.Acq_Time_Start AS acq_start,
       PSM.job,
       PSM.tool,
       PSM.job_progress,
       PSM.job_eta_minutes,
       PSM.campaign,
       PSM.experiment,
       PSM.param_file,
       PSM.settings_file,
       PSM.organism,
       PSM.Organism_DB AS org_db,
       PSM.Protein_Collection_List AS protein_collection,
       PSM.results_folder_path
FROM V_Analysis_Job_PSM_List_Report PSM
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON PSM.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON PSM.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN V_Dataset_QC_Metrics QCM
       ON PSM.Dataset_ID = QCM.Dataset_ID
WHERE PSM.State_ID NOT IN (5, 13, 14)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_PSM_List_Report] TO [DDL_Viewer] AS [dbo]
GO
