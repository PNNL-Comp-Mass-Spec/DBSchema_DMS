/****** Object:  Synonym [dbo].[S_Mgr_Params] ******/
CREATE SYNONYM [dbo].[S_Mgr_Params] FOR [ProteinSeqs].[Manager_Control].[dbo].[V_MgrParams]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Mgr_Params] TO [DDL_Viewer] AS [dbo]
GO
