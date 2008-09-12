/****** Object:  View [dbo].[V_GetPipelineJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetPipelineJobs
AS
SELECT     AJ.AJ_jobID AS Job, AJ.AJ_priority AS Priority, dbo.T_Analysis_Tool.AJT_toolName AS Tool, dbo.T_Dataset.Dataset_Num AS Dataset, 
                      dbo.T_Dataset.Dataset_ID, AJ.AJ_settingsFileName AS Settings_File_Name, AJ.AJ_StateID AS State
FROM         dbo.T_Analysis_Job AS AJ INNER JOIN
                      dbo.T_Dataset_Archive AS DA ON AJ.AJ_datasetID = DA.AS_Dataset_ID INNER JOIN
                      dbo.T_Analysis_Tool ON AJ.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Dataset ON AJ.AJ_datasetID = dbo.T_Dataset.Dataset_ID AND DA.AS_Dataset_ID = dbo.T_Dataset.Dataset_ID
WHERE     (AJ.AJ_StateID IN (1, 8)) AND (DA.AS_state_ID IN (3, 4, 10)) AND (DA.AS_update_state_ID <> 3)

GO
