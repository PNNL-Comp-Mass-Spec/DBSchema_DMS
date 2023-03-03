/****** Object:  View [dbo].[V_Dataset_Scans_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Scans_List_Report]
AS
SELECT DS.Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
       DTN.DST_name AS dataset_type,
       DST.ScanType AS scan_type,
       DST.ScanCount AS scan_count,
       DST.ScanFilter AS scan_filter,
       DS.Scan_Count AS scan_count_total,
       CONVERT(decimal(9, 2),
         CASE WHEN ISNULL(DSInfo.elution_time_max, 0) < 1E6
              THEN DSInfo.elution_time_max
              ELSE 1E6
         END) AS elution_time_max,
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS file_size_mb,
	   DSInfo.ProfileScanCount_MS   AS profile_scan_count_ms,
	   DSInfo.ProfileScanCount_MSn  AS profile_scan_count_msn,
       DSInfo.CentroidScanCount_MS  AS centroid_scan_count_ms,
	   DSInfo.CentroidScanCount_MSn AS centroid_scan_count_msn,
       DST.Entry_ID AS scan_type_entry_id
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Dataset_Info DSInfo
       ON DS.Dataset_ID = DSInfo.Dataset_ID
     INNER JOIN dbo.T_Dataset_ScanTypes DST
       ON DS.Dataset_ID = DST.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Scans_List_Report] TO [DDL_Viewer] AS [dbo]
GO
