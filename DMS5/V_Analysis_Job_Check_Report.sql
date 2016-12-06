/****** Object:  View [dbo].[V_Analysis_Job_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Check_Report
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS Job, dbo.T_Analysis_State_Name.AJS_name AS State, dbo.T_Analysis_Job.AJ_start AS Started, 
                      dbo.T_Analysis_Job.AJ_finish AS Finished, ISNULL(dbo.T_Analysis_Job.AJ_assignedProcessorName, '(none)') AS CPU, 
                      dbo.T_Analysis_Tool.AJT_toolName AS [Tool Name], dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Analysis_Job.AJ_comment AS Comment, 
                      dbo.T_Analysis_Job.AJ_priority AS [Pri.], dbo.t_storage_path.SP_machine_name AS Storage, dbo.t_storage_path.SP_path AS Path, 
                      dbo.T_Analysis_Job.AJ_parmFileName AS [Parm File], dbo.T_Analysis_Job.AJ_settingsFileName AS [Settings File], 
                      dbo.T_Analysis_Job.AJ_organismDBName AS [Organism DB], dbo.T_Analysis_Job.AJ_proteinCollectionList AS [Protein Collection List], 
                      dbo.T_Analysis_Job.AJ_proteinOptionsList AS [Protein Options], ISNULL(dbo.T_Analysis_Job.AJ_resultsFolderName, '(none)') AS [Results Folder], 
                      dbo.T_Analysis_Job.AJ_batchID AS Batch, dbo.T_Organisms.OG_name AS Organism, ISNULL(DATEDIFF(hour, dbo.T_Analysis_Job.AJ_start, 
                      GETDATE()), 0) AS Elapsed
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Analysis_State_Name ON dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID
WHERE     (NOT (dbo.T_Analysis_Job.AJ_StateID IN (1, 4)))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Check_Report] TO [DDL_Viewer] AS [dbo]
GO
