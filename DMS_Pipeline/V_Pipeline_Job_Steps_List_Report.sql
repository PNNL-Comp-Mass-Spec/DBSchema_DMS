/****** Object:  View [dbo].[V_Pipeline_Job_Steps_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Job_Steps_List_Report]
AS
SELECT JS.job,
       JS.Step_Number AS step,
       J.script,
       JS.Step_Tool AS tool,
       ParamQ.parameter_file,
       SSN.Name AS step_state,
       JSN.Name AS job_state_b,
       J.dataset,
       JS.start,
       JS.finish,
       CASE WHEN (JS.State = 9 Or JS.Remote_Info_ID > 1) THEN
                Convert(decimal(9,2), DATEDIFF(second, JS.remote_start, ISNULL(JS.remote_finish, GetDate())) / 60.0)
            ELSE
                Convert(decimal(9,2), DATEDIFF(second, JS.start, IsNull(JS.finish, GetDate())) / 60.0)
       END As runtime_minutes,
       JS.processor,
       JS.state,
       CASE WHEN JS.State = 9 Or JS.Remote_Info_ID > 1 THEN Convert(DECIMAL(9,2), IsNull(JS.remote_progress, 0))
            WHEN JS.State = 4 THEN Convert(DECIMAL(9,2), PS.Progress)
            WHEN JS.State = 5 THEN 100
            ELSE 0
       END AS job_progress,
       CASE WHEN JS.State = 4 AND JS.Step_Tool = 'XTandem' THEN 0      -- We cannot predict runtime for X!Tandem jobs since progress is not properly reported
            WHEN (JS.State = 9 Or JS.Remote_Info_ID > 1) AND IsNull(JS.remote_progress, 0) > 0 THEN
               CONVERT(DECIMAL(9,2), DATEDIFF(second, JS.remote_start, ISNULL(JS.remote_finish, GetDate())) /
                                          (JS.Remote_Progress / 100.0) / 60.0 / 60.0)
            WHEN JS.State = 4 AND PS.Progress > 0 THEN
               CONVERT(DECIMAL(9,2), DATEDIFF(second, JS.start, ISNULL(JS.finish, GetDate())) /
                                          (PS.Progress / 100.0) / 60.0 / 60.0)
            WHEN JS.State = 5 THEN Convert(decimal(9,2), DATEDIFF(second, JS.start, IsNull(JS.finish, GetDate())) / 60.0 / 60.0)
            ELSE 0
       END AS runtime_predicted_hours,
       Convert(decimal(9,1), DATEDIFF(second, PS.status_date, GetDate()) / 60.0) AS last_cpu_status_minutes,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.signature,
       JS.cpu_load,
       JS.actual_cpu_load,
       JS.memory_usage_mb,
       JS.tool_version_id,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       ParamQ.settings_file,
       ParamQ.Dataset_Storage_Path + J.Dataset AS dataset_folder_path,
       JS.next_try,
       JS.retry_count,
       JS.Remote_Info_ID As remote_info_id,
       JS.remote_start,
       JS.remote_finish,
       JS.Job_Plus_Step AS id
FROM dbo.T_Job_Steps AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Jobs AS J
       ON JS.Job = J.Job
     INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID
     LEFT OUTER JOIN dbo.T_Processor_Status (READUNCOMMITTED) PS
      ON JS.Processor = PS.Processor_Name
     LEFT OUTER JOIN (
          SELECT Job,
                 Parameters.query('Param[@Name = "SettingsFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') AS Settings_File,
                 Parameters.query('Param[@Name = "ParamFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') AS Parameter_File,
                 Parameters.query('Param[@Name = "DatasetStoragePath"]').value('(/Param/@Value)[1]', 'varchar(256)') AS Dataset_Storage_Path
          FROM T_Job_Parameters
     ) ParamQ ON ParamQ.Job = JS.Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_List_Report] TO [DDL_Viewer] AS [dbo]
GO
