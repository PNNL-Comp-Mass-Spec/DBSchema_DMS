/****** Object:  View [dbo].[V_Job_Steps_History_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Job_Steps_History_Export]
AS
SELECT JS.job,
       J.dataset,
       J.dataset_id,
       JS.Step as step,
       J.script,
       JS.Tool AS tool,
       SSN.Name AS state_name,
       JS.state,
       JS.start,
       JS.finish,
       JS.processor,
       JS.Input_Folder_Name AS input_folder,
       JS.Output_Folder_Name AS output_folder,
       J.priority,
       JS.signature,
       JS.memory_usage_mb,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       JS.remote_info_id,
       JS.remote_start,
       JS.remote_finish,
       J.transfer_folder_path,
       JS.tool_version_id,
       STV.tool_version,
       JS.saved
FROM dbo.T_Job_Steps_History JS
     INNER JOIN dbo.T_Job_Step_State_Name SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Jobs_History J
       ON JS.Job = J.Job And
          JS.Saved = J.Saved
     LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV
       ON JS.Tool_Version_ID = STV.Tool_Version_ID
WHERE J.Most_Recent_Entry = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_History_Export] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_History_Export] TO [Limited_Table_Write] AS [dbo]
GO
