/****** Object:  Synonym [dbo].[S_Production_Pipeline_Job_Steps_History] ******/
CREATE SYNONYM [dbo].[S_Production_Pipeline_Job_Steps_History] FOR [DMS_Pipeline].[dbo].[T_Job_Steps_History]
GO
GRANT VIEW DEFINITION ON [dbo].[S_Production_Pipeline_Job_Steps_History] TO [DDL_Viewer] AS [dbo]
GO
