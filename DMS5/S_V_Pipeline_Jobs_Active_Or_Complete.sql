/****** Object:  Synonym [dbo].[S_V_Pipeline_Jobs_Active_Or_Complete] ******/
CREATE SYNONYM [dbo].[S_V_Pipeline_Jobs_Active_Or_Complete] FOR [DMS_Pipeline].[dbo].[V_Pipeline_Jobs_Active_Or_Complete]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Pipeline_Jobs_Active_Or_Complete] TO [DDL_Viewer] AS [dbo]
GO
