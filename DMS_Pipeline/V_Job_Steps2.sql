/****** Object:  View [dbo].[V_Job_Steps2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps2]
AS
SELECT DataQ.Job, DataQ.Dataset, DataQ.Step, DataQ.Script, DataQ.Tool, ParamQ.Settings_File, ParamQ.Parameter_File, DataQ.State_Name, DataQ.State,
       DataQ.Start, DataQ.Finish, DataQ.RunTime_Minutes, DataQ.Last_CPU_Status_Minutes, DataQ.Job_Progress, DataQ.RunTime_Predicted_Hours, DataQ.Processor, DataQ.Process_ID, DataQ.Prog_Runner_Process_ID, DataQ.Prog_Runner_Core_Usage,
       CASE WHEN DataQ.ProcessorWarningFlag = 0
            THEN 'pskill \\' + DataQ.Machine + ' ' + CAST(DataQ.Process_ID AS varchar(12))
            ELSE 'Processor Warning'
            END AS Kill_Manager,
       CASE WHEN DataQ.ProcessorWarningFlag = 0
            THEN 'pskill \\' + DataQ.Machine+ ' ' + CAST(DataQ.Prog_Runner_Process_ID AS varchar(12))
            ELSE 'Processor Warning'
            END AS Kill_Prog_Runner,
       DataQ.Processor_Warning,
       DataQ.Input_Folder, DataQ.Output_Folder, DataQ.Priority, DataQ.Signature, DataQ.Dependencies, DataQ.CPU_Load, DataQ.Actual_CPU_Load, DataQ.Memory_Usage_MB, DataQ.Tool_Version_ID, DataQ.Tool_Version,
       DataQ.Completion_Code, DataQ.Completion_Message,
       DataQ.Evaluation_Code, DataQ.Evaluation_Message,
       DataQ.Next_Try,
       DataQ.Retry_Count,
       DataQ.Remote_Info_ID,
       DataQ.Remote_Info,
       DataQ.Remote_Timestamp,
       DataQ.Remote_Start,
       DataQ.Remote_Finish,
       DataQ.Remote_Progress,
       DataQ.Dataset_ID,
       DataQ.Data_Pkg_ID,
       DataQ.Machine,
       DataQ.Work_Dir_Path,
       DataQ.Transfer_Folder_Path,
       ParamQ.Dataset_Storage_Path + DataQ.Dataset AS Dataset_Folder_Path,
       DataQ.Log_File_Path +
         CASE WHEN YEAR(GetDate()) <> YEAR(DataQ.Start) THEN TheYear + '\'
         ELSE ''
         END +
         'AnalysisMgr_' +
         DataQ.TheYear + '-' +
         CASE WHEN LEN(DataQ.TheMonth) = 1 THEN '0' + TheMonth
         ELSE DataQ.TheMonth
         END + '-' +
         CASE WHEN LEN(DataQ.TheDay) = 1 THEN '0' + TheDay
         ELSE DataQ.TheDay
         END +
         '.txt' AS Log_File_Path
FROM ( SELECT JS.Job,
              JS.Dataset,
              JS.Step,
              JS.Script,
              JS.Tool,
              JS.State_Name,
              JS.State,
              JS.Start,
              JS.Finish,
              JS.RunTime_Minutes,
              JS.Last_CPU_Status_Minutes,
              JS.Job_Progress,
              JS.RunTime_Predicted_Hours,
              JS.Processor,
              JS.Process_ID,
              JS.Prog_Runner_Process_ID,
              JS.Prog_Runner_Core_Usage,
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
              JS.Next_Try,
              JS.Retry_Count,
              JS.Remote_Info_ID,
              JS.Remote_Info,
              JS.Remote_Timestamp,
              JS.Remote_Start,
              JS.Remote_Finish,
              JS.Remote_Progress,
              JS.Dataset_ID,
              JS.Data_Pkg_ID,
              LP.Machine,
              LP.WorkDir_AdminShare AS Work_Dir_Path,
              JS.Transfer_Folder_Path,
              JS.Log_File_Path,
              CONVERT(varchar(4), YEAR(JS.Start)) AS TheYear,
              CONVERT(varchar(2), MONTH(JS.Start)) AS TheMonth,
              CONVERT(varchar(2), DAY(JS.Start)) AS TheDay
       FROM V_Job_Steps JS
            LEFT OUTER JOIN dbo.T_Local_Processors LP
              ON JS.Processor = LP.Processor_Name
    ) DataQ
    LEFT OUTER JOIN (
          SELECT Job,
                 Parameters.query('Param[@Name = "SettingsFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Settings_File,
                 Parameters.query('Param[@Name = "ParamFileName"]').value('(/Param/@Value)[1]', 'varchar(256)') as Parameter_File,
                 Parameters.query('Param[@Name = "DatasetStoragePath"]').value('(/Param/@Value)[1]', 'varchar(256)') as Dataset_Storage_Path
          FROM [T_Job_Parameters]
   ) ParamQ ON ParamQ.Job = DataQ.Job

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps2] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[V_Job_Steps2] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Job_Steps2] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Job_Steps2] TO [Limited_Table_Write] AS [dbo]
GO
