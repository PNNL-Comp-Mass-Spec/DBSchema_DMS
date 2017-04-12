/****** Object:  Synonym [dbo].[S_MT_Main_RefreshCachedOrganisms] ******/
CREATE SYNONYM [dbo].[S_MT_Main_RefreshCachedOrganisms] FOR [ProteinSeqs].[MT_Main].[dbo].[RefreshCachedOrganisms]
GO
GRANT VIEW DEFINITION ON [dbo].[S_MT_Main_RefreshCachedOrganisms] TO [DDL_Viewer] AS [dbo]
GO
