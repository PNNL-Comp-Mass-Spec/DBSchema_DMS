/****** Object:  View [dbo].[V_Pipeline_Job_Steps_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Pipeline_Job_Steps_History_List_Report]
AS
SELECT JS.job,
       JS.Step AS step,
       J.script,
       JS.Tool AS tool,
	   SSN.Name AS step_state,
	   JSN.Name AS job_state_b,
       J.dataset,
       JS.start,
       JS.finish,
       Convert(decimal(9,2), DATEDIFF(second, JS.start, IsNull(JS.finish, GetDate())) / 60.0) AS runtime_minutes,
       JS.processor,
       JS.state,
		CASE WHEN JS.State = 5 THEN 100
		     ELSE 0
		END AS job_progress,
		CASE WHEN JS.State = 5 THEN Convert(decimal(9,2), DATEDIFF(second, JS.start, IsNull(JS.finish, GetDate())) / 60.0 / 60.0)
			 ELSE 0
		END AS runtime_predicted_hours,
	   0 AS last_cpu_status_minutes,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.signature,
       0 AS cpu_load,
	   0 AS actual_cpu_load,
       memory_usage_mb,
       JS.tool_version_id,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       JobStepSavedCombo AS id
FROM dbo.T_Job_Steps_History AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
     INNER JOIN (	SELECT Job, Dataset, Script, State, Priority
					FROM T_Jobs_History
					WHERE Most_Recent_Entry = 1
				 ) AS J
       ON JS.Job = J.Job
     INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID
WHERE Most_Recent_Entry = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_History_List_Report] TO [DDL_Viewer] AS [dbo]
GO
