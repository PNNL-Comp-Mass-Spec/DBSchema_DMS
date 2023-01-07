/****** Object:  View [dbo].[V_Helper_Dataset_Capture_Job_Steps_Ckbx] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Helper_Dataset_Capture_Job_Steps_Ckbx
AS
SELECT J.dataset, J.job, S.script, JSN.Name AS job_state, J.storage_server, J.instrument, J.start, J.finish
FROM T_Jobs AS J INNER JOIN
                      T_Job_State_Name AS JSN ON J.State = JSN.ID INNER JOIN
                      T_Scripts AS S ON J.Script = S.Script

GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Dataset_Capture_Job_Steps_Ckbx] TO [DDL_Viewer] AS [dbo]
GO
