/****** Object:  View [dbo].[V_Dataset_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Detail_Report_Ex] AS
-- Note: this view is intended to be used for retrieving information for a single dataset
-- Performance will be poor if used to query multiple datasets because it references several scalar-valued functions
-- For changes, see https://github.com/PNNL-Comp-Mass-Spec/DBSchema_DMS/commit/e843c6bb52
SELECT DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       OG.OG_name AS Organism,
       BTO.Tissue AS [Experiment Tissue],
       TIN.IN_name AS Instrument,
       DS.DS_sec_sep AS [Separation Type],
       LCCart.Cart_Name AS [LC Cart],
       CartConfig.Cart_Config_Name AS [LC Cart Config],
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
       RR.ID AS Request,
       RR.RDS_BatchID AS Batch,
       DL.Dataset_Folder_Path AS [Dataset Folder Path],
       DL.Archive_Folder_Path AS [Archive Folder Path],
       DL.MyEMSL_URL AS [MyEMSL URL],
       dbo.GetMyEMSLTransactionIdURLs(DS.Dataset_ID) As [MyEMSL Upload IDs],    
       DFP.Dataset_URL AS [Data Folder Link],
       DL.QC_Link AS [QC Link],
       DL.QC_2D AS [QC 2D],
       CASE
         WHEN IsNull(DL.MASIC_Directory_Name, '') = '' THEN ''
         ELSE DFP.Dataset_URL + MASIC_Directory_Name
       END AS [MASIC QC Link],
       DL.QC_Metric_Stats AS [QC Metric Stats],
       ISNULL(JobCountQ.Jobs, 0) AS Jobs,
       ISNULL(PSMJobsQ.Jobs, 0) AS [PSM Jobs],
       dbo.GetDatasetPMTaskCount(DS.Dataset_ID) AS [Peak Matching Results],
       dbo.GetDatasetFactorCount(DS.Dataset_ID) AS Factors,
       dbo.GetDatasetPredefineJobCount (DS.Dataset_ID) AS [Predefines Triggered],
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       RR.RDS_Run_Start AS [Run Start],
       RR.RDS_Run_Finish AS [Run Finish],
       DS.Scan_Count AS [Scan Count],
       dbo.GetDatasetScanTypeList(DS.Dataset_ID) AS [Scan Types],
       DS.Acq_Length_Minutes AS [Acq Length],
       CONVERT(int, DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)],
       DS.File_Info_Last_Modified AS [File Info Updated],
       DF.File_Path AS [Dataset File],
       DF.File_Hash AS [SHA1 Hash],
       DS.DS_folder_name AS [Folder Name],
       DS.Capture_Subfolder AS [Capture Subfolder],
       TDASN.DASN_StateName AS [Archive State],
       DA.AS_state_Last_Affected AS [Archive State Last Affected],
       AUSN.AUS_name AS [Archive Update State],
       DA.AS_update_state_Last_Affected AS [Archive Update State Last Affected],
       RR.RDS_WorkPackage [Work Package],
       CASE WHEN RR.RDS_WorkPackage IN ('none', '') THEN ''
            ELSE ISNULL(CC.Activation_State_Name, 'Invalid') 
            END AS [Work Package State],
       EUT.Name AS [EUS Usage Type],
       RR.RDS_EUS_Proposal_ID AS [EUS Proposal],
       EPT.Proposal_Type_Name AS [EUS Proposal Type],
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'V') AS [EUS User],
       TIS_1.Name AS [Predigest Int Std],
       TIS_2.Name AS [Postdigest Int Std],
       T_MyEMSLState.StateName AS [MyEMSL State]
FROM S_V_BTO_ID_to_Name AS BTO
     RIGHT OUTER JOIN T_Dataset AS DS
                      INNER JOIN T_DatasetStateName AS TDSN
                        ON DS.DS_state_ID = TDSN.Dataset_state_ID
                      INNER JOIN T_Instrument_Name AS TIN
                        ON DS.DS_instrument_name_ID = TIN.Instrument_ID
                      INNER JOIN T_DatasetTypeName AS DST
                        ON DS.DS_type_ID = DST.DST_Type_ID
                      INNER JOIN T_Experiments AS E
                        ON DS.Exp_ID = E.Exp_ID
                      INNER JOIN T_Users AS U
                        ON DS.DS_Oper_PRN = U.U_PRN
                      INNER JOIN T_DatasetRatingName AS TDRN
                        ON DS.DS_rating = TDRN.DRN_state_ID
                      INNER JOIN T_LC_Column AS LCCol
                        ON DS.DS_LC_column_ID = LCCol.ID
                      INNER JOIN T_Internal_Standards AS TIS_1
                        ON E.EX_internal_standard_ID = TIS_1.Internal_Std_Mix_ID
                      INNER JOIN T_Internal_Standards AS TIS_2
                        ON E.EX_postdigest_internal_std_ID = TIS_2.Internal_Std_Mix_ID
                      INNER JOIN T_Organisms AS OG
                        ON E.EX_organism_ID = OG.Organism_ID
       ON BTO.Identifier = E.EX_Tissue_ID
     LEFT OUTER JOIN T_Storage_Path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN T_Cached_Dataset_Folder_Paths AS DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     LEFT OUTER JOIN T_Cached_Dataset_Links AS DL
       ON DS.Dataset_ID = DL.Dataset_ID
     LEFT OUTER JOIN V_Dataset_Archive_Path AS DAP
       ON DS.Dataset_ID = DAP.Dataset_ID
     LEFT OUTER JOIN T_LC_Cart AS LCCart
                     INNER JOIN T_Requested_Run AS RR
                       ON LCCart.ID = RR.RDS_Cart_ID
                     LEFT OUTER JOIN T_EUS_Proposals AS EUP
                       ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
                     LEFT OUTER JOIN T_EUS_Proposal_Type AS EPT
                       ON EUP.Proposal_Type = EPT.Proposal_Type
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN ( SELECT AJ_datasetID AS DatasetID,
                              COUNT(*) AS Jobs
                       FROM T_Analysis_Job
                       GROUP BY AJ_datasetID ) AS JobCountQ
       ON JobCountQ.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN ( SELECT J.AJ_datasetID AS DatasetID,
                              COUNT(PSMs.Job) AS Jobs
                       FROM T_Analysis_Job_PSM_Stats AS PSMs
                            INNER JOIN T_Analysis_Job AS J
                              ON PSMs.Job = J.AJ_jobID
                       GROUP BY J.AJ_datasetID ) AS PSMJobsQ
       ON PSMJobsQ.DatasetID = DS.Dataset_ID    
     LEFT OUTER JOIN T_Dataset_Archive AS DA
                     INNER JOIN T_MyEMSLState
                       ON DA.MyEMSLState = T_MyEMSLState.MyEMSLState
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     LEFT OUTER JOIN V_Charge_Code_Status AS CC
       ON RR.RDS_WorkPackage = CC.Charge_Code
     LEFT OUTER JOIN T_DatasetArchiveStateName AS TDASN
       ON DA.AS_state_ID = TDASN.DASN_StateID
     LEFT OUTER JOIN T_Archive_Update_State_Name AS AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
     LEFT OUTER JOIN T_LC_Cart_Configuration AS CartConfig
       ON DS.Cart_Config_ID = CartConfig.Cart_Config_ID
     LEFT OUTER JOIN T_Dataset_Files DF
       ON DF.Dataset_ID = DS.Dataset_ID AND
          DF.File_Size_Rank = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Detail_Report_Ex] TO [DDL_Viewer] AS [dbo]
GO
