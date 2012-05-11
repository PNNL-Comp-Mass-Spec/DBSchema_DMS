/****** Object:  View [dbo].[V_Job_Steps3] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps3] 
AS
-- Note: This view uses Gigasax.DMS5.dbo.V_Dataset_Folder_Paths and
--       it crashes when run on another server (i.e. when not run on Gigasax while referencing Gigasax)
SELECT Job, Dataset, Step, Script, Tool, Settings_File, Parameter_File, StateName, State, 
       Start, Finish, RunTime_Minutes, LastCPUStatus_Minutes, Job_Progress, Processor, Input_Folder, 
       Output_Folder, Priority, Signature, CPU_Load, 
       Completion_Code, Completion_Message, Evaluation_Code, 
       Evaluation_Message, Transfer_Folder_Path, 
       Dataset_Folder_Path,
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
              AJ.AJ_SettingsFileName AS Settings_File,
              AJ.AJ_ParmFileName AS Parameter_File,
              JS.Start,
              JS.Finish,
              JS.RunTime_Minutes,
              DATEDIFF(minute, PS.Status_Date, GetDate()) AS LastCPUStatus_Minutes,
              PS.Progress as Job_Progress,
              JS.Processor,
              JS.Input_Folder,
              JS.Output_Folder,
              JS.Priority,
              JS.Signature,
              JS.CPU_Load,
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
              CONVERT(varchar(4), YEAR(JS.Start)) AS TheYear,
              DFP.Dataset_Folder_Path
       FROM V_Job_Steps JS
            LEFT OUTER JOIN dbo.T_Local_Processors LP
              ON JS.Processor = LP.Processor_Name
            LEFT OUTER JOIN dbo.S_DMS_T_Analysis_Job AJ
              ON JS.Job = AJ.AJ_jobID
            LEFT OUTER JOIN Gigasax.DMS5.dbo.V_Dataset_Folder_Paths DFP
              ON JS.Dataset = DFP.Dataset
            LEFT OUTER JOIN dbo.T_Processor_Status (READUNCOMMITTED) PS
              ON JS.Processor = PS.Processor_Name
    ) DataQ



GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps3] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps3] TO [PNL\D3M580] AS [dbo]
GO
