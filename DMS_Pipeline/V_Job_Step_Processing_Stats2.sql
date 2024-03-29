/****** Object:  View [dbo].[V_Job_Step_Processing_Stats2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Processing_Stats2]
AS
SELECT Entered,
       Job,
       Dataset,
       Step,
       Script,
       Tool,
       Start,
       Finish,
       RunTime_Minutes_Snapshot,
       Current_Runtime_Minutes,
       Job_Progress_Snapshot,
       Current_Progress,
       Runtime_Predicted_Hours_Snapshot,
       Current_RunTime_Predicted_Hours,
       Processor,
       Prog_Runner_Core_Usage,
       CPU_Load,
       Actual_CPU_Load,
       Current_State_Name,
       Current_State,
       Transfer_Folder_Path,
       LogFolderPath + 
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
         TheYear + '.txt' AS Log_File_Path
FROM ( SELECT JSPS.Entered,
              JSPS.Job,
              J.Dataset,
              JSPS.Step,
              J.Script,
              JS.Tool,
              JS.Start,
              JS.Finish,
              JSPS.RunTime_Minutes AS RunTime_Minutes_Snapshot,
              JS.RunTime_Minutes AS Current_Runtime_Minutes,
              JSPS.Job_Progress AS Job_Progress_Snapshot,
              JS.Job_Progress AS Current_Progress,
              JSPS.RunTime_Predicted_Hours AS Runtime_Predicted_Hours_Snapshot,
              JS.RunTime_Predicted_Hours AS Current_RunTime_Predicted_Hours,
              JSPS.Processor,
              JSPS.ProgRunner_CoreUsage AS Prog_Runner_Core_Usage,
              JSPS.CPU_Load,
              JSPS.Actual_CPU_Load,
              JSN.Name AS Current_State_Name,
              JS.State AS Current_State,
              JS.Transfer_Folder_Path,
              '\\' + LP.Machine + '\DMS_Programs\AnalysisToolManager' + 
                CASE WHEN JS.Processor LIKE '%-[1-9]' 
				THEN RIGHT(JS.Processor, 1)
                ELSE ''
                END + '\Logs\' AS LogFolderPath,
              CONVERT(varchar(2), MONTH(JS.Start)) AS TheMonth,
              CONVERT(varchar(2), DAY(JS.Start)) AS TheDay,
              CONVERT(varchar(4), YEAR(JS.Start)) AS TheYear
       FROM T_Job_Step_Processing_Stats JSPS
            LEFT OUTER JOIN T_Local_Processors LP
              ON LP.Processor_Name = JSPS.Processor
            LEFT OUTER JOIN T_Jobs J
                            INNER JOIN V_Job_Steps JS
                              ON J.Job = JS.Job
                            INNER JOIN T_Job_Step_State_Name JSN
                              ON JS.State = JSN.ID
              ON JSPS.Job = JS.Job AND
                 JSPS.Step = JS.Step ) DataQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Processing_Stats2] TO [DDL_Viewer] AS [dbo]
GO
