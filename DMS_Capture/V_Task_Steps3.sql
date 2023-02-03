/****** Object:  View [dbo].[V_Task_Steps3] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Task_Steps3]
AS
SELECT TS.job, dataset, dataset_id, step, script, 
       tool, state_name, state, start, finish, runtime_minutes, 
       last_cpu_status_minutes, job_progress, runtime_predicted_hours, processor, process_id,
       input_folder, output_folder, priority, cpu_load, tool_version_id, 
       tool_version, completion_code, completion_message, evaluation_code, 
       evaluation_message, holdoff_interval_minutes, next_try, retry_count, 
       instrument, storage_server, transfer_folder_path, 
       dataset_folder_path, server_folder_path, capture_subfolder, job_state, 
       log_file_path,
       MyEMSLStatus.status_uri
FROM V_Task_Steps2 TS
     LEFT OUTER JOIN ( SELECT Job,
                              Status_URI,
                              Row_Number() OVER ( PARTITION BY job ORDER BY entry_id DESC ) AS StatusRank
                       FROM V_MyEMSL_Uploads
                       WHERE NOT Status_URI IS NULL ) MyEMSLStatus
       ON TS.Job = MyEMSLStatus.Job AND
          MyEMSLStatus.StatusRank = 1 AND
          TS.Tool IN ('ArchiveVerify', 'DatasetArchive', 'ArchiveUpdate')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Task_Steps3] TO [DDL_Viewer] AS [dbo]
GO
