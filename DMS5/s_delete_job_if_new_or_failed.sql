/****** Object:  Synonym [dbo].[S_DeleteJobIfNewOrFailed] ******/
CREATE SYNONYM [dbo].[S_DeleteJobIfNewOrFailed] FOR [DMS_Pipeline].[dbo].[delete_job_if_new_or_failed]
GO
GRANT VIEW DEFINITION ON [dbo].[S_DeleteJobIfNewOrFailed] TO [DDL_Viewer] AS [dbo]
GO
