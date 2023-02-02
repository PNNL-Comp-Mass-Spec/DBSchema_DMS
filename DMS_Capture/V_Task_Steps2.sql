/****** Object:  View [dbo].[V_Task_Steps2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Task_Steps2]
AS
SELECT job, dataset, dataset_id, step, script, 
       tool, state_name, state, start, finish, runtime_minutes, 
       last_cpu_status_minutes, job_progress, runtime_predicted_hours, processor, process_id,
       input_folder, output_folder, priority, dependencies, cpu_load, tool_version_id, 
       tool_version, completion_code, completion_message, evaluation_code, 
       evaluation_message, holdoff_interval_minutes, next_try, retry_count, 
       instrument, instrument_source_files, storage_server, transfer_folder_path, capture_subfolder,
       dataset_folder_path, server_folder_path, job_state, 
       log_file_path + 
         CASE WHEN YEAR(GetDate()) <> YEAR(Start) THEN TheYear + '\'
         ELSE ''
         END + 
         'CapTaskMan_' + 
         TheYear + '-' +
         CASE WHEN LEN(TheMonth) = 1 THEN '0' + TheMonth
         ELSE TheMonth
         END + '-' + 
         CASE WHEN LEN(TheDay) = 1 THEN '0' + TheDay
         ELSE TheDay
         END +
         '.txt' AS log_file_path
FROM (
	SELECT TS.job,
		   TS.dataset,
		   TS.dataset_id,
		   TS.step,
		   TS.script,
		   TS.tool,
		   TS.state_name,
		   TS.state,
		   TS.start,
		   TS.finish,
		   TS.runtime_minutes,
		   TS.last_cpu_status_minutes,
		   TS.job_progress,
		   TS.runtime_predicted_hours,
		   TS.processor,
		   TS.process_id,
		   TS.input_folder,
		   TS.output_folder,
		   TS.priority,
		   TS.dependencies,
		   TS.cpu_load,
		   TS.tool_version_id,
		   TS.tool_version,
		   TS.completion_code,
		   TS.completion_message,
		   TS.evaluation_code,
		   TS.evaluation_message,
		   TS.holdoff_interval_minutes,
		   TS.next_try,
		   TS.retry_count,
		   TS.instrument,
		   TS.instrument_source_files,
		   TS.storage_server,
		   TS.transfer_folder_path,
		   TS.dataset_folder_path,
		   TS.server_folder_path,
		   TS.capture_subfolder,
		   TS.job_state,
		   '\\' + LP.Machine + '\DMS_Programs\CaptureTaskManager' + 
			 CASE
				 WHEN TS.Processor LIKE '%[-_][1-9]' THEN RIGHT(TS.Processor, 2)
				 ELSE ''
			 END + '\Logs\' AS log_file_path,
           CONVERT(varchar(4), YEAR(TS.Start)) AS TheYear,
           CONVERT(varchar(2), MONTH(TS.Start)) AS TheMonth,
           CONVERT(varchar(2), DAY(TS.Start)) AS TheDay
	FROM V_Task_Steps TS
		 LEFT OUTER JOIN T_Local_Processors LP
		   ON TS.Processor = LP.Processor_Name
      ) LookupQ


GO
