/****** Object:  View [dbo].[V_Capture_Job_Steps_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Job_Steps_List_Report]
AS
SELECT JS.job,
       JS.Step AS step,
       S.script,
       JS.Tool AS tool,
       SSN.Name AS step_state,
       JSN.Name AS job_state_b,
       JS.Retry_Count AS retry,
       J.dataset,
       JS.processor,
       JS.start,
       JS.finish,
       CONVERT(decimal(9, 2), DATEDIFF(SECOND, JS.Start, ISNULL(JS.Finish, GETDATE())) / 60.0) AS runtime_minutes,
       JS.state,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.cpu_load,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       JS.Job_Plus_Step AS id,
       J.storage_server,
	   J.instrument
FROM dbo.T_Task_Steps AS JS
     INNER JOIN dbo.T_Task_Step_State_Name AS SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Tasks AS J
       ON JS.Job = J.Job
     INNER JOIN dbo.T_Task_State_Name AS JSN
       ON J.State = JSN.ID
     INNER JOIN dbo.T_Scripts AS S
       ON J.Script = S.Script

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Job_Steps_List_Report] TO [DDL_Viewer] AS [dbo]
GO
