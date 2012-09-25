/****** Object:  View [dbo].[V_Dataset_Scans_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Scans_Detail_Report]
AS
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       InstName.IN_name AS Instrument,
       DTN.DST_name AS [Dataset Type],
       DSInfo.Scan_Types as [Scan Types],
       DS.Scan_Count AS [Scan Count Total],
       SUM(CASE WHEN DST.ScanType = 'MS'          THEN DST.ScanCount ELSE 0 END) AS [ScanCount MS],
       SUM(CASE WHEN DST.ScanType = 'HMS'         THEN DST.ScanCount ELSE 0 END) AS [ScanCount HMS],
       SUM(CASE WHEN DST.ScanType = 'Zoom-MS'     THEN DST.ScanCount ELSE 0 END) AS [ScanCount Zoom-MS],
       SUM(CASE WHEN DST.ScanType = 'CID-MSn'     THEN DST.ScanCount ELSE 0 END) AS [ScanCount CID-MSn],
       SUM(CASE WHEN DST.ScanType = 'CID-HMSn'    THEN DST.ScanCount ELSE 0 END) AS [ScanCount CID-HMSn],
       SUM(CASE WHEN DST.ScanType = 'HMSn'        THEN DST.ScanCount ELSE 0 END) AS [ScanCount HMSn],
       SUM(CASE WHEN DST.ScanType = 'HCD-HMSn'    THEN DST.ScanCount ELSE 0 END) AS [ScanCount HCD-HMSn],
       SUM(CASE WHEN DST.ScanType = 'ETD-MSn'     THEN DST.ScanCount ELSE 0 END) AS [ScanCount ETD-MSn],
       SUM(CASE WHEN DST.ScanType = 'ETD-HMSn'    THEN DST.ScanCount ELSE 0 END) AS [ScanCount ETD-HMSn],
       SUM(CASE WHEN DST.ScanType = 'SA_ETD-MSn'  THEN DST.ScanCount ELSE 0 END) AS [ScanCount SA_ETD-MSn],
       SUM(CASE WHEN DST.ScanType = 'SA_ETD-HMSn' THEN DST.ScanCount ELSE 0 END) AS [ScanCount SA_ETD-HMSn],
       SUM(CASE WHEN DST.ScanType = 'Q1MS'        THEN DST.ScanCount ELSE 0 END) AS [ScanCount Q1MS],
       SUM(CASE WHEN DST.ScanType = 'Q3MS'        THEN DST.ScanCount ELSE 0 END) AS [ScanCount Q3MS],
       SUM(CASE WHEN DST.ScanType = 'CID-SRM'     THEN DST.ScanCount ELSE 0 END) AS [ScanCount CID-SRM],
       SUM(CASE WHEN NOT DST.ScanType IN ('MS',
                                          'HMS'         , 
                                          'Zoom-MS'     ,
                                          'CID-MSn'     , 
                                          'CID-HMSn'    , 
                                          'HMSn'        , 
                                          'HCD-HMSn'    , 
                                          'ETD-MSn'     , 
                                          'ETD-HMSn'    , 
                                          'SA_ETD-MSn'  , 
                                          'SA_ETD-HMSn' , 
                                          'Q1MS'        , 
                                          'Q3MS'        , 
                                          'CID-SRM'
                                         )        THEN DST.ScanCount ELSE 0 END) AS [ScanCount Other],
       CONVERT(decimal(9, 2), 
         CASE WHEN ISNULL(DSInfo.Elution_Time_Max, 0) < 1E6 
              THEN DSInfo.Elution_Time_Max
              ELSE 1E6
         END) AS [Elution Time Max],
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)]
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Dataset_Info DSInfo
       ON DS.Dataset_ID = DSInfo.Dataset_ID
     INNER JOIN dbo.T_Dataset_ScanTypes DST
       ON DS.Dataset_ID = DST.Dataset_ID
GROUP BY DS.Dataset_ID, DS.Dataset_Num, InstName.IN_name, DTN.DST_name, 
         DS.Scan_Count, DSInfo.Elution_Time_Max,DS.File_Size_Bytes,
         DSInfo.Scan_Types



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Scans_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Scans_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
