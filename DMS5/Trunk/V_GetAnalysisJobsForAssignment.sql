/****** Object:  View [dbo].[V_GetAnalysisJobsForAssignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view V_GetAnalysisJobsForAssignment
as
SELECT     TOP 100 PERCENT dbo.V_Analysis_Job.JobNum AS Job, dbo.V_Analysis_Job.DatasetNum AS Dataset, dbo.V_Analysis_Job.ToolName AS Tool, 
                      dbo.V_Analysis_Job.ParmFileName AS [Parm File], dbo.V_Analysis_Job.OrganismDBName AS [Organism DB File], dbo.V_Analysis_Job.priority, 
                      dbo.V_Analysis_Job.AssignedProcessor, dbo.DatasetPreference(dbo.V_Analysis_Job.DatasetNum) AS Preference, dbo.T_Dataset_Archive.AS_state_ID, 
                      dbo.V_Analysis_Job.StateID AS JobStateID
FROM         dbo.V_Analysis_Job INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.V_Analysis_Job.DatasetID = dbo.T_Dataset_Archive.AS_Dataset_ID
WHERE     (dbo.V_Analysis_Job.StateID = 1) OR
                      (dbo.V_Analysis_Job.StateID = 2)
GO
