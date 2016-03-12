/****** Object:  View [dbo].[V_Analysis_Job_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Ex]
AS
SELECT CONVERT(varchar(32), dbo.T_Analysis_Job.AJ_jobID) 
	AS JobNum, dbo.T_Analysis_Tool.AJT_toolName AS ToolName, 
	dbo.T_Dataset.Dataset_Num AS DatasetNum, 
	dbo.T_Dataset.DS_folder_name AS DatasetFolderName, 
	dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path AS DatasetStoragePath, 
	dbo.T_Analysis_Job.AJ_parmFileName AS ParmFileName, 
	dbo.T_Analysis_Job.AJ_settingsFileName AS SettingsFileName, 
	dbo.T_Analysis_Tool.AJT_parmFileStoragePath AS ParmFileStoragePath,
	dbo.T_Analysis_Job.AJ_organismDBName AS OrganismDBName,
	dbo.T_Analysis_Job.AJ_proteinCollectionList AS [ProteinCollectionList], 
	dbo.T_Analysis_Job.AJ_proteinOptionsList AS [ProteinOptions], 
	dbo.T_Organisms.OG_organismDBPath AS OrganismDBStoragePath,
	dbo.T_Analysis_Job.AJ_StateID AS StateID, 
	dbo.T_Analysis_Job.AJ_jobID AS jobID, 
	dbo.T_Analysis_Job.AJ_priority AS priority, 
	dbo.T_Analysis_Job.AJ_comment AS Comment, 
	dbo.T_Dataset.DS_Comp_State AS CompState, 
	dbo.T_Instrument_Name.IN_class AS InstClass, 
	dbo.T_Analysis_Job.AJ_owner AS Owner
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
   dbo.T_Instrument_Name ON 
   dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Ex] TO [PNL\D3M578] AS [dbo]
GO
