/****** Object:  View [dbo].[V_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps]
AS
SELECT	JS.Job,
		JS.Dataset,
		JS.Step,
		JS.Script,
		JS.Tool,
		JS.StateName,
		JS.State,
		JS.Start,
		JS.Finish,
		JS.RunTime_Minutes,
        DATEDIFF(minute, PS.Status_Date, GetDate()) AS LastCPUStatus_Minutes,
		CASE WHEN JS.State = 4 THEN PS.Progress 
		     WHEN JS.State = 5 THEN 100
		     ELSE 0 END AS Job_Progress,
		CASE WHEN JS.State = 4 AND JS.Tool = 'XTandem' THEN 0						-- We cannot predict runtime for X!Tandem jobs since progress is not properly reported
		     WHEN JS.State = 4 AND PS.Progress > 0     THEN CONVERT(DECIMAL(9,2), JS.RunTime_Minutes / (PS.Progress / 100.0) / 60.0)
		     WHEN JS.State = 5 THEN Convert(decimal(9,2), JS.RunTime_Minutes / 60.0)
			 ELSE 0
		END AS RunTime_Predicted_Hours,
		JS.Processor,
		CASE WHEN JS.State = 4 THEN PS.Process_ID ELSE NULL END AS Process_ID,
		JS.Input_Folder,
		JS.Output_Folder,
		JS.Priority,
		JS.Signature,
		JS.Dependencies,
		JS.CPU_Load,
		JS.Actual_CPU_Load,
		JS.Memory_Usage_MB,
		JS.Tool_Version_ID,
		JS.Tool_Version,
		JS.Completion_Code,
		JS.Completion_Message,
		JS.Evaluation_Code,
		JS.Evaluation_Message,
		JS.Dataset_ID,
		JS.Transfer_Folder_Path
FROM (
	SELECT JS.Job,
		   J.Dataset,
		   J.Dataset_ID,
		   JS.Step_Number AS Step,
		   S.Script,
		   JS.Step_Tool AS Tool,
		   SSN.Name AS StateName,
		   JS.State,
		   JS.Start,
		   JS.Finish,
		   CONVERT(decimal(9, 1), DATEDIFF(second, JS.Start, ISNULL(JS.Finish, GetDate())) / 60.0) AS RunTime_Minutes,
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
		   J.Transfer_Folder_Path,
		   JS.Tool_Version_ID,
		   STV.Tool_Version
	FROM dbo.T_Job_Steps JS
		 INNER JOIN dbo.T_Job_Step_State_Name SSN
		   ON JS.State = SSN.ID
		 INNER JOIN dbo.T_Jobs J
		   ON JS.Job = J.Job
		 INNER JOIN dbo.T_Scripts S
		   ON J.Script = S.Script
		 LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV 
		   ON JS.Tool_Version_ID = STV.Tool_Version_ID
	) JS
     LEFT OUTER JOIN dbo.T_Processor_Status (READUNCOMMITTED) PS
       ON JS.Processor = PS.Processor_Name



GO
GRANT INSERT ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps] TO [PNL\D3M580] AS [dbo]
GO
