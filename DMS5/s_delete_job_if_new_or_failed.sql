/****** Object:  Synonym [dbo].[s_delete_job_if_new_or_failed] ******/
CREATE SYNONYM [dbo].[s_delete_job_if_new_or_failed] FOR [DMS_Pipeline].[dbo].[delete_job_if_new_or_failed]
GO
GRANT VIEW DEFINITION ON [dbo].[s_delete_job_if_new_or_failed] TO [DDL_Viewer] AS [dbo]
GO
