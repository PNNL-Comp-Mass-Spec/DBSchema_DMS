/****** Object:  View [dbo].[V_DEPkgr_DSRequest_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_DSRequest_Analysis_Job
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS Analysis_Job_ID, dbo.T_Dataset.Dataset_ID, dbo.T_Requested_Run_History.ID AS Request_ID, 
                      dbo.T_Dataset.Dataset_Num AS Dataset_Name, dbo.T_Requested_Run_History.RDS_Name AS Request_Name, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Tool_Name
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Requested_Run_History ON dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run_History.DatasetID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID

GO
