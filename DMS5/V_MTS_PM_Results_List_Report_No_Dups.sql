/****** Object:  View [dbo].[V_MTS_PM_Results_List_Report_No_Dups] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_PM_Results_List_Report_No_Dups]
AS
SELECT dataset,
       job,
       tool_name,
       task_start,
       results_url,
       task_id,
       task_state_id,
       task_finish,
       task_server,
       task_database,
       tool_version,
       output_folder_path,
       mts_job_id,
       instrument,
       amts_1pct_fdr,
       amts_5pct_fdr,
       amts_10pct_fdr,
       amts_25pct_fdr,
       amts_50pct_fdr,
       ppm_shift,
       qid,
       md_id,
       param_file,
       settings_file,
       ini_file_name,
       comparison_mass_tag_count,
       md_state
FROM ( SELECT DS.Dataset_Num AS Dataset,
              AJ.AJ_jobID AS Job,
              PM.Tool_Name,
              PM.Job_Start AS Task_Start,
              PM.Results_URL,
              PM.Task_ID,
              PM.State_ID AS Task_State_ID,
              PM.Job_Finish AS Task_Finish,
              PM.Task_Server,
              PM.Task_Database,
              PM.Tool_Version,
              PM.Output_Folder_Path,
              PM.MTS_Job_ID,
              Inst.IN_name AS Instrument,
              PM.AMT_Count_1pct_FDR AS AMTs_1pct_FDR,
              PM.AMT_Count_5pct_FDR AS AMTs_5pct_FDR,
              PM.AMT_Count_10pct_FDR AS AMTs_10pct_FDR,
              PM.AMT_Count_25pct_FDR AS AMTs_25pct_FDR,
              PM.AMT_Count_50pct_FDR AS AMTs_50pct_FDR,
              PM.Refine_Mass_Cal_PPMShift AS PPM_Shift,
              PM.QID,
              PM.MD_ID,
              AJ.AJ_parmFileName AS Param_File,
              AJ.AJ_settingsFileName AS Settings_File,
              PM.Ini_File_Name,
              PM.Comparison_Mass_Tag_Count,
              PM.MD_State,
              Row_Number() OVER ( PARTITION BY PM.Task_ID, AJ.AJ_jobID ORDER BY IsNull(PM.Job_Start, '') DESC ) AS Finish_Rank
       FROM T_Dataset DS
            INNER JOIN T_Analysis_Job AJ
              ON DS.Dataset_ID = AJ.AJ_datasetID
            INNER JOIN T_Instrument_Name Inst
              ON DS.DS_instrument_name_ID = Inst.Instrument_ID
            INNER JOIN T_MTS_Peak_Matching_Tasks_Cached PM
              ON AJ.AJ_jobID = PM.DMS_Job ) FilterQ
WHERE Finish_Rank = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PM_Results_List_Report_No_Dups] TO [DDL_Viewer] AS [dbo]
GO
