/****** Object:  View [dbo].[V_Pipeline_Job_Steps_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Pipeline_Job_Steps_Detail_Report]
AS
SELECT JS.Job_Plus_Step AS id,
       JS.job,
       JS.Step AS step,
       J.dataset,
       J.script,
       JS.Tool AS tool,
       SSN.Name AS step_state,
       JSN.Name AS job_state_b,
       JS.State AS state_id,
       JS.start,
       JS.finish,
       CASE WHEN (JS.State = 9 Or JS.Remote_Info_ID > 1) THEN
                Convert(decimal(9,2), DATEDIFF(second, JS.remote_start, ISNULL(JS.remote_finish, GetDate())) / 60.0)
            ELSE
                Convert(decimal(9,2), DATEDIFF(second, JS.start, IsNull(JS.finish, GetDate())) / 60.0)
       END As runtime_minutes,
       CASE WHEN JS.State In (4, 9) AND JS.Remote_Info_ID > 1 THEN CONVERT(varchar(12), CONVERT(decimal(9, 2), IsNull(JS.remote_progress, 0))) + '% complete'
            WHEN JS.State = 4 THEN CONVERT(varchar(12), CONVERT(decimal(9, 2), PS.Progress)) + '% complete'
            WHEN JS.State = 5 THEN 'Complete'
            ELSE 'Not started'
       END AS job_progress,
       CASE WHEN JS.State = 4 AND JS.Tool = 'XTandem' THEN 0      -- We cannot predict runtime for X!Tandem jobs since progress is not properly reported
            WHEN (JS.State = 9 Or JS.Remote_Info_ID > 1) AND IsNull(JS.remote_progress, 0) > 0 THEN
               CONVERT(DECIMAL(9,2), DATEDIFF(second, JS.remote_start, ISNULL(JS.remote_finish, GetDate())) /
                                          (JS.Remote_Progress / 100.0) / 60.0 / 60.0)
            WHEN JS.State = 4 AND PS.Progress > 0 THEN
               CONVERT(DECIMAL(9,2), DATEDIFF(second, JS.start, ISNULL(JS.finish, GetDate())) /
                                          (PS.Progress / 100.0) / 60.0 / 60.0)
            WHEN JS.State = 5 THEN Convert(decimal(9,2), DATEDIFF(second, JS.start, IsNull(JS.finish, GetDate())) / 60.0 / 60.0)
            ELSE 0
       END AS runtime_predicted_hours,
       JS.processor,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.signature,
       JS.cpu_load,
       JS.actual_cpu_load,
       JS.memory_usage_mb,
       JS.tool_version_id,
       STV.tool_version,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       JS2.Dataset_Folder_Path AS dataset_folder_path,
       J.Transfer_Folder_Path AS transfer_folder_path,
       JS2.Log_File_Path AS log_file_path,
       JS.next_try,
       JS.retry_count,
       JS.Remote_Info_ID As remote_info_id,
       Replace(Replace(RI.remote_info, '<', '&lt;'), '>', '&gt;') As remote_info,
       JS.remote_start,
       JS.remote_finish
FROM dbo.T_Job_Steps AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Jobs AS J
       ON JS.Job = J.Job
     INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID
     INNER JOIN V_Job_Steps2 AS JS2
       ON JS.Job = JS2.Job AND
          JS.Step = JS2.Step
     LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV
       ON JS.Tool_Version_ID = STV.Tool_Version_ID
     LEFT OUTER JOIN dbo.T_Processor_Status (READUNCOMMITTED) PS
       ON JS.Processor = PS.Processor_Name
     LEFT OUTER JOIN dbo.T_Remote_Info RI
       ON RI.Remote_Info_ID = JS.Remote_Info_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
