/****** Object:  View [dbo].[V_Dataset_Scans_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Scans_Detail_Report]
AS
SELECT DS.Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
       DTN.DST_name AS dataset_type,
       DSInfo.Scan_Types AS scan_types,
       DS.Scan_Count AS scan_count_total,
	   DSInfo.ProfileScanCount_MS   AS profile_scan_count_ms,
	   DSInfo.ProfileScanCount_MSn  AS profile_scan_count_msn,
       DSInfo.CentroidScanCount_MS  AS centroid_scan_count_ms,
	   DSInfo.CentroidScanCount_MSn AS centroid_scan_count_msn,
       DSInfo.Scan_Count_DIA        AS scan_count_dia,
       SUM(CASE WHEN DST.ScanType = 'MS'                             THEN DST.ScanCount ELSE 0 END) AS scan_count_ms,
       SUM(CASE WHEN DST.ScanType = 'HMS'                            THEN DST.ScanCount ELSE 0 END) AS scan_count_hms,
       SUM(CASE WHEN DST.ScanType = 'Zoom-MS'                        THEN DST.ScanCount ELSE 0 END) AS scan_count_zoom_ms,
       SUM(CASE WHEN DST.ScanType = 'CID-MSn'                        THEN DST.ScanCount ELSE 0 END) AS scan_count_cid_msn,
       SUM(CASE WHEN DST.ScanType = 'CID-HMSn'                       THEN DST.ScanCount ELSE 0 END) AS scan_count_cid_hmsn,
       SUM(CASE WHEN DST.ScanType = 'HMSn'                           THEN DST.ScanCount ELSE 0 END) AS scan_count_hmsn,
       SUM(CASE WHEN DST.ScanType In ('HCD-HMSn', 'DIA-HCD-HMSn')    THEN DST.ScanCount ELSE 0 END) AS scan_count_hcd_hmsn,
       SUM(CASE WHEN DST.ScanType = 'ETD-MSn'                        THEN DST.ScanCount ELSE 0 END) AS scan_count_etd_msn,
       SUM(CASE WHEN DST.ScanType = 'ETD-HMSn'                       THEN DST.ScanCount ELSE 0 END) AS scan_count_etd_hmsn,
       SUM(CASE WHEN DST.ScanType = 'SA_ETD-MSn'                     THEN DST.ScanCount ELSE 0 END) AS scan_count_sa_etd_msn,
       SUM(CASE WHEN DST.ScanType = 'SA_ETD-HMSn'                    THEN DST.ScanCount ELSE 0 END) AS scan_count_sa_etd_hmsn,
       SUM(CASE WHEN DST.ScanType = 'Q1MS'                           THEN DST.ScanCount ELSE 0 END) AS scan_count_q1ms,
       SUM(CASE WHEN DST.ScanType = 'Q3MS'                           THEN DST.ScanCount ELSE 0 END) AS scan_count_q3ms,
       SUM(CASE WHEN DST.ScanType = 'CID-SRM'                        THEN DST.ScanCount ELSE 0 END) AS scan_count_cid_srm,
       SUM(CASE WHEN NOT DST.ScanType IN ('MS',
                                          'HMS'         ,
                                          'Zoom-MS'     ,
                                          'CID-MSn'     ,
                                          'CID-HMSn'    ,
                                          'HMSn'        ,
                                          'HCD-HMSn'    ,
                                          'DIA-HCD-HMSn',
                                          'ETD-MSn'     ,
                                          'ETD-HMSn'    ,
                                          'SA_ETD-MSn'  ,
                                          'SA_ETD-HMSn' ,
                                          'Q1MS'        ,
                                          'Q3MS'        ,
                                          'CID-SRM'
                                         )  THEN DST.ScanCount ELSE 0 END) AS scan_count_other,
       CONVERT(decimal(9, 2),
         CASE WHEN ISNULL(DSInfo.elution_time_max, 0) < 1E6
              THEN DSInfo.elution_time_max
              ELSE 1E6
         END) AS elution_time_max,
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS file_size_mb
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Dataset_Info DSInfo
       ON DS.Dataset_ID = DSInfo.Dataset_ID
     INNER JOIN dbo.T_Dataset_ScanTypes DST
       ON DS.Dataset_ID = DST.Dataset_ID
GROUP BY DS.Dataset_ID, DS.Dataset_Num, InstName.IN_name, DTN.DST_name,
         DS.Scan_Count, DSInfo.Elution_Time_Max,DS.File_Size_Bytes,
         DSInfo.Scan_Types,
		 DSInfo.ProfileScanCount_MS, DSInfo.ProfileScanCount_MSn,
		 DSInfo.CentroidScanCount_MS, DSInfo.CentroidScanCount_MSn,
         DSInfo.Scan_Count_DIA

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Scans_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
