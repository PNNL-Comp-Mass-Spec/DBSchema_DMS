/****** Object:  View [dbo].[V_QC_Metrics_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_QC_Metrics_List_Report]
AS
SELECT DS.Dataset_Num AS Dataset,
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size MB],
       PM.AMT_Count_10pct_FDR AS [AMTs 10pct FDR],
       PM.AMT_Count_50pct_FDR AS [AMTs 50pct FDR],
       PM.Results_URL,
       SPath.SP_URL + DS.Dataset_Num + '/QC/' + DS.Dataset_Num + '_BPI_MS.png'  AS [QC Link],
       PM.Task_Database,
       AJ.AJ_parmFileName AS [Parm File],
       AJ.AJ_settingsFileName AS Settings_File,
       dbo.GetFactorList(RR.ID) AS Factors, 
       Inst.IN_name AS Instrument,
       PM.DMS_Job AS Job,
       PM.Tool_Name,
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       DSN.DSS_name AS State,
       DSRating.DRN_name AS Rating,
       LC.SC_Column_Number AS [LC Column],
       AJ.AJ_created AS Created,
       AJ.AJ_start AS Started,
       AJ.AJ_finish AS Finished,
       PM.Ini_File_Name
       --DS.Dataset_ID AS ID,
       --PM.Job_Start AS Task_Start,
       --PM.Task_ID,
       --PM.State_ID AS Task_State_ID,
       --PM.Job_Finish AS Task_Finish,
       --PM.Task_Server,
       --PM.Tool_Version,
       --PM.Output_Folder_Path,
       --PM.MTS_Job_ID,
       --PM.AMT_Count_1pct_FDR AS [AMTs 1pct FDR],
       --PM.AMT_Count_5pct_FDR AS [AMTs 5pct FDR],
       --PM.AMT_Count_25pct_FDR AS [AMTs 25pct FDR],
       --DTN.DST_name AS [Dataset Type],
       --DSInfo.Scan_Types AS [Scan Types],
       --DS.Scan_Count AS [Scan Count Total],
       --DSInfo.ScanCountMS AS [Scan Count MS],
       --DSInfo.ScanCountMSn AS [Scan Count MSn],
       --CONVERT(decimal(9, 2), 
       --  CASE WHEN ISNULL(DSInfo.Elution_Time_Max, 0) < 1E6 
       --       THEN DSInfo.Elution_Time_Max
       --       ELSE 1E6
       --  END) AS [Elution Time Max],
       --DS.Acq_Length_Minutes AS [Acq Length],
       --DSInfo.TIC_Max_MS,
       --DSInfo.TIC_Max_MSn,
       --DSInfo.BPI_Max_MS,
       --DSInfo.BPI_Max_MSn,
       --DSInfo.TIC_Median_MS,
       --DSInfo.TIC_Median_MSn,
       --DSInfo.BPI_Median_MS,
       --DSInfo.BPI_Median_MSn,
       --DS.DS_sec_sep AS [Separation Type],
       --DS.DS_comment AS [Comment________________],
       --DS.DS_created AS Created,
       --DSInfo.Last_Affected AS [DSInfo Updated]
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
