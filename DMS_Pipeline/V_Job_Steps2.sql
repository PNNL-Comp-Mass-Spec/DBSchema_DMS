/****** Object:  View [dbo].[V_Job_Steps2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Job_Steps2] 
AS
SELECT DataQ.Job, DataQ.Dataset, DataQ.Step, DataQ.Script, DataQ.Tool, ParamQ.Settings_File, ParamQ.Parameter_File, DataQ.StateName, DataQ.State, 
       DataQ.Start, DataQ.Finish, DataQ.RunTime_Minutes, DataQ.LastCPUStatus_Minutes, DataQ.Job_Progress, DataQ.RunTime_Predicted_Hours, DataQ.Processor, DataQ.Process_ID, DataQ.ProgRunner_ProcessID, DataQ.ProgRunner_CoreUsage,
	   CASE WHEN DataQ.ProcessorWarningFlag = 0 
	        THEN 'pskill \\' + DataQ.Machine + ' ' + CAST(DataQ.Process_ID AS varchar(12)) 
			ELSE 'Processor Warning'
			END AS Kill_Manager,
	   CASE WHEN DataQ.ProcessorWarningFlag = 0 
	        THEN 'pskill \\' + DataQ.Machine+ ' ' + CAST(DataQ.ProgRunner_ProcessID AS varchar(12)) 
			ELSE 'Processor Warning'
			END AS Kill_ProgRunner,
	   DataQ.Processor_Warning,
	   DataQ.Input_Folder, DataQ.Output_Folder, DataQ.Priority, DataQ.Signature, DataQ.Dependencies, DataQ.CPU_Load, DataQ.Actual_CPU_Load, DataQ.Memory_Usage_MB, DataQ.Tool_Version_ID, DataQ.Tool_Version,
       DataQ.Completion_Code, DataQ.Completion_Message, DataQ.Evaluation_Code, 
       DataQ.Evaluation_Message, 
	   DataQ.Dataset_ID,
	   DataQ.Machine,
	   DataQ.Transfer_Folder_Path, 
       ParamQ.Dataset_Storage_Path + DataQ.Dataset AS Dataset_Folder_Path,
       DataQ.LogFilePath + 
         CASE WHEN YEAR(GetDate()) <> YEAR(DataQ.Start) THEN TheYear + '\'
         ELSE ''
         END + 
         'AnalysisMgr_' + 
         CASE WHEN LEN(DataQ.TheMonth) = 1 THEN '0' + TheMonth
         ELSE DataQ.TheMonth
         END + '-' + 
         CASE WHEN LEN(DataQ.TheDay) = 1 THEN '0' + TheDay
         ELSE DataQ.TheDay
         END + '-' + 
         DataQ.TheYear + '.txt' AS LogFilePath
FROM ( SELECT JS.Job,
              JS.Dataset,
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
			  JS.ProgRunner_ProcessID,
			  JS.ProgRunner_CoreUsage,
			  JS.Processor_Warning,
			  CASE WHEN Len(IsNull(JS.Processor_Warning, '')) = 0 Then 0 Else 1 End as ProcessorWarningFlag,
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
			  LP.Machine,
              JS.Transfer_Folder_Path,
              '\\' + LP.Machine + '\DMS_Programs\AnalysisToolManager' + 
                CASE WHEN JS.Processor LIKE '%-[1-9]' 
                THEN RIGHT(JS.Processor, 1)
                ELSE ''
                END + '\Logs\' AS LogFilePath,
              CONVERT(varchar(2), MONTH(JS.Start)) AS TheMonth,
              CONVERT(varchar(2), DAY(JS.Start)) AS TheDay,
              CONVERT(varchar(4), YEAR(JS.Start)) AS TheYear
       FROM V_Job_Steps JS
            LEFT OUTER JOIN dbo.T_Local_Processors LP
              ON JS.Processor = LP.Processor_Name
    ) DataQ
    LEFT OUTER JOIN ( 
          SELECT Job,
                 Parameters.query('Param[@Name = "SettingsFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Settings_File,
                 Parameters.query('Param[@Name = "ParmFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Parameter_File,
                 Parameters.query('Param[@Name = "DatasetStoragePath"]').value('(/Param/@Value)[1]', 'varchar(256)') as Dataset_Storage_Path                         
          FROM [T_Job_Parameters] 
   ) ParamQ ON ParamQ.Job = DataQ.Job


GO
GRANT INSERT ON [dbo].[V_Job_Steps2] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Job_Steps2] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Job_Steps2] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps2] TO [PNL\D3M580] AS [dbo]
GO
