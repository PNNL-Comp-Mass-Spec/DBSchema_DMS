/****** Object:  View [dbo].[V_PDE_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_PDE_Analysis_Jobs
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS AnalysisID, dbo.T_Dataset.Dataset_Num AS BaseFileName, 
                      dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path + dbo.T_Dataset.DS_folder_name + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName
                       + '\' AS AnalysisJobDirectory
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID

GO
