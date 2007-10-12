/****** Object:  View [dbo].[V_GPM_Analysis_Job_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GPM_Analysis_Job_Report]
AS
SELECT     
	CONVERT(varchar(32), T_Analysis_Job.AJ_jobID) AS Job,
	T_Analysis_State_Name.AJS_name AS State,
	'http://' + t_storage_path.SP_machine_name + '/thegpm-cgi/dms2gpm.pl?job='+ CONVERT(varchar(32), T_Analysis_Job.AJ_jobID) + '&storage=' + t_storage_path.SP_vol_name_server + t_storage_path.SP_path + T_Dataset.DS_folder_name + '\' + T_Analysis_Job.AJ_resultsFolderName + '\&file=' + T_Dataset.Dataset_Num + '_xt.zip' AS [GPM Path],
	t_storage_path.SP_machine_name as [Storage],
	T_Dataset.Dataset_Num AS Dataset,
	t_storage_path.SP_instrument_name AS Instrument,
	T_Analysis_Tool.AJT_toolName AS [Tool Name],
	T_Analysis_Job.AJ_parmFileName AS [Parm File],
	T_Analysis_Job.AJ_settingsFileName AS [Settings File],
	T_Organisms.OG_name AS Organism,
	T_Analysis_Job.AJ_organismDBName AS [Organism DB],
	T_Analysis_Job.AJ_proteinCollectionList AS [ProteinCollectionList], 
	T_Analysis_Job.AJ_proteinOptionsList AS [ProteinOptions], 
	T_Analysis_Job.AJ_owner AS Owner,
	T_Analysis_Job.AJ_priority AS Priority,
	CONVERT(char(32), T_Analysis_Job.AJ_comment) AS Comment,
	T_Analysis_Job.AJ_assignedProcessorName AS [Assigned Processor],
	T_Analysis_Job.AJ_created AS Created,
	T_Analysis_Job.AJ_start AS Started,
	T_Analysis_Job.AJ_finish AS Finished,
	T_Analysis_Job.AJ_requestID AS Request
FROM         
T_Analysis_Job INNER JOIN
T_Dataset ON T_Analysis_Job.AJ_datasetID = T_Dataset.Dataset_ID INNER JOIN
T_Organisms ON T_Analysis_Job.AJ_organismID = T_Organisms.Organism_ID INNER JOIN
t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID INNER JOIN
T_Analysis_State_Name ON T_Analysis_Job.AJ_StateID = T_Analysis_State_Name.AJS_stateID 
WHERE     (T_Analysis_Tool.AJT_toolName = 'XTandem')

GO
