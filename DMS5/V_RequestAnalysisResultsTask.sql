/****** Object:  View [dbo].[V_RequestAnalysisResultsTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_RequestAnalysisResultsTask
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS Job, dbo.T_Dataset.Dataset_Num AS Dataset, dbo.t_storage_path.SP_vol_name_server AS StorageVol, 
                      dbo.t_storage_path.SP_vol_name_client AS StorageVolExternal, dbo.t_storage_path.SP_path AS StoragePath, 
                      dbo.T_Dataset.DS_folder_name AS DatasetFolder, dbo.t_storage_path.SP_machine_name AS StorageServer, 
                      dbo.T_Analysis_Job.AJ_assignedProcessorName AS Processor, dbo.T_Analysis_Job.AJ_resultsFolderName AS ResultsFolder, 
                      dbo.T_MiscPaths.Client AS ServerRelativeTransferPath, 
                      dbo.t_storage_path.SP_vol_name_client + dbo.T_MiscPaths.Client AS ClientFullTransferPath
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Analysis_Job ON dbo.T_Dataset.Dataset_ID = dbo.T_Analysis_Job.AJ_datasetID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID CROSS JOIN
                      dbo.T_MiscPaths
WHERE     (dbo.T_MiscPaths.[Function] = 'AnalysisXfer')

GO
GRANT VIEW DEFINITION ON [dbo].[V_RequestAnalysisResultsTask] TO [DDL_Viewer] AS [dbo]
GO
