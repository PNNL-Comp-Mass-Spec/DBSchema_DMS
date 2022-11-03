/****** Object:  View [dbo].[V_Capture_Job_Steps_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Capture_Job_Steps_List_Report]
AS
SELECT JS.Job,
       JS.Step_Number AS Step,
       S.Script,
       JS.Step_Tool AS Tool,
       SSN.Name AS Step_State,
       JSN.Name AS Job_State_B,
       JS.Retry_Count AS Retry,
       J.Dataset,
       JS.Processor,
       JS.Start,
       JS.Finish,
       CONVERT(decimal(9, 2), DATEDIFF(SECOND, JS.Start, ISNULL(JS.Finish, GETDATE())) / 60.0) AS Runtime,
       JS.State,
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.CPU_Load,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       JS.Job_Plus_Step AS id,
       J.Storage_Server,
	   J.Instrument
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
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Job_Steps_List_Report] TO [DDL_Viewer] AS [dbo]
GO
