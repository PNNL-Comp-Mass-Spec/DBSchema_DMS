/****** Object:  View [dbo].[V_DEPkgr_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Analysis_Jobs
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS Analysis_ID, dbo.T_Analysis_Job.AJ_created AS Created_Date, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Tool, dbo.T_Analysis_Job.AJ_parmFileName AS Parameter_File_Name, 
                      dbo.T_Analysis_Job.AJ_organismDBName AS Organism_Database_Used, dbo.T_Organisms.OG_name AS Organism, 
                      dbo.T_Analysis_Job.AJ_datasetID AS Dataset_ID, dbo.V_DEPkgr_Datasets.Dataset_Name, dbo.V_DEPkgr_Datasets.Experiment_Name, 
                      dbo.T_Analysis_State_Name.AJS_name AS Analysis_Job_State
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.V_DEPkgr_Datasets ON dbo.T_Analysis_Job.AJ_datasetID = dbo.V_DEPkgr_Datasets.Dataset_ID INNER JOIN
                      dbo.T_Analysis_State_Name ON dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID

GO
