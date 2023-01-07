/****** Object:  View [dbo].[V_Data_Analysis_Request_Batch_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_Batch_Datasets]
AS
SELECT R.ID AS request_id,
       DS.Dataset_ID AS dataset_id,
       DS.Dataset_Num AS dataset,
       E.Experiment_Num AS experiment,
       InstName.IN_name AS instrument,
       DFP.Dataset_Folder_Path AS dataset_folder_path,
       DS.Acq_Time_Start AS acq_start,
       BatchIDs.Batch_ID AS batch_id,
       R.campaign,
       R.organism,
       R.Request_Name AS request_name,
       R.Analysis_Type AS analysis_type
FROM T_Dataset AS DS
     INNER JOIN T_Requested_Run AS RR
       ON DS.Dataset_ID = RR.DatasetID
     INNER JOIN T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Experiments AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Cached_Dataset_Folder_Paths AS DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     RIGHT OUTER JOIN T_Data_Analysis_Request AS R
                      INNER JOIN T_Data_Analysis_Request_Batch_IDs AS BatchIDs
                        ON R.ID = BatchIDs.Request_ID
       ON RR.RDS_BatchID = BatchIDs.Batch_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_Batch_Datasets] TO [DDL_Viewer] AS [dbo]
GO
