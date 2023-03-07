/****** Object:  View [dbo].[V_Table_Row_Counts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Table_Row_Counts]
AS
SELECT s.Name As schema_name,
       o.name AS table_name, 
       i.rowcnt AS table_row_count
FROM sys.objects o 
     INNER JOIN dbo.sysindexes i 
       ON o.object_id = i.id 
     INNER JOIN sys.schemas s 
       ON s.schema_id = o.schema_id
WHERE o.type = 'u' AND 
      i.indid < 2 AND 
      o.name <> 'dtproperties'

GO
GRANT VIEW DEFINITION ON [dbo].[V_Table_Row_Counts] TO [DDL_Viewer] AS [dbo]
GO
