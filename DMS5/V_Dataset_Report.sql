/****** Object:  View [dbo].[V_Dataset_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Note that this view is used by page families helper_dataset and helper_dataset_ckbx

CREATE VIEW [dbo].[V_Dataset_Report]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID AS ID,
       DSN.DSS_name AS State,
       DSR.DRN_name AS Rating,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DS.DS_comment AS [Comment],
       DS.DateSortKey AS Acq_Start,           -- Use DateSortKey here for speed, since it is indexed (and updated via a trigger); in contrast, the dataset list report and detail report use "ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start) AS Acq_Start"	   
       DS.Acq_Length_Minutes AS Acq_Length,
       DTN.DST_Name AS Dataset_Type,
       E.Experiment_Num AS Experiment,
	   C.Campaign_Num AS Campaign,
       RR.ID AS Request,
	   RR.RDS_BatchID AS Batch,
       ISNULL(SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num), '') AS Dataset_Folder_Path
FROM dbo.T_DatasetStateName AS DSN
     INNER JOIN dbo.T_Dataset AS DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN dbo.T_DatasetTypeName AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_DatasetRatingName AS DSR
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
