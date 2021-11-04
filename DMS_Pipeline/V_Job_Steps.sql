/****** Object:  View [dbo].[V_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps]
AS
SELECT  JS.Job,
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
        CASE WHEN (JS.State = 9 OR JS.Retry_Count > 0) THEN JS.Remote_Progress
             WHEN JS.State = 4 THEN PS.Progress 
             WHEN JS.State IN (3, 5) THEN 100             
             ELSE 0 END AS Job_Progress,
        CASE WHEN (JS.State = 9 OR JS.Retry_Count > 0) AND JS.Remote_Progress > 0
                                                              THEN CONVERT(DECIMAL(9,2), JS.RunTime_Minutes / (JS.Remote_Progress / 100.0) / 60.0)
             WHEN  JS.State = 4 AND JS.Tool = 'XTandem'       THEN 0                        -- We cannot predict runtime for X!Tandem jobs since progress is not properly reported
             WHEN  JS.State = 4 AND PS.Progress > 0           THEN CONVERT(DECIMAL(9,2), JS.RunTime_Minutes / (PS.Progress / 100.0) / 60.0)
             WHEN  JS.State = 5 THEN Convert(decimal(9,2), JS.RunTime_Minutes / 60.0)
             ELSE 0
        END AS RunTime_Predicted_Hours,
        JS.Processor,
        CASE WHEN JS.State = 4 THEN PS.Process_ID ELSE NULL END AS Process_ID,
        CASE WHEN JS.State = 4 THEN PS.ProgRunner_ProcessID ELSE NULL END AS ProgRunner_ProcessID,
        CASE WHEN JS.State = 4 THEN PS.ProgRunner_CoreUsage ELSE NULL END AS ProgRunner_CoreUsage,
        CASE WHEN JS.State = 4 AND NOT (PS.Job = JS.Job AND PS.Job_Step = JS.Step)
             THEN 'Error, running job ' + Cast(PS.Job as varchar(12)) + ', step ' + Cast(PS.Job_Step as varchar(9))
             ELSE ''
        END AS Processor_Warning,
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
        JS.DataPkgID,
        JS.Transfer_Folder_Path,
        '\\' + LP.Machine + '\DMS_Programs\AnalysisToolManager' + 
            CASE WHEN JS.Processor LIKE '%-[1-9]' 
            THEN RIGHT(JS.Processor, 1)
            ELSE ''
            END + '\Logs\' AS LogFilePath
FROM (
    SELECT JS.Job,
           J.Dataset,
           J.Dataset_ID,
           J.DataPkgID,
           JS.Step_Number AS Step,
           S.Script,
           JS.Step_Tool AS Tool,
           SSN.Name AS StateName,
           JS.State,
           CASE WHEN JS.State <> 4 AND NOT JS.Remote_Start IS NULL
                THEN JS.Remote_Start
                ELSE JS.Start
           END AS Start,
           CASE WHEN JS.State <> 4 AND NOT JS.Remote_Start IS NULL
                THEN JS.Remote_Finish
                ELSE JS.Finish
           END AS Finish,
           CASE WHEN (JS.State = 9 OR JS.Retry_Count > 0) AND NOT JS.Remote_Start IS NULL
                THEN CONVERT(decimal(9, 1), DATEDIFF(second, JS.Remote_Start, ISNULL(JS.Remote_Finish, GetDate())) / 60.0)
                ELSE CONVERT(decimal(9, 1), DATEDIFF(second, JS.Start,        ISNULL(JS.Finish, GetDate())) / 60.0) 
           END AS RunTime_Minutes,
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
           RI.Remote_Info,        
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
         INNER JOIN dbo.T_Scripts S
           ON J.Script = S.Script
         LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV 
           ON JS.Tool_Version_ID = STV.Tool_Version_ID
         LEFT OUTER JOIN dbo.T_Remote_Info RI 
           ON JS.Remote_Info_ID = RI.Remote_Info_ID
    ) JS
    LEFT OUTER JOIN dbo.T_Processor_Status (READUNCOMMITTED) PS
       ON JS.Processor = PS.Processor_Name
    LEFT OUTER JOIN dbo.T_Local_Processors LP
       ON JS.Processor = LP.Processor_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps] TO [Limited_Table_Write] AS [dbo]
GO
