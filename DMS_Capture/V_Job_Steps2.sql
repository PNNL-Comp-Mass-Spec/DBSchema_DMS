/****** Object:  View [dbo].[V_Job_Steps2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Job_Steps2]
AS
SELECT Job, Dataset, Dataset_ID, Step, Script, 
       Tool, StateName, State, Start, Finish, RunTime_Minutes, 
       LastCPUStatus_Minutes, Job_Progress, RunTime_Predicted_Hours, Processor, Process_ID,
       Input_Folder, Output_Folder, Priority, Dependencies, CPU_Load, Tool_Version_ID, 
       Tool_Version, Completion_Code, Completion_Message, Evaluation_Code, 
       Evaluation_Message, Holdoff_Interval_Minutes, Next_Try, Retry_Count, 
       Instrument, Storage_Server, Transfer_Folder_Path, Capture_Subfolder,
       Dataset_Folder_Path, Server_Folder_Path, Job_State, 
       LogFilePath + CASE WHEN YEAR(GetDate()) <> YEAR(Start) THEN TheYear + '\' ELSE ''END 
                + 'CapTaskMan_' + CASE WHEN LEN(TheMonth) = 1 THEN '0' + TheMonth ELSE TheMonth END 
                + '-' + CASE WHEN LEN(TheDay) = 1 THEN '0' + TheDay ELSE TheDay END 
                + '-' + TheYear + '.txt' AS LogFilePath
FROM (
	SELECT JS.Job,
		   JS.Dataset,
		   JS.Dataset_ID,
		   JS.Step,
		   JS.Script,
		   JS.Tool,
		   JS.StateName,
		   JS.State,
		   JS.Start,
		   JS.Finish,
		   JS.RunTime_Minutes,
		   JS.LastCPUStatus_Minutes,
		   JS.Job_Progress,
		   JS.RunTime_Predicted_Hours,
		   JS.Processor,
		   JS.Process_ID,
		   JS.Input_Folder,
		   JS.Output_Folder,
		   JS.Priority,
		   JS.Dependencies,
		   JS.CPU_Load,
		   JS.Tool_Version_ID,
		   JS.Tool_Version,
		   JS.Completion_Code,
		   JS.Completion_Message,
		   JS.Evaluation_Code,
		   JS.Evaluation_Message,
		   JS.Holdoff_Interval_Minutes,
		   JS.Next_Try,
		   JS.Retry_Count,
		   JS.Instrument,
		   JS.Storage_Server,
		   JS.Transfer_Folder_Path,
		   JS.Dataset_Folder_Path,
		   JS.Server_Folder_Path,
		   JS.Capture_Subfolder,
		   JS.Job_State,
		   '\\' + LP.Machine + '\DMS_Programs\CaptureTaskManager' + 
			 CASE
				 WHEN JS.Processor LIKE '%[-_][1-9]' THEN RIGHT(JS.Processor, 2)
				 ELSE ''
			 END + '\Logs\' AS LogFilePath,
		   CONVERT(varchar(2), MONTH(JS.Start)) AS TheMonth,
		   CONVERT(varchar(2), DAY(JS.Start)) AS TheDay,
		   CONVERT(varchar(4), YEAR(JS.Start)) AS TheYear
	FROM V_Job_Steps JS
		 LEFT OUTER JOIN T_Local_Processors LP
		   ON JS.Processor = LP.Processor_Name
      ) LookupQ



GO
