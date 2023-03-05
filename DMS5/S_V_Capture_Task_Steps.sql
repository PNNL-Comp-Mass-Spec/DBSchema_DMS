/****** Object:  Synonym [dbo].[S_V_Capture_Job_Steps] ******/
CREATE SYNONYM [dbo].[S_V_Capture_Job_Steps] FOR [DMS_Capture].[dbo].[V_Task_Steps]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Capture_Job_Steps] TO [DDL_Viewer] AS [dbo]
GO
