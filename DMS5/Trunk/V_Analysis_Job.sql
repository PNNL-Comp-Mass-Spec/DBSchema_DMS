/****** Object:  View [dbo].[V_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job]
AS
SELECT
	CONVERT(varchar(32), T_Analysis_Job.AJ_jobID) AS JobNum,
	T_Analysis_Tool.AJT_toolName AS ToolName,
	T_Dataset.Dataset_Num AS DatasetNum,
	T_Dataset.DS_folder_name AS DatasetFolderName,
	t_storage_path.SP_vol_name_client + t_storage_path.SP_path AS DatasetStoragePath,
	T_Analysis_Job.AJ_parmFileName AS ParmFileName,
	T_Analysis_Job.AJ_settingsFileName AS SettingsFileName,
	T_Analysis_Tool.AJT_parmFileStoragePath AS ParmFileStoragePath,
	T_Analysis_Job.AJ_organismDBName AS OrganismDBName,
  T_Analysis_Job.AJ_proteinCollectionList AS [ProteinCollectionList], 
  T_Analysis_Job.AJ_proteinOptionsList AS [ProteinOptions], 
	T_Organisms.OG_organismDBPath AS OrganismDBStoragePath,
	T_Analysis_Job.AJ_StateID AS StateID,
	T_Analysis_Job.AJ_jobID AS jobID,
	T_Analysis_Job.AJ_priority AS priority,
	T_Analysis_Job.AJ_comment AS Comment,
	T_Dataset.DS_Comp_State AS CompState,
	T_Instrument_Name.IN_class AS InstClass,
	t_storage_path.SP_vol_name_client AS StorageServerPath,
	T_Analysis_Job.AJ_datasetID AS DatasetID, 
	T_Analysis_Job.AJ_assignedProcessorName AS AssignedProcessor
FROM 
T_Analysis_Job INNER JOIN
                      T_Dataset ON T_Analysis_Job.AJ_datasetID = T_Dataset.Dataset_ID INNER JOIN
                      T_Organisms ON T_Analysis_Job.AJ_organismID = T_Organisms.Organism_ID INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
                      T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID

GO
GRANT DELETE ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job] TO [PNL\D3M580] AS [dbo]
GO
