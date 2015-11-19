/****** Object:  View [dbo].[V_Pipeline_Job_Steps_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Job_Steps_History_List_Report]
AS
SELECT JS.Job,
       JS.Step_Number AS Step,
       J.Script,
       JS.Step_Tool AS Tool,
	   SSN.Name AS Step_State,
	   JSN.Name as Job_State_B,
       J.Dataset,
       JS.Start,
       JS.Finish,
       Convert(decimal(9,2), DATEDIFF(second, JS.Start, IsNull(JS.Finish, GetDate())) / 60.0) as Runtime,
       JS.Processor,      
       JS.State,
		CASE WHEN JS.State = 5 THEN 100
		     ELSE 0 
		END AS [Job Progress],
		CASE WHEN JS.State = 5 THEN Convert(decimal(9,2), DATEDIFF(second, JS.Start, IsNull(JS.Finish, GetDate())) / 60.0 / 60.0)
			 ELSE 0
		END AS [RunTime Predicted Hours],
	   0 AS [Last CPU Status Minutes],
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Signature,
       0 AS CPU_Load,
	   0 AS Actual_CPU_Load,
       Memory_Usage_MB,
       JS.Tool_Version_ID,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       JobStepSavedCombo AS [#ID]
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
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_History_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_History_List_Report] TO [PNL\D3M580] AS [dbo]
GO
