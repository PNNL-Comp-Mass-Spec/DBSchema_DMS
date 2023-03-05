/****** Object:  View [dbo].[V_Capture_Jobs_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Jobs_Detail_Report]
AS
SELECT J.job,
       J.priority,
       J.script,
       JSN.Name AS job_state_b,
       'Steps' AS steps,
       J.dataset,
       J.Dataset_ID AS dataset_id,
       J.results_folder_name,
       J.imported,
       J.finish,
       J.storage_server,
       J.instrument,
       J.instrument_class,
       J.max_simultaneous_captures,
       J.comment,
	   J.capture_subfolder,
       dbo.get_job_param_list(J.Job) AS parameters
FROM dbo.T_Tasks AS J
     INNER JOIN dbo.T_Task_State_Name AS JSN
       ON J.State = JSN.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Jobs_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
