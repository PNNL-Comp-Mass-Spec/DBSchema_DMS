/****** Object:  View [dbo].[V_Pipeline_Job_Steps_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Job_Steps_Detail_Report]
AS
SELECT JS.Job_Plus_Step AS ID,
       JS.Job,
       JS.Step_Number AS Step,
       J.Dataset,
       J.Script,
       JS.Step_Tool AS Tool,
       SSN.Name AS Step_State,
       JSN.Name as Job_State_B,
       JS.State AS StateID,
       JS.Start,
       JS.Finish,
       Convert(decimal(9, 2), DATEDIFF(second, JS.Start, IsNull(JS.Finish, GetDate())) / 60.0) as Runtime_Minutes,
       CASE WHEN JS.State In (4, 9) AND JS.Remote_Info_ID > 1 THEN CONVERT(varchar(12), CONVERT(decimal(9, 2), IsNull(JS.Remote_Progress, 0))) + '% complete' 
            WHEN JS.State = 4 THEN CONVERT(varchar(12), CONVERT(decimal(9, 2), PS.Progress)) + '% complete' 
            WHEN JS.State = 5 THEN 'Complete'
            ELSE 'Not started' 
       END AS Job_Progress,
       CASE WHEN JS.State = 4 AND JS.Step_Tool = 'XTandem' THEN 0      -- We cannot predict runtime for X!Tandem jobs since progress is not properly reported
            WHEN (JS.State = 9 Or JS.Remote_Info_ID > 1) AND IsNull(JS.Remote_Progress, 0) > 0 THEN
                CONVERT(decimal(9,2), DATEDIFF(second, JS.Start, ISNULL(JS.Finish, GetDate())) /
                                           (JS.Remote_Progress / 100.0) / 60.0 / 60.0)
            WHEN JS.State = 4 AND PS.Progress > 0  THEN 
                CONVERT(decimal(9,2), DATEDIFF(second, JS.Start, ISNULL(JS.Finish, GetDate())) /
                                           (PS.Progress / 100.0) / 60.0 / 60.0)
            WHEN JS.State = 5 THEN Convert(decimal(9,2), DATEDIFF(second, JS.Start, IsNull(JS.Finish, GetDate())) / 60.0 / 60.0)
            ELSE 0
       END AS [RunTime Predicted Hours],
       JS.Processor,
       JS.Input_Folder_Name AS Input_Folder,
       JS.Output_Folder_Name AS Output_Folder,
       J.Priority,
       JS.Signature,
       JS.CPU_Load,
       JS.Actual_CPU_Load,
       JS.Memory_Usage_MB,
       JS.Tool_Version_ID,
       STV.Tool_Version,
       JS.Completion_Code,
       JS.Completion_Message,
       JS.Evaluation_Code,
       JS.Evaluation_Message,
       JS2.Dataset_Folder_Path AS [Dataset Folder Path],
       J.Transfer_Folder_Path AS [Transfer Folder Path],
       JS2.LogFilePath AS [Log File Path],
       JS.Next_Try,
       JS.Retry_Count,
       JS.Remote_Info_ID As RemoteInfoID,
       Replace(Replace(RI.Remote_Info, '<', '&lt;'), '>', '&gt;') As Remote_Info,
       JS.Remote_Start,
       JS.Remote_Finish
FROM dbo.T_Job_Steps AS JS
     INNER JOIN dbo.T_Job_Step_State_Name AS SSN
       ON JS.State = SSN.ID
     INNER JOIN dbo.T_Jobs AS J
       ON JS.Job = J.Job
     INNER JOIN dbo.T_Job_State_Name JSN
       ON J.State = JSN.ID
     INNER JOIN V_Job_Steps2 AS JS2 
       ON JS.Job = JS2.Job AND 
          JS.Step_Number = JS2.Step
     LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV 
       ON JS.Tool_Version_ID = STV.Tool_Version_ID
     LEFT OUTER JOIN dbo.T_Processor_Status (READUNCOMMITTED) PS
       ON JS.Processor = PS.Processor_Name
     LEFT OUTER JOIN dbo.T_Remote_Info RI
       ON RI.Remote_Info_ID = JS.Remote_Info_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Job_Steps_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
