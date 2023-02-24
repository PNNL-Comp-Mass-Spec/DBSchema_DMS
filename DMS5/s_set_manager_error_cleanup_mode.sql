/****** Object:  Synonym [dbo].[S_SetManagerErrorCleanupMode] ******/
CREATE SYNONYM [dbo].[S_SetManagerErrorCleanupMode] FOR [ProteinSeqs].[Manager_Control].[set_manager_error_cleanup_mode]
GO
GRANT VIEW DEFINITION ON [dbo].[S_SetManagerErrorCleanupMode] TO [DDL_Viewer] AS [dbo]
GO
