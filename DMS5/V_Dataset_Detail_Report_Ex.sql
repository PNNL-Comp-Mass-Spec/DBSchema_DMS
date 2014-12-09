/****** Object:  View [dbo].[V_Dataset_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Dataset_Detail_Report_Ex] as
SELECT DS.Dataset_Num AS Dataset,
       TE.Experiment_Num AS Experiment,
       OG.OG_name AS Organism,
       TIN.IN_name AS Instrument,
       DS.DS_sec_sep AS [Separation Type],
       LCCart.Cart_Name AS [LC Cart],
       LCCol.SC_Column_Number AS [LC Column],
       DS.DS_wellplate_num AS [Wellplate Number],
       DS.DS_well_num AS [Well Number],
       DST.DST_Name AS [Type],
       U.Name_with_PRN AS Operator,
       DS.DS_comment AS [Comment],
       TDRN.DRN_name AS Rating,
       TDSN.DSS_name AS State,
       DS.Dataset_ID AS ID,
       DS.DS_created AS Created,
       RRH.ID AS Request,
       CASE
           WHEN DA.AS_state_ID = 4 THEN 'Purged: ' + DFP.Dataset_Folder_Path
           ELSE CASE
                    WHEN DA.AS_instrument_data_purged > 0 THEN 'Raw Data Purged: ' + DFP.Dataset_Folder_Path
                    ELSE DFP.Dataset_Folder_Path
                END
       END AS [Dataset Folder Path],
       CASE
           WHEN DA.MyEMSLState > 0 And DS.DS_created >= '9/17/2013' Then ''
           ELSE DFP.Archive_Folder_Path
       END AS [Archive Folder Path],
       dbo.GetMyEMSLUrlDatasetName(Dataset_Num) AS [MyEMSL URL],
       DFP.Dataset_URL AS [Data Folder Link],
       CASE
           WHEN DA.QC_Data_Purged > 0 THEN ''
           ELSE DFP.Dataset_URL + 'QC/index.html'
       END AS [QC Link],
	   CASE
           WHEN DA.QC_Data_Purged > 0 THEN ''
           ELSE DFP.Dataset_URL + J.AJ_resultsFolderName + '/'
       END AS [QC 2D],
       CASE
           WHEN Experiment_Num LIKE 'QC[_]Shew%' THEN 
                'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/' + IN_Name + '/filterDS/QC_Shew'
           ELSE 'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/MS2_Count/inst/' + IN_Name + '/filterDS/' + SUBSTRING(DS.Dataset_Num, 1, 4)
       END AS 'QC Metric Stats',
       ISNULL(JobCountQ.Jobs, 0) AS Jobs,
       ISNULL(PMTaskCountQ.PMTasks, 0) AS [Peak Matching Results],
       ISNULL(FC.Factor_Count, 0) AS Factors,
       ISNULL(PredefinedJobQ.JobCount, 0) AS [Predefines Triggered],
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       RRH.RDS_Run_Start AS [Run Start],
       RRH.RDS_Run_Finish AS [Run Finish],
       DS.Scan_Count AS [Scan Count],
       DSTypes.ScanTypeList AS [Scan Types],
       DS.Acq_Length_Minutes AS [Acq Length],
       --DATEDIFF(minute, ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start), ISNULL(DS.Acq_Time_End, RRH.RDS_Run_Finish)) AS [Acq Length],
       CONVERT(int, DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)],
       DS.File_Info_Last_Modified AS [File Info Updated],
       DS.DS_folder_name AS [Folder Name],
       TDASN.DASN_StateName AS [Archive State],
       DA.AS_state_Last_Affected AS [Archive State Last Affected],
       AUSN.AUS_name AS [Archive Update State],
       DA.AS_update_state_Last_Affected AS [Archive Update State Last Affected],
       TIS_1.Name AS [Predigest Int Std],
       TIS_2.Name AS [Postdigest Int Std],
       T_MyEMSLState.StateName AS [MyEMSL State]
FROM dbo.t_storage_path AS SPath
     RIGHT OUTER JOIN dbo.T_Dataset AS DS
                      INNER JOIN dbo.T_DatasetStateName AS TDSN
                        ON DS.DS_state_ID = TDSN.Dataset_state_ID
                      INNER JOIN dbo.T_Instrument_Name AS TIN
                        ON DS.DS_instrument_name_ID = TIN.Instrument_ID
                      INNER JOIN dbo.T_DatasetTypeName AS DST
                        ON DS.DS_type_ID = DST.DST_Type_ID
                      INNER JOIN dbo.T_Experiments AS TE
                        ON DS.Exp_ID = TE.Exp_ID
                      INNER JOIN dbo.T_Users AS U
                        ON DS.DS_Oper_PRN = U.U_PRN
                      INNER JOIN dbo.T_DatasetRatingName AS TDRN
                        ON DS.DS_rating = TDRN.DRN_state_ID
                      INNER JOIN dbo.T_LC_Column AS LCCol
                        ON DS.DS_LC_column_ID = LCCol.ID
                      INNER JOIN dbo.T_Internal_Standards AS TIS_1
                        ON TE.EX_internal_standard_ID = TIS_1.Internal_Std_Mix_ID
                      INNER JOIN dbo.T_Internal_Standards AS TIS_2
                        ON TE.EX_postdigest_internal_std_ID = TIS_2.Internal_Std_Mix_ID
                      INNER JOIN dbo.T_Organisms AS OG
                        ON TE.EX_organism_ID = OG.Organism_ID
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
     INNER JOIN V_Dataset_Folder_Paths AS DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path AS DAP
       ON DS.Dataset_ID = DAP.Dataset_ID
     LEFT OUTER JOIN dbo.T_LC_Cart AS LCCart
                     INNER JOIN dbo.T_Requested_Run AS RRH
                       ON LCCart.ID = RRH.RDS_Cart_ID
       ON DS.Dataset_ID = RRH.DatasetID
     LEFT OUTER JOIN ( SELECT AJ_datasetID AS DatasetID,
                              COUNT(*) AS Jobs
                       FROM dbo.T_Analysis_Job
                       GROUP BY AJ_datasetID ) AS JobCountQ
       ON JobCountQ.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_Dataset_Archive AS DA 
         INNER JOIN T_MyEMSLState
             ON DA.MyEMSLState = T_MyEMSLState.MyEMSLState
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_DatasetArchiveStateName AS TDASN
       ON DA.AS_state_ID = TDASN.DASN_StateID
     LEFT OUTER JOIN dbo.T_Archive_Update_State_Name AS AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
     LEFT OUTER JOIN ( SELECT AJ.AJ_datasetID AS DatasetID,
                              COUNT(*) AS PMTasks
                       FROM dbo.T_Analysis_Job AS AJ
                            INNER JOIN dbo.T_MTS_Peak_Matching_Tasks_Cached AS PM
                              ON AJ.AJ_jobID = PM.DMS_Job
                       GROUP BY AJ.AJ_datasetID ) AS PMTaskCountQ
       ON PMTaskCountQ.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.V_Factor_Count_By_Dataset AS FC
       ON FC.Dataset_ID = DS.Dataset_ID
     Left Outer Join dbo.T_Analysis_Job J
	   On DS.DeconTools_Job_for_QC = J.AJ_JobID
     LEFT OUTER JOIN ( SELECT Dataset_ID,
                              SUM(jobs_created) AS JobCount
                       FROM T_Predefined_Analysis_Scheduling_Queue
                       GROUP BY Dataset_ID ) PredefinedJobQ
       ON PredefinedJobQ.Dataset_ID = DS.Dataset_ID
     CROSS APPLY GetDatasetScanTypeList ( DS.Dataset_ID ) DSTypes



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Detail_Report_Ex] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Detail_Report_Ex] TO [PNL\D3M580] AS [dbo]
GO
