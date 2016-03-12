/****** Object:  View [dbo].[V_Requested_Run_Queue_Times] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Queue_Times]
AS
SELECT RequestedRun_ID,
       RequestedRun_Created,
       RequestedRun_Name,
       RDS_Origin,
       BatchID,
       Dataset_ID,
       Dataset_Created,
       Dataset_AcqTimeStart,
       CASE
           WHEN [Days From Requested Run Create To Dataset Acquired] IS NULL THEN 
				CASE WHEN RDS_Status = 'Active' 
				     THEN DATEDIFF(DAY, RequestedRun_Created, GETDATE())
				     ELSE NULL
				END
		   WHEN [Days From Requested Run Create To Dataset Acquired] <= 0 Then
		        CASE WHEN RDS_Origin = 'Auto'
		             THEN NULL
		             ELSE [Days From Requested Run Create To Dataset Acquired]
		        END
           ELSE [Days From Requested Run Create To Dataset Acquired]
       END AS [Days In Queue]
FROM ( SELECT RR.ID AS RequestedRun_ID,
              RR.RDS_created AS RequestedRun_Created,
              RR.RDS_Name AS RequestedRun_Name,
              RR.RDS_BatchID AS BatchID,
              RR.RDS_Status,
              RR.RDS_Origin,
              DS.Dataset_ID,
              DS.DS_created AS Dataset_Created,
              DS.Acq_Time_Start AS Dataset_AcqTimeStart,
              DATEDIFF(DAY, RR.RDS_created, ISNULL(DS.Acq_Time_Start, DS.DS_created)) AS 
                [Days From Requested Run Create To Dataset Acquired]
       FROM T_Requested_Run RR
            LEFT OUTER JOIN T_Dataset DS
              ON RR.DatasetID = DS.Dataset_ID
      ) DataQ


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Queue_Times] TO [PNL\D3M578] AS [dbo]
GO
