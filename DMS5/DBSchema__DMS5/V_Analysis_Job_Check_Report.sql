/****** Object:  View [dbo].[V_Analysis_Job_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Check_Report
AS
SELECT     
	CONVERT(varchar(32), T_Analysis_Job.AJ_jobID) AS Job,
	T_Analysis_State_Name.AJS_name AS State,
	T_Analysis_Job.AJ_start AS Started,
	T_Analysis_Job.AJ_finish AS Finished,
	ISNULL(DATEDIFF(hour,
	T_Analysis_Job.AJ_start, GETDATE()), 0) AS Elapsed,
	ISNULL(T_Analysis_Job.AJ_assignedProcessorName,'(none)') AS CPU,
	T_Analysis_Job.AJ_priority AS [Pri.],
	T_Analysis_Tool.AJT_toolName AS [Tool Name],
	T_Dataset.Dataset_Num AS Dataset,
	t_storage_path.SP_machine_name AS Storage,
	t_storage_path.SP_path AS Path,
	T_Analysis_Job.AJ_parmFileName AS [Parm File],
	T_Analysis_Job.AJ_settingsFileName AS [Settings File],
	T_Organisms.OG_name AS Organism,
	T_Analysis_Job.AJ_organismDBName AS [Organism DB],
  T_Analysis_Job.AJ_proteinCollectionList AS [Protein Collection List], 
  T_Analysis_Job.AJ_proteinOptionsList AS [Protein Options], 
	T_Analysis_Job.AJ_comment AS Comment,
	ISNULL(T_Analysis_Job.AJ_resultsFolderName,'(none)') AS [Results Folder],
	T_Analysis_Job.AJ_batchID AS Batch
FROM         T_Analysis_Job INNER JOIN
                      T_Dataset ON T_Analysis_Job.AJ_datasetID = T_Dataset.Dataset_ID INNER JOIN
                      T_Organisms ON T_Analysis_Job.AJ_organismID = T_Organisms.Organism_ID INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
                      T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID INNER JOIN
                      T_Analysis_State_Name ON T_Analysis_Job.AJ_StateID = T_Analysis_State_Name.AJS_stateID
WHERE     (NOT (T_Analysis_Job.AJ_StateID IN (1, 4)))



GO
