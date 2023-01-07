/****** Object:  View [dbo].[V_Dataset_QC_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_QC_List_Report]
AS
SELECT DS.Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '/QC/' + DS.Dataset_Num + '_BPI_MS.png' AS qc_link,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '/QC/' + DS.Dataset_Num + '_HighAbu_LCMS.png' AS qc_2d,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '/' + J.AJ_resultsFolderName + '/' + DS.Dataset_Num + '_HighAbu_LCMS_zoom.png' AS qc_decontools,
       Exp.Experiment_Num AS experiment,
       C.Campaign_Num AS campaign,
       InstName.IN_name AS instrument,
       DS.DS_created AS created,
       DS.DS_comment AS comment,
       DSN.DSS_name AS state,
       DSRating.DRN_name AS rating,
       DS.Acq_Length_Minutes AS acq_length,
       ISNULL(DS.acq_time_start, RR.RDS_Run_Start) AS acq_start,
       ISNULL(DS.acq_time_end, RR.RDS_Run_Finish) AS acq_end,
       DTN.DST_name AS dataset_type,
       DS.DS_Oper_PRN AS operator,
       LC.SC_Column_Number AS lc_column,
       RR.ID AS request,
       RR.RDS_BatchID AS batch,
       DS.DS_sec_sep AS separation_type
FROM T_DatasetStateName AS DSN
     INNER JOIN T_Dataset AS DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName AS DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_Experiments AS Exp
       ON DS.Exp_ID = Exp.Exp_ID
     INNER JOIN T_Campaign AS C
       ON Exp.EX_campaign_ID = C.Campaign_ID
     INNER JOIN t_storage_path AS SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
     INNER JOIN T_LC_Column AS LC
       ON DS.DS_LC_column_ID = LC.ID
     LEFT OUTER JOIN T_Requested_Run AS RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER Join T_Analysis_Job As J
       ON DS.DeconTools_Job_for_QC = J.AJ_jobID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_List_Report] TO [DDL_Viewer] AS [dbo]
GO
