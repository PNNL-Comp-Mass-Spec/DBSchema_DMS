/****** Object:  View [dbo].[V_Table_Size_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Table_Size_Summary]
AS
WITH Table_Space_Summary (schema_name, table_name, space_used_mb, space_reserved_mb, table_row_count, table_size_bytes, index_count)
As (
    SELECT schema_name, 
           table_name, 
           SUM(space_used_mb) As space_used_mb, 
           SUM(space_reserved_mb) As space_reserved_mb, 
           MAX(table_row_count) As table_row_count,
           Max(table_size_bytes) As table_size_bytes,
           COUNT(*) As index_count
    FROM dbo.V_Table_Index_Sizes
    GROUP BY schema_name, table_name
)
SELECT S.schema_name, 
       S.table_name,
       S.table_row_count, 
       S.space_used_mb,
       S.table_size_bytes As size_bytes,
       S.index_count,
       ROUND(S.space_used_mb / CONVERT(real, TotalsQ.total_used_mb) * 100, 2) AS percent_total_used_mb, 
       S.space_reserved_mb,
       ROUND(S.Space_Reserved_MB / CONVERT(real, TotalsQ.total_reserved_mb) * 100, 2) AS percent_total_reserved_mb, 
       ROUND(S.Table_Row_Count / CONVERT(real, TotalsQ.total_rows) * 100, 2) AS percent_total_rows
FROM Table_Space_Summary S CROSS JOIN
     (SELECT SUM(Space_Used_MB) AS total_used_mb,
             SUM(Space_Reserved_MB) AS total_reserved_mb,
             SUM(Table_Row_Count) AS total_rows
      FROM Table_Space_Summary) TotalsQ

GO
