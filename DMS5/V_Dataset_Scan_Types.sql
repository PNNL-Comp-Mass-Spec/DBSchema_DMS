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
       DST.ScanType,
       DST.ScanCount,
       DST.ScanFilter,
       DS.Scan_Count,
       DS.File_Size_Bytes,
       DS.Acq_Length_Minutes,
       DS.Acq_Time_Start,
       DS.DS_created
FROM T_Dataset_ScanTypes DST
     INNER JOIN T_Dataset DS
       ON DST.Dataset_ID = DS.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Scan_Types] TO [DDL_Viewer] AS [dbo]
GO
