/****** Object:  View [dbo].[V_Dataset_Scans_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Scans_Export]
AS
SELECT DS.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       InstName.IN_name AS Instrument,
       DTN.DST_name AS Dataset_Type,
       DST.ScanType AS Scan_Type,
       DST.ScanCount AS Scan_Count,
       DST.ScanFilter AS Scan_Filter,
       DS.Scan_Count AS Scan_Count_Total,
       CONVERT(decimal(9, 2), 
         CASE WHEN ISNULL(DSInfo.Elution_Time_Max, 0) < 1E6 
              THEN DSInfo.Elution_Time_Max
              ELSE 1E6
         END) AS Elution_Time_Max,
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS File_Size_MB,
       DST.Entry_ID Entry_ID
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
