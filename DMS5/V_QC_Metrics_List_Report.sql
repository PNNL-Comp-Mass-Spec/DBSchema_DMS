/****** Object:  View [dbo].[V_QC_Metrics_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_QC_Metrics_List_Report]
AS
SELECT DS.Dataset_Num AS dataset,
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS file_size_mb,
       PM.AMT_Count_10pct_FDR AS amts_10pct_fdr,
       PM.AMT_Count_50pct_FDR AS amts_50pct_fdr,
       PM.Refine_Mass_Cal_PPMShift AS ppm_shift,
       PM.results_url,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '/QC/' + DS.Dataset_Num + '_BPI_MS.png' AS qc_link,
       PM.task_database,
       AJ.AJ_parmFileName AS param_file,
       AJ.AJ_settingsFileName AS settings_file,
       dbo.GetFactorList(RR.ID) AS factors,
       Inst.IN_name AS instrument,
       PM.DMS_Job AS job,
       PM.tool_name,
       DS.Acq_Time_Start AS acquisition_start,
       DS.Acq_Time_End AS acquisition_end,
       DSN.DSS_name AS state,
       DSRating.DRN_name AS rating,
       LC.SC_Column_Number AS lc_column,
       AJ.AJ_created AS created,
       AJ.AJ_start AS started,
       AJ.AJ_finish AS finished,
       PM.ini_file_name,
       PM.md_state
       --DS.Dataset_ID AS id,
       --PM.Job_Start AS task_start,
       --PM.task_id,
       --PM.State_ID AS task_state_id,
       --PM.Job_Finish AS task_finish,
       --PM.task_server,
       --PM.tool_version,
       --PM.output_folder_path,
       --PM.mts_job_id,
       --PM.AMT_Count_1pct_FDR AS amts_1pct_fdr,
       --PM.AMT_Count_5pct_FDR AS amts_5pct_fdr,
       --PM.AMT_Count_25pct_FDR AS amts_25pct_fdr,
       --DTN.DST_name AS dataset_type,
       --DSInfo.Scan_Types AS scan_types,
       --DS.Scan_Count AS scan_count_total,
       --DSInfo.ScanCountMS AS scan_count_ms,
       --DSInfo.ScanCountMSn AS scan_count_msn,
       --CONVERT(decimal(9, 2),
       --  CASE WHEN ISNULL(DSInfo.elution_time_max, 0) < 1E6
       --       THEN DSInfo.elution_time_max
       --       ELSE 1E6
       --  END) AS elution_time_max,
       --DS.Acq_Length_Minutes AS acq_length,
       --DSInfo.tic_max_ms,
       --DSInfo.tic_max_msn,
       --DSInfo.bpi_max_ms,
       --DSInfo.bpi_max_msn,
       --DSInfo.tic_median_ms,
       --DSInfo.tic_median_msn,
       --DSInfo.bpi_median_ms,
       --DSInfo.bpi_median_msn,
       --DS.DS_sec_sep AS separation_type,
       --DS.DS_comment AS comment,
       --DS.DS_created AS created,
       --DSInfo.Last_Affected AS dsinfo_updated
FROM T_Dataset DS
     INNER JOIN T_Analysis_Job AJ
       ON DS.Dataset_ID = AJ.AJ_datasetID
     INNER JOIN T_Instrument_Name Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
     RIGHT OUTER JOIN T_MTS_Peak_Matching_Tasks_Cached PM
       ON AJ.AJ_jobID = PM.DMS_Job
--     INNER JOIN T_Dataset_Info DSInfo
--       ON DS.Dataset_ID = DSInfo.Dataset_ID
     INNER JOIN T_LC_Column LC
       ON DS.DS_LC_column_ID = LC.ID
     INNER JOIN T_DatasetRatingName DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_DatasetStateName DSN
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     LEFT OUTER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
--     INNER JOIN T_DatasetTypeName DTN
--       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN T_Storage_Path SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_QC_Metrics_List_Report] TO [DDL_Viewer] AS [dbo]
GO
