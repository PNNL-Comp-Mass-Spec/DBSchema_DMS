/****** Object:  View [dbo].[V_Table_Index_Sizes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Table_Index_Sizes]
AS
WITH Table_Index_Space_Usage
( schema_name, table_name, index_name, index_row_count, table_row_count, space_used_kb, space_reserved_kb, fill_factor, is_disabled )
AS (
    SELECT s.Name As schema_name,
           o.Name As table_name,
           COALESCE (i.Name, 'HEAP') As index_name,
           CASE WHEN i.index_id IN ( 0, 1 ) THEN p.row_count ELSE 0 End As index_row_count,
           p.row_count As Table_Row_Count,
           p.used_page_count * 8 As Space_Used_KB,
           p.reserved_page_count * 8 As Space_Reserved_KB,
           i.fill_factor,
           i.is_disabled
    FROM sys.dm_db_partition_stats p
         INNER JOIN sys.objects o ON o.object_id = p.object_id
         INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
         LEFT OUTER JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id
    WHERE o.type_desc = 'USER_TABLE' AND o.is_ms_shipped = 0
), Table_Space_Usage (schema_name, table_name, table_size_bytes)
As (
    SELECT TableQ.schema_name,
           TableQ.table_name,
           Cast(TableQ.table_size As Bigint) * spt.low AS table_size_bytes
    FROM master.dbo.spt_values spt
         CROSS JOIN ( SELECT s.name AS Schema_Name,
                             so.name AS table_name,
                             SUM(si.reserved) AS table_size
                      FROM sys.objects so
                           INNER JOIN sysindexes si
                             ON so.object_id = si.id
                           INNER JOIN sys.schemas s
                             ON s.schema_id = so.schema_id
                      WHERE si.indid IN (0, 1, 255) AND
                            so.TYPE = 'U'
                      GROUP BY s.name, so.name ) TableQ
    WHERE (spt.number = 1) AND
          (spt.type = 'E'))
SELECT IndexQ.schema_name, 
       IndexQ.table_name, 
       IndexQ.index_name,
       SUM(IndexQ.Index_Row_Count) AS index_row_count,
       SUM(IndexQ.Table_Row_Count) AS table_row_count,
       SUM(IndexQ.space_used_kb) / 1024.0 AS space_used_mb,
       SUM(IndexQ.space_reserved_kb) / 1024.0 AS space_reserved_mb,
       fill_factor,
       is_disabled,
       SUM(Cast(space_used_kb As Bigint) * 1024) As index_size_bytes,
       TableQ.table_size_bytes
FROM Table_Index_Space_Usage As IndexQ
     Left Outer Join Table_Space_Usage As TableQ
     On IndexQ.Schema_Name = TableQ.Schema_Name And IndexQ.table_name = TableQ.table_name
GROUP BY IndexQ.Schema_Name, IndexQ.Table_Name, IndexQ.Index_Name, IndexQ.fill_factor, IndexQ.is_disabled, TableQ.table_size_bytes


GO
GRANT VIEW DEFINITION ON [dbo].[V_Table_Index_Sizes] TO [DDL_Viewer] AS [dbo]
GO
