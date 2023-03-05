/****** Object:  View [dbo].[V_Task_Steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Task_Steps]
AS
SELECT JS.job,
       JS.dataset,
       JS.dataset_id,
       JS.step,
       JS.script,
       JS.tool,
       JS.StateName AS state_name,
       JS.state,
       JS.start,
       JS.finish,
       JS.runtime_minutes,
       DATEDIFF(MINUTE, PS.Status_Date, GetDate()) AS last_cpu_status_minutes,
       CASE
           WHEN State = 4 THEN PS.Progress
           WHEN State = 5 THEN 100
           ELSE 0
       END AS job_progress,
       CASE
           WHEN State = 4 AND
                PS.Progress > 0 THEN CONVERT(decimal(9, 2), JS.RunTime_Minutes / (PS.Progress /
                                                            100.0) / 60.0)
           ELSE 0
       END AS runtime_predicted_hours,
       JS.processor,
	   CASE WHEN JS.State = 4 THEN PS.Process_ID ELSE NULL END AS process_id,
       JS.input_folder,
       JS.output_folder,
       JS.priority,
	   JS.dependencies,
       JS.cpu_load,
       JS.tool_version_id,
       JS.tool_version,
       JS.completion_code,
       JS.completion_message,
       JS.evaluation_code,
       JS.evaluation_message,
       JS.holdoff_interval_minutes,
       JS.next_try,
       JS.retry_count,
       JS.instrument,
	   'http://dms2.pnl.gov/helper_inst_source/view/' + JS.Instrument AS instrument_source_files,
       JS.storage_server,
       JS.transfer_folder_path,
       JS.dataset_folder_path,
       JS.server_folder_path,
	   JS.capture_subfolder,
       JS.job_state
FROM ( SELECT JS.Job,
              J.Dataset,
              J.Dataset_ID,
              JS.Step AS Step,
              S.Script,
              JS.Tool AS Tool,
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
       FROM dbo.T_Task_Steps JS
            INNER JOIN dbo.T_Task_Step_State_Name SSN
              ON JS.State = SSN.ID
            INNER JOIN dbo.T_Tasks J
              ON JS.Job = J.Job
            INNER JOIN dbo.T_Scripts S
              ON J.Script = S.Script
            LEFT OUTER JOIN dbo.S_DMS_V_DatasetFullDetails DI
              ON J.Dataset = DI.Dataset_Num
            LEFT OUTER JOIN dbo.T_Step_Tool_Versions STV
              ON JS.Tool_Version_ID = STV.Tool_Version_ID
       WHERE J.State <> 101 ) JS
     LEFT OUTER JOIN dbo.T_Processor_Status PS ( READUNCOMMITTED )
       ON JS.Processor = PS.Processor_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Task_Steps] TO [DDL_Viewer] AS [dbo]
GO
