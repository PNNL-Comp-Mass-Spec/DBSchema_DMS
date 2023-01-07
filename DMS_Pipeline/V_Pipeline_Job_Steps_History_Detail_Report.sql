/****** Object:  View [dbo].[V_Pipeline_Job_Steps_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Job_Steps_History_Detail_Report]
AS
SELECT JS.JobStepSavedCombo AS id,
       JS.job,
       JS.Step_Number AS step,
       J.dataset,
       J.script,
       JS.Step_Tool AS tool,
       SSN.Name AS step_state,
       JSN.Name AS job_state_b,
       JS.State AS state_id,
       JS.start,
       JS.finish,
       Convert(decimal(9,2), DATEDIFF(second, JS.start, IsNull(JS.finish, GetDate())) / 60.0) AS runtime_minutes,
       JS.processor,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.signature,
       0 AS cpu_load,
	   0 AS actual_cpu_load,
       Memory_Usage_MB,
       JS.tool_version_id,
       STV.tool_version,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       ParamQ.Dataset_Storage_Path + Dataset AS dataset_folder_path,
       J.transfer_folder_path
FROM dbo.T_Job_Steps_History AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
       INNER JOIN ( SELECT Job, Dataset, Script, State, Priority, Transfer_Folder_Path
                    FROM T_Jobs_History
				    WHERE Most_Recent_Entry = 1
				 ) AS J
       ON JS.Job = J.Job
   INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID
   LEFT OUTER JOIN (
          SELECT Job,
				 Parameters.query('Param[@Name = "SettingsFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') ASWSettings_File,
				 Parameters.query('Param[@Name = "ParamFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') AS Parameter_File,
				 Parameters.query('Param[@Name = "DatasetStoragePath"]').value('(/Param/@Value)[1]', 'varchar(256)') AS Dataset_Storage_Path
		  FROM T_Job_Parameters_History
		  WHERE Most_Recent_Entry = 1
     ) ParamQ ON ParamQ.Job = JS.Job
     LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV
       ON JS.Tool_Version_ID = STV.Tool_Version_ID
WHERE Most_Recent_Entry = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_History_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
