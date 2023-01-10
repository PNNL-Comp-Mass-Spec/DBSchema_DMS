/****** Object:  View [dbo].[V_Analysis_Delta_T_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Delta_T_Report]
AS
SELECT CONVERT(varchar(32), T_Analysis_Job.AJ_jobID) AS job,
       DATEDIFF(mi, T_Analysis_Job.AJ_start, T_Analysis_Job.AJ_finish) AS delta_t,
       T_Analysis_Job.AJ_priority AS priority,
       T_Analysis_State_Name.AJS_name AS state,
       T_Analysis_Tool.AJT_toolName AS tool_name,
       T_Dataset.Dataset_Num AS dataset,
       T_Analysis_Job.AJ_parmFileName AS param_file,
       T_Analysis_Job.AJ_settingsFileName AS settings_file,
       T_Organisms.OG_name AS organism,
       T_Analysis_Job.AJ_organismDBName AS organism_db,
       T_Analysis_Job.AJ_proteinCollectionList AS protein_collection_list,
       T_Analysis_Job.AJ_proteinOptionsList AS protein_options,
       T_Analysis_Job.AJ_comment AS comment,
       T_Analysis_Job.AJ_created AS created,
       T_Analysis_Job.AJ_start AS started,
       T_Analysis_Job.AJ_finish AS finished,
       ISNULL(T_Analysis_Job.AJ_assignedProcessorName, '(none)') AS cpu,
       ISNULL(T_Analysis_Job.AJ_resultsFolderName, '(none)') AS results_folder
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


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Delta_T_Report] TO [DDL_Viewer] AS [dbo]
GO
