/****** Object:  View [dbo].[V_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset]
AS
SELECT DS.dataset_id,
       DS.dataset_num AS dataset,
       DS.ds_comment,
       DS.ds_created,
       DS.ds_state_id,
       DSN.DSS_name AS state,
       DS.ds_rating,
       DSRating.DRN_name AS rating,
       DS.ds_last_affected,
       DS.ds_instrument_name_id,
       InstName.IN_name AS instrument,
       DS.ds_oper_prn AS operator_username,
       DS.ds_type_id,
       DTN.DST_name AS dataset_type,
       DS.ds_sec_sep,
       DS.ds_folder_name,
       DS.ds_storage_path_id,
       DFP.dataset_folder_path,
	   DFP.Dataset_URL + 'QC/index.html' AS qc_link,
       DS.exp_id,
       Exp.Experiment_Num AS experiment,
       C.Campaign_Num AS campaign,
       DS.ds_internal_standard_id,
       DS.acq_time_start,
       DS.acq_time_end,
       DS.acq_length_minutes,
	   DS.ds_lc_column_id,
       DS.scan_count,
       DS.file_size_bytes,
       DS.file_info_last_modified,
       DS.dataset_num,
	   DS.DateSortKey AS date_sort_key
FROM T_Dataset_State_Name DSN
     INNER JOIN T_Dataset DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Dataset_Rating_Name DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_Experiments Exp
       ON DS.Exp_ID = Exp.Exp_ID
     INNER JOIN T_Campaign C
       ON Exp.EX_campaign_ID = C.Campaign_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset] TO [DDL_Viewer] AS [dbo]
GO
