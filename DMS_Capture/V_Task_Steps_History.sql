/****** Object:  View [dbo].[V_Task_Steps_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Task_Steps_History]
AS
SELECT JS.job,
       J.dataset,
       J.dataset_id,
       JS.Step AS step,
       S.script,
       JS.Tool AS tool,
       SSN.Name AS state_name,
       JS.state,
       JS.start,
       JS.finish,
       CONVERT(decimal(9, 1), DATEDIFF(SECOND, JS.Start, ISNULL(JS.Finish, GETDATE())) / 60.0) AS runtime_minutes,
       JS.processor,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       InstName.IN_name AS instrument,
       JS.tool_version_id,
       STV.tool_version,
       DI.SP_vol_name_client + DI.SP_path + DI.DS_folder_name AS dataset_folder_path,
       DI.SP_vol_name_server + DI.SP_path + DI.DS_folder_name AS server_folder_path,
       J.State AS job_state,
       JS.saved
FROM T_Task_Steps_History JS
     INNER JOIN T_Task_Step_State_Name SSN
       ON JS.State = SSN.ID
     INNER JOIN T_Tasks_History J
       ON JS.Job = J.Job AND
          JS.Saved = J.Saved
     INNER JOIN T_Scripts S
       ON J.Script = S.Script
     INNER JOIN S_DMS_T_Dataset DS
       ON J.Dataset_ID = DS.Dataset_ID
     INNER JOIN S_DMS_T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     LEFT OUTER JOIN S_DMS_V_DatasetFullDetails DI
       ON J.Dataset = DI.Dataset_Num
     LEFT OUTER JOIN T_Step_Tool_Versions STV
       ON JS.Tool_Version_ID = STV.Tool_Version_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Task_Steps_History] TO [DDL_Viewer] AS [dbo]
GO
