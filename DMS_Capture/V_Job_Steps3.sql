/****** Object:  View [dbo].[V_Job_Steps3] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Steps3]
AS
SELECT JS.Job, Dataset, Dataset_ID, Step, Script, 
       Tool, StateName, State, Start, Finish, RunTime_Minutes, 
       LastCPUStatus_Minutes, Job_Progress, RunTime_Predicted_Hours, Processor, Process_ID,
       Input_Folder, Output_Folder, Priority, CPU_Load, Tool_Version_ID, 
       Tool_Version, Completion_Code, Completion_Message, Evaluation_Code, 
       Evaluation_Message, Holdoff_Interval_Minutes, Next_Try, Retry_Count, 
       Instrument, Storage_Server, Transfer_Folder_Path, 
       Dataset_Folder_Path, Server_Folder_Path, Job_State, 
       LogFilePath,
       MyEMSLStatus.Status_URI
FROM V_Job_Steps2 JS
     LEFT OUTER JOIN ( SELECT Job,
                              Status_URI,
                              Row_Number() OVER ( PARTITION BY job ORDER BY entry_id DESC ) AS StatusRank
                       FROM V_MyEMSL_Uploads
                       WHERE NOT Status_URI IS NULL ) MyEMSLStatus
       ON JS.Job = MyEMSLStatus.Job AND
          MyEMSLStatus.StatusRank = 1 AND
          JS.Tool IN ('ArchiveVerify', 'DatasetArchive', 'ArchiveUpdate')

GO
