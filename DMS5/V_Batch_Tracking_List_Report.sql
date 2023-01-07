/****** Object:  View [dbo].[V_Batch_Tracking_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Batch_Tracking_List_Report
AS
SELECT T_Requested_Run_Batches.ID AS batch, T_Requested_Run_Batches.Batch AS name, T_Requested_Run.RDS_Status AS status,
       T_Requested_Run.ID AS request, T_Dataset.dataset_id, T_Dataset.Dataset_Num AS dataset, T_Instrument_Name.IN_name AS instrument,
       T_LC_Column.SC_Column_Number AS lc_column, T_Dataset.Acq_Time_Start AS start, T_Requested_Run.RDS_Block AS block,
       T_Requested_Run.RDS_Run_Order AS run_order
FROM T_LC_Column INNER JOIN
     T_Dataset ON T_LC_Column.ID = T_Dataset.DS_LC_column_ID INNER JOIN
     T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID RIGHT OUTER JOIN
     T_Requested_Run_Batches INNER JOIN
     T_Requested_Run ON T_Requested_Run_Batches.ID = T_Requested_Run.RDS_BatchID ON T_Dataset.Dataset_ID = T_Requested_Run.DatasetID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Batch_Tracking_List_Report] TO [DDL_Viewer] AS [dbo]
GO
