/****** Object:  View [dbo].[V_Analysis_Job_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Check_Report]
AS
SELECT dbo.T_Analysis_Job.AJ_jobID AS job,
       dbo.T_Analysis_State_Name.AJS_name AS state,
       dbo.T_Analysis_Job.AJ_start AS started,
       dbo.T_Analysis_Job.AJ_finish AS finished,
       ISNULL(dbo.T_Analysis_Job.aj_assignedprocessorname, '(none)') AS cpu,
       dbo.T_Analysis_Tool.AJT_toolName AS tool_name,
       dbo.T_Dataset.Dataset_Num AS dataset,
       dbo.T_Analysis_Job.AJ_comment AS comment,
       dbo.T_Analysis_Job.AJ_priority AS priority,
       dbo.t_storage_path.SP_machine_name AS storage,
       dbo.t_storage_path.SP_path AS path,
       dbo.T_Analysis_Job.AJ_parmFileName AS param_file,
       dbo.T_Analysis_Job.AJ_settingsFileName AS settings_file,
       dbo.T_Analysis_Job.AJ_organismDBName AS organism_db,
       dbo.T_Analysis_Job.AJ_proteinCollectionList AS protein_collection_list,
       dbo.T_Analysis_Job.AJ_proteinOptionsList AS protein_options,
       ISNULL(dbo.T_Analysis_Job.aj_resultsfoldername, '(none)') AS results_folder,
       dbo.T_Analysis_Job.AJ_batchID AS batch,
       dbo.T_Organisms.OG_name AS organism,
       ISNULL(DATEDIFF(HOUR, dbo.T_Analysis_Job.aj_start, GETDATE()), 0) AS elapsed_hours
FROM dbo.T_Analysis_Job
     INNER JOIN dbo.T_Dataset
       ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID
     INNER JOIN dbo.T_Organisms
       ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID
     INNER JOIN dbo.t_storage_path
       ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID
     INNER JOIN dbo.T_Analysis_Tool
       ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID
     INNER JOIN dbo.T_Analysis_State_Name
       ON dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID
WHERE (NOT (dbo.T_Analysis_Job.AJ_StateID IN (1, 4)))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Check_Report] TO [DDL_Viewer] AS [dbo]
GO
