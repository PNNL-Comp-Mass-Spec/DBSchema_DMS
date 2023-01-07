/****** Object:  View [dbo].[V_Requested_Run_Queue_Times] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Queue_Times]
AS
SELECT requested_run_id,
       requested_run_created,
       requested_run_name,
       rds_origin AS origin,
       batch_id,
       dataset_id,
       dataset_created,
       dataset_acq_time_start,
       CASE
           WHEN Days_From_Requested_Run_Create_To_Dataset_Acquired IS NULL THEN
                CASE WHEN RDS_Status = 'Active'
                     THEN DATEDIFF(DAY, Requested_Run_Created, GETDATE())
                     ELSE NULL
                END
           WHEN Days_From_Requested_Run_Create_To_Dataset_Acquired <= 0 Then
                CASE WHEN RDS_Origin = 'Auto'
                     THEN NULL
                     ELSE Days_From_Requested_Run_Create_To_Dataset_Acquired
                END
           ELSE Days_From_Requested_Run_Create_To_Dataset_Acquired
       END As days_in_queue
FROM ( SELECT RR.ID AS Requested_Run_ID,
              RR.RDS_created AS Requested_Run_Created,
              RR.RDS_Name AS Requested_Run_Name,
              RR.RDS_BatchID AS Batch_ID,
              RR.RDS_Status,
              RR.RDS_Origin,
              DS.Dataset_ID,
              DS.DS_created AS Dataset_Created,
              DS.Acq_Time_Start AS Dataset_Acq_Time_Start,
              DATEDIFF(DAY, RR.RDS_created, ISNULL(DS.Acq_Time_Start, DS.DS_created)) AS
                Days_From_Requested_Run_Create_To_Dataset_Acquired
       FROM T_Requested_Run RR
            LEFT OUTER JOIN T_Dataset DS
              ON RR.DatasetID = DS.Dataset_ID
      ) DataQ


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Queue_Times] TO [DDL_Viewer] AS [dbo]
GO
