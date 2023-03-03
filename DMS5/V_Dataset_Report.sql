/****** Object:  View [dbo].[V_Dataset_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Note that this view is used by page families helper_dataset and helper_dataset_ckbx

CREATE VIEW [dbo].[V_Dataset_Report]
AS
SELECT DS.Dataset_Num AS dataset,
       DS.Dataset_ID AS id,
       DSN.DSS_name AS state,
       DSR.DRN_name AS rating,
       InstName.IN_name AS instrument,
       DS.DS_created AS created,
       DS.DS_comment AS comment,
       DS.DateSortKey AS acq_start,           -- Use DateSortKey here for speed, since it is indexed (and updated via a trigger); in contrast, the dataset list report and detail report use "ISNULL(DS.acq_time_start, RR.RDS_Run_Start) AS Acq_Start"
       DS.Acq_Length_Minutes AS acq_length,
       DTN.DST_Name AS dataset_type,
       E.Experiment_Num AS experiment,
	   C.Campaign_Num AS campaign,
       RR.ID AS request,
	   RR.RDS_BatchID AS batch,
       ISNULL(SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.ds_folder_name, DS.Dataset_Num), '') AS dataset_folder_path
FROM dbo.T_Dataset_State_Name AS DSN
     INNER JOIN dbo.T_Dataset AS DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN dbo.T_Dataset_Type_Name AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Dataset_Rating_Name AS DSR
       ON DS.DS_rating = DSR.DRN_state_ID
     INNER JOIN dbo.T_Experiments AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.t_storage_path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     LEFT OUTER JOIN dbo.T_Requested_Run AS RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path AS DAP
       ON DS.Dataset_ID = DAP.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Report] TO [DDL_Viewer] AS [dbo]
GO
