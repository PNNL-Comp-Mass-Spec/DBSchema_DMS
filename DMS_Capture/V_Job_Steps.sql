/****** Object:  View [dbo].[V_Job_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps]
AS
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
       DATEDIFF(MINUTE, PS.Status_Date, GetDate()) AS LastCPUStatus_Minutes,
       CASE
           WHEN State = 4 THEN PS.Progress
           WHEN State = 5 THEN 100
           ELSE 0
       END AS Job_Progress,
       CASE
           WHEN State = 4 AND
                PS.Progress > 0 THEN CONVERT(decimal(9, 2), JS.RunTime_Minutes / (PS.Progress / 
                                                            100.0) / 60.0)
           ELSE 0
       END AS RunTime_Predicted_Hours,
       JS.Processor,
	   CASE WHEN JS.State = 4 THEN PS.Process_ID ELSE NULL END AS Process_ID,
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
       JS.Job_State
FROM ( SELECT JS.Job,
              J.Dataset,
              J.Dataset_ID,
              JS.Step_Number AS Step,
              S.Script,
              JS.Step_Tool AS Tool,
              SSN.Name AS StateName,
              JS.State,
              JS.Start,
              JS.Finish,
       CONVERT(decimal(9, 1), DATEDIFF(SECOND, JS.Start, ISNULL(JS.Finish, GetDate())) / 60.0) AS 
         RunTime_Minutes,
              JS.Processor,
              JS.Input_Folder_Name AS Input_Folder,
              JS.Output_Folder_Name AS Output_Folder,
              J.Priority,
			  JS.Dependencies,
              JS.CPU_Load,
              JS.Completion_Code,
              JS.Completion_Message,
              JS.Evaluation_Code,
              JS.Evaluation_Message,
              JS.Holdoff_Interval_Minutes,
              JS.Next_Try,
              JS.Retry_Count,
              J.Instrument,
              J.Storage_Server,
              J.Transfer_Folder_Path,
              JS.Tool_Version_ID,
              STV.Tool_Version,
              DI.SP_vol_name_client + DI.SP_path + DI.DS_folder_name AS Dataset_Folder_Path,
              DI.SP_vol_name_server + DI.SP_path + DI.DS_folder_name AS Server_Folder_Path,
			  J.Capture_Subfolder,
              J.State AS Job_State
       FROM dbo.T_Job_Steps JS
            INNER JOIN dbo.T_Job_Step_State_Name SSN
              ON JS.State = SSN.ID
            INNER JOIN dbo.T_Jobs J
              ON JS.Job = J.Job
            INNER JOIN dbo.T_Scripts S
              ON J.Script = S.Script
            LEFT OUTER JOIN dbo.V_DMS_Get_Dataset_Info DI
              ON J.Dataset = DI.Dataset_Num
            LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV
              ON JS.Tool_Version_ID = STV.Tool_Version_ID
       WHERE J.State <> 101 ) JS
     LEFT OUTER JOIN dbo.T_Processor_Status PS ( READUNCOMMITTED )
       ON JS.Processor = PS.Processor_Name



GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Steps] TO [DDL_Viewer] AS [dbo]
GO
