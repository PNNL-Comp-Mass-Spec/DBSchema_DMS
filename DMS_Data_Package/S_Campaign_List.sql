/****** Object:  Synonym [dbo].[S_Campaign_List] ******/
CREATE SYNONYM [dbo].[S_Campaign_List] FOR [DMS5].[dbo].[T_Campaign]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Campaign_List] TO [DDL_Viewer] AS [dbo]
GO
