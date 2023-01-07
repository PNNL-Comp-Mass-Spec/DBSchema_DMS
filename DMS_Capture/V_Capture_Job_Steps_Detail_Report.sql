/****** Object:  View [dbo].[V_Capture_Job_Steps_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Capture_Job_Steps_Detail_Report
AS
SELECT JS.Job_Plus_Step AS id,
       JS.job,
       JS.Step_Number AS step,
       J.dataset,
       S.script,
       JS.Step_Tool AS tool,
       SSN.Name AS step_state,
       JSN.Name AS job_state_b,
       JS.State AS state_id,
       JS.start,
       JS.finish,
       CONVERT(decimal(9, 2), DATEDIFF(SECOND, JS.Start, ISNULL(JS.Finish, GETDATE())) / 60.0) AS runtime_minutes,
       JS.processor,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.cpu_load,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       J.Transfer_Folder_Path AS transfer_folder_path,
       JS.Next_Try AS next_try,
       JS.Retry_Count AS retry_count
FROM dbo.T_Job_Steps AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Jobs AS J
       ON JS.Job = J.Job
     INNER JOIN dbo.T_Job_State_Name AS JSN
       ON J.State = JSN.ID
     INNER JOIN dbo.T_Scripts AS S
       ON J.Script = S.Script


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Job_Steps_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
