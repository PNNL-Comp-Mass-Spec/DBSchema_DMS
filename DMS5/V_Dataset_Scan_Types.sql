/****** Object:  View [dbo].[V_Dataset_Scan_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Scan_Types]
AS
SELECT DST.Entry_ID,
       DST.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DST.ScanType AS Scan_Type,
       DST.ScanCount AS Scan_Count,
       DST.ScanFilter AS Scan_Filter,
       DS.Scan_Count AS Scan_Count_Total,
       DS.File_Size_Bytes,
       DS.Acq_Length_Minutes,
       DS.Acq_Time_Start,
       DS.DS_created AS Created
FROM T_Dataset_ScanTypes DST
     INNER JOIN T_Dataset DS
       ON DST.Dataset_ID = DS.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Scan_Types] TO [DDL_Viewer] AS [dbo]
GO
