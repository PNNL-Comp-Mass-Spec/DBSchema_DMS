/****** Object:  View [dbo].[V_Requested_Run_Batch_Export_RFID_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Requested_Run_Batch_Export_RFID_Recent]
AS
SELECT RRB.ID,
       RRB.Batch As Name,
       U.U_Name AS Owner,
       RRB.Description,
       RequestedRunStats.Requests,              -- Total requested runs in batch
       RequestedRunStats.Active_Requests,       -- Active requested runs in batch (no dataset yet)
       RBS.Instrument_Group_First AS Inst_Group,
       RRB.Created As Created,
       RFID_Hex_ID As Hex_ID
FROM T_Requested_Run_Batches AS RRB
     INNER JOIN T_Users AS U
       ON RRB.Owner = U.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              COUNT(*) AS Requests,
                              Sum(Case When RDS_Status = 'Active' Then 1 Else 0 End) As Active_Requests
                       FROM T_Requested_Run AS RR
                       GROUP BY RDS_BatchID
                     ) AS RequestedRunStats
       ON RequestedRunStats.BatchID = RRB.ID
     LEFT OUTER JOIN T_Cached_Requested_Run_Batch_Stats RBS
       ON RBS.Batch_ID = RRB.ID
WHERE RRB.ID > 0 AND RRB.Created >= DATEADD(month, -2, GETDATE())

GO
