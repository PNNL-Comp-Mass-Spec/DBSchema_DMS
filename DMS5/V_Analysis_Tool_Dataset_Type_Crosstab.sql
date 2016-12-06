/****** Object:  View [dbo].[V_Analysis_Tool_Dataset_Type_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Tool_Dataset_Type_Crosstab]
AS
SELECT PivotData.ToolName,
       IsNull([MS], 0) AS [MS],
       IsNull([HMS], 0) AS [HMS],
       IsNull([MS-MSn], 0) AS [MS-MSn],
       IsNull([MS-ETD-MSn], 0) AS [MS-ETD-MSn],
       IsNull([MS-CID/ETD-MSn], 0) AS [MS-CID/ETD-MSn],
       IsNull([HMS-MSn], 0) AS [HMS-MSn],
       IsNull([HMS-HMSn], 0) AS [HMS-HMSn],
       IsNull([HMS-ETD-MSn], 0) AS [HMS-ETD-MSn],
       IsNull([HMS-CID/ETD-MSn], 0) AS [HMS-CID/ETD-MSn],
       IsNull([HMS-HCD-MSn], 0) AS [HMS-HCD-MSn],
       IsNull([HMS-HCD-CID/ETD-MSn], 0) AS [HMS-HCD-CID/ETD-MSn],
       IsNull([HMS-HCD-ETD-MSn], 0) AS [HMS-HCD-ETD-MSn],
       IsNull([HMS-PQD-CID/ETD-MSn], 0) AS [HMS-PQD-CID/ETD-MSn],
       IsNull([HMS-PQD-ETD-MSn], 0) AS [HMS-PQD-ETD-MSn],
       IsNull([HMS-HCD-CID/ETD-HMSn], 0) AS [HMS-HCD-CID/ETD-HMSn],
       IsNull([IMS-HMS], 0) AS [IMS-HMS],
       IsNull([IMS-MSn-HMS], 0) AS [IMS-MSn-HMS],
       IsNull([MRM], 0) AS [MRM],
       IsNull([GC-MS], 0) AS [GC-MS],
       IsNull([GC-SIM], 0) AS [GC-SIM]
FROM ( SELECT AnTool.AJT_toolName AS ToolName,
              ADT.Dataset_Type,
              1 AS Valid
       FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
            INNER JOIN T_Analysis_Tool AnTool
              ON ADT.Analysis_Tool_ID = AnTool.AJT_toolID ) AS SourceTable
     PIVOT ( SUM(Valid)
             FOR Dataset_Type
             IN ( [HMS], [MS-MSn], [HMS-MSn], [MS], [HMS-HMSn], [IMS-HMS], [IMS-MSn-HMS], 
             [MS-ETD-MSn], [MRM], [MS-CID/ETD-MSn], [HMS-ETD-MSn], [HMS-CID/ETD-MSn], [HMS-HCD-MSn], 
             [HMS-HCD-CID/ETD-MSn], [HMS-HCD-ETD-MSn], [HMS-PQD-CID/ETD-MSn], [HMS-PQD-ETD-MSn], 
             [GC-MS], [GC-SIM], [HMS-HCD-CID/ETD-HMSn] ) ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Dataset_Type_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
