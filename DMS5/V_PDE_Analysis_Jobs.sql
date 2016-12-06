/****** Object:  View [dbo].[V_PDE_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_PDE_Analysis_Jobs
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS AnalysisID, dbo.T_Dataset.Dataset_Num AS BaseFileName, 
                      dbo.V_Dataset_Folder_Paths.Dataset_Folder_Path + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName + '\' AS AnalysisJobDirectory, 
                      dbo.V_Dataset_Folder_Paths.Archive_Folder_Path + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName + '\' AS AnalysisJobArchiveDirectory
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.V_Dataset_Folder_Paths ON dbo.T_Dataset.Dataset_ID = dbo.V_Dataset_Folder_Paths.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_PDE_Analysis_Jobs] TO [DDL_Viewer] AS [dbo]
GO
