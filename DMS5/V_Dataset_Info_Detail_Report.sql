/****** Object:  View [dbo].[V_Dataset_Info_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Info_Detail_Report]
AS
SELECT DS.Dataset_Num AS dataset,
       TE.Experiment_Num AS experiment,
       OG.OG_name AS organism,
       InstName.IN_name AS instrument,
       DTN.DST_name AS dataset_type,
       DSInfo.Scan_Types AS scan_types,
       DS.Scan_Count AS scan_count_total,
       DSInfo.ScanCountMS AS scan_count_ms,
       DSInfo.ScanCountMSn AS scan_count_msn,
       CONVERT(decimal(9, 2),
         CASE WHEN ISNULL(DSInfo.elution_time_max, 0) < 1E6
              THEN DSInfo.elution_time_max
              ELSE 1E6
         END) AS elution_time_max,
       DS.Acq_Length_Minutes AS acq_length,
       --DATEDIFF(MINUTE, ISNULL(DS.acq_time_start, RR.RDS_Run_Start), ISNULL(DS.acq_time_end, RR.RDS_Run_Finish)) AS acq_length,
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS file_size_mb,
       CONVERT(varchar(32), DSInfo.TIC_Max_MS) AS tic_max_ms,
       CONVERT(varchar(32), DSInfo.TIC_Max_MSn) AS tic_max_msn,
       CONVERT(varchar(32), DSInfo.BPI_Max_MS) AS bpi_max_ms,
       CONVERT(varchar(32), DSInfo.BPI_Max_MSn) AS bpi_max_msn,
       CONVERT(varchar(32), DSInfo.TIC_Median_MS) AS tic_median_ms,
       CONVERT(varchar(32), DSInfo.TIC_Median_MSn) AS tic_median_msn,
       CONVERT(varchar(32), DSInfo.BPI_Median_MS) AS bpi_median_ms,
       CONVERT(varchar(32), DSInfo.BPI_Median_MSn) AS bpi_median_msn,
       DS.DS_sec_sep AS separation_type,
       LCCart.Cart_Name AS lc_cart,
       LC.SC_Column_Number AS lc_column,
       DS.DS_wellplate_num AS wellplate,
       DS.DS_well_num AS well,
       U.Name_with_PRN AS operator,
       DS.Acq_Time_Start AS acquisition_start,
       DS.Acq_Time_End AS acquisition_end,
       RR.RDS_Run_Start AS run_start,
       RR.RDS_Run_Finish AS run_finish,
       DSN.DSS_name AS state,
       DSRating.DRN_name AS rating,
       DS.DS_comment AS comment,
       DS.DS_created AS created,
       DS.Dataset_ID AS id,
       CASE
           WHEN DS.DS_state_ID IN (3, 4) AND
                ISNULL(DSA.as_state_id, 0) <> 4 THEN SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.ds_folder_name, DS.Dataset_Num)
           ELSE '(not available)'
       END AS dataset_folder_path,
       CASE
           WHEN ISNULL(DSA.as_state_id, 0) IN (3, 4, 10, 14, 15) THEN DAP.Archive_Path + '\' + ISNULL(DS.ds_folder_name, DS.Dataset_Num)
           ELSE '(not available)'
       END AS archive_folder_path,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '/' AS data_folder_link,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '/QC/index.html' AS qc_link,
       DSInfo.Last_Affected AS dsinfo_updated
FROM T_DatasetStateName DSN
     INNER JOIN T_Dataset DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_LC_Column LC
       ON DS.DS_LC_column_ID = LC.ID
     INNER JOIN T_Dataset_Info DSInfo
       ON DS.Dataset_ID = DSInfo.Dataset_ID
     INNER JOIN dbo.T_Experiments TE
       ON DS.Exp_ID = TE.Exp_ID
     INNER JOIN dbo.T_Organisms OG
       ON TE.EX_organism_ID = OG.Organism_ID
     INNER JOIN dbo.T_Users U
       ON DS.DS_Oper_PRN = U.U_PRN
     LEFT OUTER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN T_Storage_Path SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
     LEFT OUTER JOIN dbo.T_LC_Cart LCCart
       ON LCCart.ID = RR.RDS_Cart_ID
     LEFT OUTER JOIN dbo.T_Dataset_Archive DSA
       ON DSA.AS_Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path DAP
       ON DS.Dataset_ID = DAP.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Info_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
