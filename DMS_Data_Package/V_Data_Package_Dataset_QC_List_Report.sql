/****** Object:  View [dbo].[V_Data_Package_Dataset_QC_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Dataset_QC_List_Report]
AS
SELECT DPD.Data_Pkg_ID AS data_pkg_id,
       DPD.dataset_id,
       DS.Dataset_Num AS dataset,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name,DS.Dataset_Num) + '/QC/' + DS.Dataset_Num + '_BPI_MS.png' AS qc_link,
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
FROM dbo.T_Data_Package_Datasets AS DPD
     INNER JOIN dbo.S_Dataset AS DS
       ON DPD.Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.S_Dataset_State_Name AS DSN
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN dbo.S_Dataset_Type_Name AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.S_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.S_Dataset_Rating_Name AS DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN dbo.S_Experiments AS Exp
       ON DS.Exp_ID = Exp.Exp_ID
     INNER JOIN dbo.S_Campaign_List AS C
       ON Exp.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.S_Storage_Path AS SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
     INNER JOIN dbo.S_LC_Column AS LC
       ON DS.DS_LC_column_ID = LC.ID
     LEFT OUTER JOIN dbo.S_Requested_Run AS RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER Join dbo.S_Analysis_Job As J
       ON DS.DeconTools_Job_for_QC = J.AJ_jobID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Dataset_QC_List_Report] TO [DDL_Viewer] AS [dbo]
GO
