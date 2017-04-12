/****** Object:  Synonym [dbo].[S_V_Pipeline_Job_Steps] ******/
CREATE SYNONYM [dbo].[S_V_Pipeline_Job_Steps] FOR [DMS_Pipeline].[dbo].[V_Job_Steps]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Pipeline_Job_Steps] TO [DDL_Viewer] AS [dbo]
GO
