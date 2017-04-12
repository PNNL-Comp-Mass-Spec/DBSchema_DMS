/****** Object:  Synonym [dbo].[S_MTS_MT_DBs] ******/
CREATE SYNONYM [dbo].[S_MTS_MT_DBs] FOR [Pogo].[MTS_Master].[dbo].[V_MT_DBs]
GO
GRANT VIEW DEFINITION ON [dbo].[S_MTS_MT_DBs] TO [DDL_Viewer] AS [dbo]
GO
