/****** Object:  View [dbo].[V_Dataset_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Export]
AS
SELECT DS.Dataset_Num AS dataset,
       E.Experiment_Num AS experiment,
       Org.OG_name AS organism,
       Inst.IN_name AS instrument,
       DS.DS_sec_sep AS separation_type,
       LC.SC_Column_Number AS lc_column,
       DS.DS_wellplate_num AS wellplate,
       DS.DS_well_num AS well,
       DSIntStd.Name AS dataset_int_std,
       DTN.DST_name AS type,
       U.Name_with_PRN AS operator,
       DS.DS_comment AS comment,
       DRN.DRN_name AS rating,
       RR.ID AS request,
       DSN.DSS_name AS state,
       DS.DS_created AS created,
       DS.DS_folder_name AS folder_name,
	   DFPCache.Dataset_Folder_Path As dataset_folder_path,
       SPath.SP_path AS storage_path,
       SPath.SP_vol_name_client + SPath.SP_path AS storage,
       DS.Dataset_ID AS id,
       DS.Acq_Time_Start AS acquisition_start,
       DS.Acq_Time_End AS acquisition_end,
       DS.Scan_Count AS scan_count,
       PreDigest.Name AS predigest_int_std,
       PostDigest.Name AS postdigest_int_std,
       DS.File_Size_Bytes / 1024.0 / 1024.0 AS file_size_mb,
       ISNULL(DA.AS_instrument_data_purged, 0) AS instrument_data_purged,	   
       DFPCache.Archive_Folder_Path As archive_folder_path,
	   IsNull(DA.MyEMSLState, 0) As myemsl_state,
       -- The following are old column names, included for compatibility with the DMS Dataset Retriever
       DS.DS_sec_sep AS [Separation Type],
       LC.SC_Column_Number AS [LC Column],
       DS.DS_wellplate_num AS [Wellplate Number],
       DS.DS_well_num AS [Well Number],
       DSIntStd.Name AS [Dataset Int Std],
       DS.DS_folder_name AS [Folder Name],
	   DFPCache.Dataset_Folder_Path As [Dataset Folder Path],
       SPath.SP_path AS [Storage Folder],
       DS.DS_Comp_State AS [Compressed State],
       DS.DS_Compress_Date AS [Compressed Date],
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       DS.Scan_Count AS [Scan Count],
       PreDigest.Name AS [PreDigest Int Std],
       PostDigest.Name AS [PostDigest Int Std],
       DS.File_Size_Bytes / 1024.0 / 1024.0 AS [File Size MB],
       DFPCache.Archive_Folder_Path As [Archive Folder Path],
	   IsNull(DA.MyEMSLState, 0) As MyEMSLState
FROM T_Dataset DS
     INNER JOIN T_DatasetStateName DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN T_Instrument_Name Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_Users U
       ON DS.DS_Oper_PRN = U.U_PRN
     INNER JOIN T_DatasetRatingName DRN
       ON DS.DS_rating = DRN.DRN_state_ID
     INNER JOIN T_LC_Column LC
       ON DS.DS_LC_column_ID = LC.ID
     INNER JOIN T_Internal_Standards DSIntStd
       ON DS.DS_internal_standard_ID = DSIntStd.Internal_Std_Mix_ID
     INNER JOIN T_Internal_Standards PreDigest
       ON E.EX_internal_standard_ID = PreDigest.Internal_Std_Mix_ID
     INNER JOIN T_Internal_Standards PostDigest
       ON E.EX_postdigest_internal_std_ID = PostDigest.Internal_Std_Mix_ID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
	 INNER JOIN T_Cached_Dataset_Folder_Paths DFPCache
       ON DS.Dataset_ID = DFPCache.Dataset_ID
     LEFT OUTER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN dbo.T_Dataset_Archive DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
WHERE Experiment_Num <> 'Tracking'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Export] TO [DDL_Viewer] AS [dbo]
GO
