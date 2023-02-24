/****** Object:  Synonym [dbo].[s_mt_main_refresh_cached_organisms] ******/
CREATE SYNONYM [dbo].[s_mt_main_refresh_cached_organisms] FOR [ProteinSeqs].[MT_Main].[dbo].[RefreshCachedOrganisms]
GO
GRANT VIEW DEFINITION ON [dbo].[s_mt_main_refresh_cached_organisms] TO [DDL_Viewer] AS [dbo]
GO
