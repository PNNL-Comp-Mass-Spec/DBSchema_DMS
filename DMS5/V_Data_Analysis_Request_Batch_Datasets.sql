/****** Object:  View [dbo].[V_Data_Analysis_Request_Batch_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_Batch_Datasets]
AS
SELECT R.ID AS [Request ID],
       DS.Dataset_ID AS [Dataset ID],
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       InstName.IN_name AS Instrument,
       DFP.Dataset_Folder_Path AS [Dataset Folder Path],
       DS.Acq_Time_Start AS [Acq Start],
       BatchIDs.Batch_ID AS [Batch ID],
       R.Campaign,
       R.Organism,
       R.Request_Name AS [Request Name],
       R.Analysis_Type AS [Analysis Type]
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
