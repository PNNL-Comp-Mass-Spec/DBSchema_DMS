/****** Object:  Synonym [dbo].[S_MTS_PT_DBs] ******/
CREATE SYNONYM [dbo].[S_MTS_PT_DBs] FOR [Pogo].[MTS_Master].[dbo].[V_PT_DBs]
GO
GRANT VIEW DEFINITION ON [dbo].[S_MTS_PT_DBs] TO [DDL_Viewer] AS [dbo]
GO
