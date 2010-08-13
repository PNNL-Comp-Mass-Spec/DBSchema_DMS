/****** Object:  View [dbo].[V_Dataset_Scans_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_Scans_List_Report]
AS
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       InstName.IN_name AS Instrument,
       DTN.DST_name AS [Dataset Type],
       DST.ScanType AS [Scan Type],
       DST.ScanCount AS [Scan Count],
       DST.ScanFilter AS [Scan Filter],
       DS.Scan_Count AS [Scan Count Total],
       CONVERT(decimal(9,2), DSInfo.Elution_Time_Max) AS [Elution Time Max],
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)],
       DST.Entry_ID AS [ScanType Entry ID]
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Dataset_Info DSInfo
       ON DS.Dataset_ID = DSInfo.Dataset_ID
     INNER JOIN dbo.T_Dataset_ScanTypes DST
       ON DS.Dataset_ID = DST.Dataset_ID



GO
