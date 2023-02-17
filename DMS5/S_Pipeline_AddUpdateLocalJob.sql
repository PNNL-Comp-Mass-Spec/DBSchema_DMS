/****** Object:  Synonym [dbo].[S_Pipeline_AddUpdateLocalJob] ******/
CREATE SYNONYM [dbo].[S_Pipeline_AddUpdateLocalJob] FOR [DMS_Pipeline].[dbo].[add_update_local_job_in_broker]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Pipeline_AddUpdateLocalJob] TO [DDL_Viewer] AS [dbo]
GO
