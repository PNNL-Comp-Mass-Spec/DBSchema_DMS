/****** Object:  View [dbo].[V_Analysis_Job_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Analysis_Job_Entry
AS
SELECT     CONVERT(varchar(32), dbo.T_Analysis_Job.AJ_jobID) AS Job, dbo.T_Analysis_Job.AJ_priority, dbo.T_Analysis_Tool.AJT_toolName AS AJ_ToolName, 
                      dbo.T_Dataset.Dataset_Num AS AJ_Dataset, dbo.T_Analysis_Job.AJ_parmFileName AS AJ_ParmFile, 
                      dbo.T_Analysis_Job.AJ_settingsFileName AS AJ_SettingsFile, dbo.T_Organisms.OG_name AS AJ_Organism, 
                      dbo.T_Analysis_Job.AJ_organismDBName AS AJ_OrganismDB, dbo.T_Analysis_Job.AJ_owner, dbo.T_Analysis_Job.AJ_comment, 
                      dbo.T_Analysis_Job.AJ_batchID, dbo.T_Analysis_Job.AJ_assignedProcessorName, dbo.T_Analysis_Job.AJ_proteinCollectionList AS protCollNameList, 
                      dbo.T_Analysis_Job.AJ_proteinOptionsList AS protCollOptionsList, dbo.T_Analysis_State_Name.AJS_name AS stateName, 
                      CASE dbo.T_Analysis_Job.AJ_propagationMode WHEN 0 THEN 'Export' ELSE 'No Export' END AS propagationMode, 
                      dbo.T_Analysis_Job_Processor_Group.Group_Name AS associatedProcessorGroup
FROM         dbo.T_Analysis_Job_Processor_Group INNER JOIN
                      dbo.T_Analysis_Job_Processor_Group_Associations ON 
                      dbo.T_Analysis_Job_Processor_Group.ID = dbo.T_Analysis_Job_Processor_Group_Associations.Group_ID RIGHT OUTER JOIN
                      dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Analysis_State_Name ON dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID ON 
                      dbo.T_Analysis_Job_Processor_Group_Associations.Job_ID = dbo.T_Analysis_Job.AJ_jobID

GO
