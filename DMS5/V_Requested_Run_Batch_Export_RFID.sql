/****** Object:  View [dbo].[V_Requested_Run_Batch_Export_RFID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Batch_Export_RFID]
AS
SELECT RRB.ID,
       RRB.Batch As Name,
	   T_Users.U_Name AS Owner,
	   RRB.Description,
       RequestedRunStats.Requests,              -- Total requested runs in batch
       RequestedRunStats.Active_Requests,       -- Active requested runs in batch (no dataset yet)
	   RRB.Requested_Instrument AS Inst_Group,
       RRB.Created As Created,
	   HexID
FROM T_Requested_Run_Batches AS RRB
     INNER JOIN T_Users
       ON RRB.Owner = T_Users.ID
     LEFT OUTER JOIN ( SELECT RDS_BatchID AS BatchID,
                              COUNT(*) AS Requests,
                              Sum(Case When RDS_Status = 'Active' Then 1 Else 0 End) As Active_Requests
                       FROM T_Requested_Run AS RR1
                       GROUP BY RDS_BatchID
                     ) AS RequestedRunStats
       ON RequestedRunStats.BatchID = RRB.ID
WHERE RRB.ID > 0


GO
