/****** Object:  Synonym [dbo].[s_pipeline_add_update_local_job] ******/
CREATE SYNONYM [dbo].[s_pipeline_add_update_local_job] FOR [DMS_Pipeline].[dbo].[add_update_local_job_in_broker]
GO
GRANT VIEW DEFINITION ON [dbo].[s_pipeline_add_update_local_job] TO [DDL_Viewer] AS [dbo]
GO
