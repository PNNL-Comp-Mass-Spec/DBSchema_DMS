/****** Object:  View [dbo].[V_Job_Steps2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Job_Steps2] 
AS
SELECT DataQ.Job, Dataset, Step, Script, Tool, ParamQ.Settings_File, ParamQ.Parameter_File, StateName, State, 
       Start, Finish, RunTime_Minutes, LastCPUStatus_Minutes, Job_Progress, RunTime_Predicted_Hours, Processor, Input_Folder, 
       Output_Folder, Priority, Signature, CPU_Load, Memory_Usage_MB, Tool_Version_ID, Tool_Version,
       Completion_Code, Completion_Message, Evaluation_Code, 
       Evaluation_Message, Transfer_Folder_Path, 
       ParamQ.Dataset_Storage_Path + Dataset AS Dataset_Folder_Path,
       LogFilePath + 
         CASE WHEN YEAR(GetDate()) <> YEAR(Start) THEN TheYear + '\'
         ELSE ''
         END + 
         'AnalysisMgr_' + 
         CASE WHEN LEN(TheMonth) = 1 THEN '0' + TheMonth
         ELSE TheMonth
         END + '-' + 
         CASE WHEN LEN(TheDay) = 1 THEN '0' + TheDay
         ELSE TheDay
         END + '-' + 
         TheYear + '.txt' AS LogFilePath
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
              JS.Input_Folder,
              JS.Output_Folder,
              JS.Priority,
              JS.Signature,
              JS.CPU_Load,
              JS.Memory_Usage_MB,
              JS.Tool_Version_ID,
		      JS.Tool_Version,
              JS.Completion_Code,
              JS.Completion_Message,
              JS.Evaluation_Code,
              JS.Evaluation_Message,
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
