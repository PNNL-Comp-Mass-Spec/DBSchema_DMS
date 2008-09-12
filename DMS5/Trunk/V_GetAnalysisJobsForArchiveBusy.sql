/****** Object:  View [dbo].[V_GetAnalysisJobsForArchiveBusy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetAnalysisJobsForArchiveBusy
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Analysis_Job ON dbo.T_Dataset.Dataset_ID = dbo.T_Analysis_Job.AJ_datasetID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID
WHERE     (dbo.T_Analysis_Job.AJ_StateID = 3) AND (NOT (dbo.T_Dataset_Archive.AS_state_ID IN (2, 7, 12))) AND 
                      (NOT (dbo.T_Dataset_Archive.AS_update_state_ID IN (3)))

GO
