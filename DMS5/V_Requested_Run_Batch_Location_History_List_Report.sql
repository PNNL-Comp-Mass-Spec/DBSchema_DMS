/****** Object:  View [dbo].[V_Requested_Run_Batch_Location_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Requested_Run_Batch_Location_History_List_Report]
AS
SELECT H.batch_id AS batch_id,
       RRB.Batch AS batch_name,
       U.U_Name AS batch_owner,
       RRB.Created AS batch_created,
       F.Freezer AS freezer,
       H.first_scan_date,
       H.last_scan_date,
       CASE
           WHEN H.last_scan_date IS NULL THEN 0
           ELSE DATEDIFF(day, H.first_scan_date, H.last_scan_date)
       END AS days_in_freezer
FROM T_Requested_Run_Batch_Location_History H
     INNER JOIN T_Material_Locations ML
       ON ML.ID = H.location_id 
     INNER JOIN T_Requested_Run_Batches RRB
       ON H.batch_id = RRB.ID
     INNER JOIN T_Material_Freezers F
       ON ML.Freezer_Tag = F.Freezer_Tag
     INNER JOIN T_Users U
       ON RRB.Owner = U.ID

GO
