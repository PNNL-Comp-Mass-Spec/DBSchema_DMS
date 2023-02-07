/****** Object:  View [dbo].[V_Job_Steps_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps_Export]
AS
SELECT JS.Job,
       J.Dataset,
       J.Dataset_ID,
       JS.Step_Number AS Step,
       J.Script,
       JS.Step_Tool AS Tool,
       SSN.Name AS State_Name,
       JS.State,
       JS.Start,
       JS.Finish,
       JS.Processor,
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Signature,
       JS.Dependencies,
       JS.CPU_Load,
       JS.Actual_CPU_Load,
       JS.Memory_Usage_MB,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       JS.Next_Try,
       JS.Retry_Count,
       JS.Remote_Info_ID,
       JS.Remote_Timestamp,
       JS.Remote_Start,
       JS.Remote_Finish,
       JS.Remote_Progress,
       J.Transfer_Folder_Path,
       JS.Tool_Version_ID,
       STV.Tool_Version
FROM dbo.T_Job_Steps JS
     INNER JOIN dbo.T_Job_Step_State_Name SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Jobs J
       ON JS.Job = J.Job
     LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV
       ON JS.Tool_Version_ID = STV.Tool_Version_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_Export] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps_Export] TO [Limited_Table_Write] AS [dbo]
GO
