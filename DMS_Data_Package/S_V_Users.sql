/****** Object:  Synonym [dbo].[S_V_Users] ******/
CREATE SYNONYM [dbo].[S_V_Users] FOR [DMS5].[dbo].[V_Users]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Users] TO [DDL_Viewer] AS [dbo]
GO
