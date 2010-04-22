/****** Object:  View [dbo].[V_Analysis_Results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create view V_Analysis_Results
as
SELECT     T_Analysis_Job.AJ_jobID AS Job, T_Dataset.Dataset_Num AS Dataset, t_storage_path.SP_vol_name_server AS StorageVol, 
                      t_storage_path.SP_vol_name_client AS StorageVolExternal, t_storage_path.SP_path AS StoragePath, T_Dataset.DS_folder_name AS DatasetFolder, 
                      t_storage_path.SP_machine_name AS StorageServer, T_Analysis_Job.AJ_assignedProcessorName AS Processor, 
                      T_Analysis_Job.AJ_resultsFolderName AS ResultsFolder, T_MiscPaths.Client AS ServerRelativeTransferPath, 
                      t_storage_path.SP_vol_name_client + T_MiscPaths.Client AS ClientFullTransferPath, T_Analysis_Job.AJ_StateID AS State
FROM         T_Dataset INNER JOIN
                      T_Analysis_Job ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID CROSS JOIN
                      T_MiscPaths
WHERE     (T_MiscPaths.[Function] = 'AnalysisXfer')



GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Results] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Results] TO [PNL\D3M580] AS [dbo]
GO
