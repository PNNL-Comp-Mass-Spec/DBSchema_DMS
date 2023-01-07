/****** Object:  View [dbo].[V_MTS_PM_Results_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_PM_Results_List_Report]
AS
SELECT PM.DMS_Job AS job,
       DS.Dataset_Num AS dataset,
       PM.tool_name,
       PM.Job_Start AS task_start,
       PM.results_url,
       PM.task_id,
       PM.State_ID AS task_state_id,
       PM.Job_Finish AS task_finish,
       PM.task_server,
       PM.task_database,
       PM.tool_version,
       PM.output_folder_path,
       PM.mts_job_id,
       Inst.IN_name AS instrument,
       PM.AMT_Count_1pct_FDR AS amts_1pct_fdr,
       PM.AMT_Count_5pct_FDR AS amts_5pct_fdr,
       PM.AMT_Count_10pct_FDR AS amts_10pct_fdr,
       PM.AMT_Count_25pct_FDR AS amts_25pct_fdr,
       PM.AMT_Count_50pct_FDR AS amts_50pct_fdr,
       Refine_Mass_Cal_PPMShift AS ppm_shift,
       PM.qid,
       PM.md_id,
       AJ.AJ_parmFileName AS param_file,
       AJ.AJ_settingsFileName AS settings_file,
       PM.ini_file_name,
       PM.comparison_mass_tag_count,
       PM.md_state,
       DS.dataset_id,
       DS.Acq_Length_Minutes AS acq_length,
       DS.acq_time_start
FROM T_Dataset DS
     INNER JOIN T_Analysis_Job AJ
       ON DS.Dataset_ID = AJ.AJ_datasetID
     INNER JOIN T_Instrument_Name Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
     RIGHT OUTER JOIN T_MTS_Peak_Matching_Tasks_Cached PM
       ON AJ.AJ_jobID = PM.DMS_Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PM_Results_List_Report] TO [DDL_Viewer] AS [dbo]
GO
