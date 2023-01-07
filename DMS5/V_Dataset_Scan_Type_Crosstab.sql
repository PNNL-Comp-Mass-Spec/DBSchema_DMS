/****** Object:  View [dbo].[V_Dataset_Scan_Type_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Scan_Type_Crosstab]
AS
SELECT PivotData.dataset_id,
       PivotData.dataset,
       PivotData.scan_count_total,
       IsNull([HMS], 0) AS [HMS],
       IsNull([MS], 0) AS [MS],
       IsNull([CID-HMSn], 0) AS [CID-HMSn],
       IsNull([CID-MSn], 0) AS [CID-MSn],
       IsNull([SA_CID-HMSn], 0) AS [SA_CID-HMSn],
       IsNull([HCD-HMSn], 0) AS [HCD-HMSn],
       IsNull([HCD-MSn], 0) AS [HCD-MSn],
       IsNull([SA_HCD-HMSn], 0) AS [SA_HCD-HMSn],
       IsNull([EThcD-HMSn], 0) AS [EThcD-HMSn],
       IsNull([ETD-HMSn], 0) AS [ETD-HMSn],
       IsNull([SA_ETD-HMSn], 0) AS [SA_ETD-HMSn],
       IsNull([ETD-MSn], 0) AS [ETD-MSn],
       IsNull([SA_ETD-MSn], 0) AS [SA_ETD-MSn],
       IsNull([HMSn], 0) AS [HMSn],
       IsNull([MSn], 0) AS [MSn],
       IsNull([GC-MS], 0) AS [GC-MS],
       -- IsNull([MRM_Full_NL], 0) AS [MRM_Full_NL],    -- Only used once (in 2009)
       IsNull([SRM], 0) AS [SRM],
       IsNull([CID-SRM], 0) AS [CID-SRM],
       IsNull([MALDI-HMS], 0) AS [MALDI-HMS],
       IsNull([PTR-HMSn], 0) AS [PTR-HMSn],
       IsNull([PTR-MSn], 0) AS [PTR-MSn],
       IsNull([PQD-HMSn], 0) AS [PQD-HMSn],             -- Last used in 2020
       IsNull([PQD-MSn], 0) AS [PQD-MSn],               -- Last used in 2009
       IsNull([Q1MS], 0) AS [Q1MS],
       IsNull([Q3MS], 0) AS [Q3MS],
       IsNull([SIM ms], 0) AS [SIM ms],
       IsNull([UVPD-HMSn], 0) AS [UVPD-HMSn],
       IsNull([UVPD-MSn], 0) AS [UVPD-MSn],
       IsNull([Zoom-MS], 0) AS [Zoom-MS]                -- Last used in 2015
FROM ( SELECT DS.Dataset_ID,
              DS.Dataset_Num AS Dataset,
              DS.Scan_Count AS Scan_Count_Total,
              DST.ScanType,
              DST.ScanCount
       FROM T_Dataset DS
            INNER JOIN T_Dataset_ScanTypes DST
              ON DS.Dataset_ID = DST.Dataset_ID
     ) AS SourceTable
     PIVOT ( SUM(ScanCount)
             FOR ScanType
             IN ( [HMS], [MS],
                  [CID-HMSn], [CID-MSn], [SA_CID-HMSn],
                  [HCD-HMSn], [HCD-MSn], [SA_HCD-HMSn],
                  [EThcD-HMSn],
                  [ETD-HMSn], [SA_ETD-HMSn],
                  [ETD-MSn], [SA_ETD-MSn],
                  [HMSn], [MSn],
                  [GC-MS],
                  [SRM], [CID-SRM],
                  [MALDI-HMS],
                  [PTR-HMSn], [PTR-MSn],
                  [PQD-HMSn], [PQD-MSn],
                  [Q1MS], [Q3MS],
                  [SIM ms],
                  [UVPD-HMSn], [UVPD-MSn],
                  [Zoom-MS]
                 )
           ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Scan_Type_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
