/****** Object:  View [dbo].[V_Analysis_Request_Jobs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Request_Jobs_List_Report
AS
SELECT
	T_Analysis_Job.AJ_jobID AS Job,
	T_Analysis_Job.AJ_priority AS [Pri.],
	T_Analysis_State_Name.AJS_name AS State,
	T_Analysis_Tool.AJT_toolName AS [Tool Name],
	T_Dataset.Dataset_Num AS Dataset,
	T_Analysis_Job.AJ_parmFileName AS [Parm File],
	T_Analysis_Job.AJ_settingsFileName AS [Settings File],
	T_Organisms.OG_name AS Organism,
	T_Analysis_Job.AJ_organismDBName AS [Organism DB],
	T_Analysis_Job.AJ_proteinCollectionList AS [ProteinCollectionList], 
	T_Analysis_Job.AJ_proteinOptionsList AS [ProteinOptions], 
	T_Analysis_Job.AJ_comment AS Comment,
	T_Analysis_Job.AJ_created AS Created,
	T_Analysis_Job.AJ_start AS Started,
	T_Analysis_Job.AJ_finish AS Finished,
	ISNULL(T_Analysis_Job.AJ_assignedProcessorName,
	'(none)') AS CPU,
	T_Analysis_Job.AJ_batchID AS Batch,
	T_Analysis_Job.AJ_requestID AS [#ReqestID]
FROM
	T_Analysis_Job INNER JOIN
	T_Dataset ON T_Analysis_Job.AJ_datasetID = T_Dataset.Dataset_ID INNER JOIN
	T_Organisms ON T_Analysis_Job.AJ_organismID = T_Organisms.Organism_ID INNER JOIN
	T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID INNER JOIN
	T_Analysis_State_Name ON T_Analysis_Job.AJ_StateID = T_Analysis_State_Name.AJS_stateID


GO
