/****** Object:  Synonym [dbo].[S_V_Pipeline_Jobs_Backfill] ******/
CREATE SYNONYM [dbo].[S_V_Pipeline_Jobs_Backfill] FOR [DMS_Pipeline].[dbo].[V_Pipeline_Jobs_Backfill]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Pipeline_Jobs_Backfill] TO [DDL_Viewer] AS [dbo]
GO
