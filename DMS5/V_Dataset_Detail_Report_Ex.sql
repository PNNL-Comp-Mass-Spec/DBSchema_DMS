/****** Object:  View [dbo].[V_Dataset_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Detail_Report_Ex]
AS
-- Note: this view is intended to be used for retrieving information for a single dataset
-- Performance will be poor if used to query multiple datasets because it references several scalar-valued functions
-- For changes, see https://github.com/PNNL-Comp-Mass-Spec/DBSchema_DMS/commit/e843c6bb52
SELECT DS.Dataset_Num AS dataset,
       E.Experiment_Num AS experiment,
       OG.OG_name AS organism,
       BTO.Tissue AS experiment_tissue,
       TIN.IN_name AS instrument,
       DS.DS_sec_sep AS separation_type,
       LCCart.Cart_Name AS lc_cart,
       CartConfig.Cart_Config_Name AS lc_cart_config,
       LCCol.SC_Column_Number AS lc_column,
       DS.DS_wellplate_num AS wellplate,
       DS.DS_well_num AS well,
       DST.DST_Name AS type,
       U.Name_with_PRN AS operator,
       DS.DS_comment AS comment,
       TDRN.DRN_name AS rating,
       TDSN.DSS_name AS state,
       DS.Dataset_ID AS id,
       DS.DS_created AS created,
       RR.ID AS request,
       RR.RDS_BatchID AS batch,
       DL.dataset_folder_path,
       DL.archive_folder_path,
       DL.myemsl_url,
       dbo.get_myemsl_transaction_id_urls(DS.Dataset_ID) AS myemsl_upload_ids,
       DFP.Dataset_URL AS data_folder_link,
       DL.QC_Link AS qc_link,
       DL.QC_2D AS qc_2d,
       CASE
         WHEN IsNull(DL.masic_directory_name, '') = '' THEN ''
         ELSE DFP.Dataset_URL + MASIC_Directory_Name
       END AS masic_qc_link,
       DL.QC_Metric_Stats AS qc_metric_stats,
       COALESCE(CDS.job_count, 0) AS jobs,
       COALESCE(CDS.psm_job_count, 0) AS psm_jobs,
       dbo.get_dataset_pm_task_count(DS.Dataset_ID) AS peak_matching_results,
       dbo.get_dataset_factor_count(DS.Dataset_ID) AS factors,
       dbo.get_dataset_predefine_job_count (DS.Dataset_ID) AS predefines_triggered,
       DS.Acq_Time_Start AS acquisition_start,
       DS.Acq_Time_End AS acquisition_end,
       RR.RDS_Run_Start AS run_start,
       RR.RDS_Run_Finish AS run_finish,
       DS.Scan_Count AS scan_count,
       dbo.get_dataset_scan_type_list(DS.Dataset_ID) AS scan_types,
       DS.Acq_Length_Minutes AS acq_length,
       CONVERT(int, DS.File_Size_Bytes / 1024.0 / 1024.0) AS file_size_mb,
       DS.File_Info_Last_Modified AS file_info_updated,
       DF.File_Path AS dataset_file,
       DF.File_Hash AS sha1_hash,
       DS.DS_folder_name AS folder_name,
       DS.Capture_Subfolder AS capture_subfolder,
       TDASN.archive_state,
       DA.AS_state_Last_Affected AS archive_state_last_affected,
       AUSN.AUS_name AS archive_update_state,
       DA.AS_update_state_Last_Affected AS archive_update_state_last_affected,
       RR.RDS_WorkPackage AS work_package,
       CASE WHEN RR.RDS_WorkPackage IN ('none', '') THEN ''
            ELSE ISNULL(CC.activation_state_name, 'Invalid')
            END AS work_package_state,
       EUT.Name AS eus_usage_type,
       RR.RDS_EUS_Proposal_ID AS eus_proposal,
       EPT.Proposal_Type_Name AS eus_proposal_type,
       dbo.get_requested_run_eus_users_list(RR.id, 'V') AS eus_user,
       TIS_1.Name AS predigest_int_std,
       TIS_2.Name AS postdigest_int_std,
       T_MyEMSLState.StateName AS myemsl_state
FROM S_V_BTO_ID_to_Name AS BTO
     RIGHT OUTER JOIN T_Dataset AS DS
                      INNER JOIN T_Dataset_State_Name AS TDSN
                        ON DS.DS_state_ID = TDSN.Dataset_state_ID
                      INNER JOIN T_Instrument_Name AS TIN
                        ON DS.DS_instrument_name_ID = TIN.Instrument_ID
                      INNER JOIN T_Dataset_Type_Name AS DST
                        ON DS.DS_type_ID = DST.DST_Type_ID
                      INNER JOIN T_Experiments AS E
                        ON DS.Exp_ID = E.Exp_ID
                      INNER JOIN T_Users AS U
                        ON DS.DS_Oper_PRN = U.U_PRN
                      INNER JOIN T_Dataset_Rating_Name AS TDRN
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
     LEFT OUTER JOIN t_cached_dataset_stats CDS
       ON CDS.Dataset_ID = ds.Dataset_ID
     LEFT OUTER JOIN T_Dataset_Archive AS DA
                     INNER JOIN T_MyEMSLState
                       ON DA.MyEMSLState = T_MyEMSLState.MyEMSLState
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     LEFT OUTER JOIN V_Charge_Code_Status AS CC
       ON RR.RDS_WorkPackage = CC.Charge_Code
     LEFT OUTER JOIN T_Dataset_Archive_State_Name AS TDASN
       ON DA.AS_state_ID = TDASN.archive_state_id
     LEFT OUTER JOIN T_Dataset_Archive_Update_State_Name AS AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
     LEFT OUTER JOIN T_LC_Cart_Configuration AS CartConfig
       ON DS.Cart_Config_ID = CartConfig.Cart_Config_ID
     LEFT OUTER JOIN T_Dataset_Files DF
       ON DF.Dataset_ID = DS.Dataset_ID AND
          DF.File_Size_Rank = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Detail_Report_Ex] TO [DDL_Viewer] AS [dbo]
GO
