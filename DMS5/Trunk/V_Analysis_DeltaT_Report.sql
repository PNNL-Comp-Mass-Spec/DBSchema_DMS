/****** Object:  View [dbo].[V_Analysis_DeltaT_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_DeltaT_Report
AS
SELECT CONVERT(varchar(32), T_Analysis_Job.AJ_jobID) AS Job, 
   DATEDIFF(mi, T_Analysis_Job.AJ_start, 
   T_Analysis_Job.AJ_finish) AS deltaT, 
   T_Analysis_Job.AJ_priority AS [Pri.], 
   T_Analysis_State_Name.AJS_name AS State, 
   T_Analysis_Tool.AJT_toolName AS [Tool Name], 
   T_Dataset.Dataset_Num AS Dataset, 
   T_Analysis_Job.AJ_parmFileName AS [Parm File], 
   T_Analysis_Job.AJ_settingsFileName AS [Settings File], 
   T_Organisms.OG_name AS Organism, 
   T_Analysis_Job.AJ_organismDBName AS [Organism DB], 
   T_Analysis_Job.AJ_proteinCollectionList AS [Protein Collection List], 
   T_Analysis_Job.AJ_proteinOptionsList AS [Protein Options], 
   T_Analysis_Job.AJ_comment AS Comment, 
   T_Analysis_Job.AJ_created AS Created, 
   T_Analysis_Job.AJ_start AS Started, 
   T_Analysis_Job.AJ_finish AS Finished, 
   ISNULL(T_Analysis_Job.AJ_assignedProcessorName, '(none)') 
   AS CPU, ISNULL(T_Analysis_Job.AJ_resultsFolderName, 
   '(none)') AS [Results Folder]
FROM dbo.T_Analysis_Job INNER JOIN
   dbo.T_Dataset ON 
   dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER
    JOIN
   dbo.T_Organisms ON 
   dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID
    INNER JOIN
   dbo.t_storage_path ON 
   dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID
    INNER JOIN
   dbo.T_Analysis_Tool ON 
   dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID
    INNER JOIN
   dbo.T_Analysis_State_Name ON 
   dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID



GO
