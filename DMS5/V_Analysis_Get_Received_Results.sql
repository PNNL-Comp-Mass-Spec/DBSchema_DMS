/****** Object:  View [dbo].[V_Analysis_Get_Received_Results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Analysis_Get_Received_Results
AS
SELECT CONVERT(varchar(32), T_Analysis_Job.AJ_jobID) 
   AS JobNum, T_Dataset.Dataset_Num AS Dataset, 
   T_Analysis_Job.AJ_resultsFolderName AS ResultsFolder, 
   t_storage_path.SP_vol_name_server + t_storage_path.SP_path AS
    ServerPath, 
   t_storage_path.SP_vol_name_client + t_storage_path.SP_path AS
    ClientPath, T_Dataset.DS_folder_name AS DatasetFolder, 
   T_Analysis_Job.AJ_assignedProcessorName AS Processor, 
   T_Analysis_Job.AJ_finish AS Finished
FROM T_Dataset INNER JOIN
   T_Analysis_Job ON 
   T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID INNER JOIN
   t_storage_path ON 
   T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID
WHERE (T_Analysis_Job.AJ_StateID = 3)
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Get_Received_Results] TO [DDL_Viewer] AS [dbo]
GO
