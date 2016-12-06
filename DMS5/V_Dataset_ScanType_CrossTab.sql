/****** Object:  View [dbo].[V_Dataset_ScanType_CrossTab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_ScanType_CrossTab
AS (
SELECT PivotData.Dataset_ID,
       PivotData.Dataset,
       PivotData.ScanCountTotal,
       IsNull([HMS], 0) AS [HMS],
       IsNull([MS], 0) AS [MS],
       IsNull([CID-HMSn], 0) AS [CID-HMSn],
       IsNull([CID-MSn], 0) AS [CID-MSn],
       IsNull([HCD-HMSn], 0) AS [HCD-HMSn],
       IsNull([ETD-HMSn], 0) AS [ETD-HMSn],
       IsNull([ETD-MSn], 0) AS [ETD-MSn],
       IsNull([SA_ETD-HMSn], 0) AS [SA_ETD-HMSn],
       IsNull([SA_ETD-MSn], 0) AS [SA_ETD-MSn],
       IsNull([HMSn], 0) AS [HMSn],
       IsNull([MSn], 0) AS [MSn],
       IsNull([MRM_Full_NL], 0) AS [MRM_Full_NL],
       IsNull([CID-SRM], 0) AS [CID-SRM],
       IsNull([PQD-HMSn], 0) AS [PQD-HMSn],
       IsNull([PQD-MSn], 0) AS [PQD-MSn],
       IsNull([Q1MS], 0) AS [Q1MS],
       IsNull([Q3MS], 0) AS [Q3MS],
       IsNull([Zoom-MS], 0) AS [Zoom-MS]
FROM ( SELECT DS.Dataset_ID,
              DS.Dataset_Num AS Dataset,
              DS.Scan_Count AS ScanCountTotal,
              DST.ScanType,
              DST.ScanCount
       FROM T_Dataset DS
            INNER JOIN T_Dataset_ScanTypes DST
              ON DS.Dataset_ID = DST.Dataset_ID
     ) AS SourceTable
     PIVOT ( SUM(ScanCount)
             FOR ScanType
             IN ( [HMS], [MS], [Zoom-MS],
                  [CID-HMSn], [CID-MSn], 
                  [HCD-HMSn], 
                  [ETD-HMSn], [SA_ETD-HMSn], 
                  [ETD-MSn],  [SA_ETD-MSn],
                  [HMSn], [MSn],
                  [MRM_Full_NL], [CID-SRM],
                  [PQD-HMSn], [PQD-MSn],
                  [Q1MS], [Q3MS]
                 ) 
           ) AS PivotData

)
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_ScanType_CrossTab] TO [DDL_Viewer] AS [dbo]
GO
