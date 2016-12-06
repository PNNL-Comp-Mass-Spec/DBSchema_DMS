/****** Object:  View [dbo].[V_Analysis_For_Delete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_For_Delete]
AS
SELECT dbo.T_Analysis_Job.AJ_jobID AS Job,
	dbo.T_Dataset.Dataset_Num AS Dataset,
	dbo.T_Analysis_Tool.AJT_toolName AS Tool,
	dbo.T_Organisms.OG_name AS Org,
	dbo.T_Analysis_Job.AJ_comment AS Comment,
	dbo.T_Analysis_Job.AJ_batchID AS Batch,
	dbo.T_Dataset.DS_folder_name AS DS_Folder,
	dbo.t_storage_path.SP_path AS Stor_Path,
	dbo.t_storage_path.SP_vol_name_client AS Vol_Name,
	dbo.T_Analysis_Job.AJ_resultsFolderName AS Res_Folder,
	dbo.T_Analysis_State_Name.AJS_name AS State,
	dbo.T_Analysis_Job.AJ_organismDBName AS Org_DBName,
dbo.T_Analysis_Job.AJ_proteinCollectionList AS [Prot_Coll], 
dbo.T_Analysis_Job.AJ_proteinOptionsList AS [Prot_Opts], 
	dbo.T_Experiments.Experiment_Num AS Experiment
FROM  dbo.T_Analysis_Job INNER JOIN
               dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
               dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
               dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
               dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
               dbo.T_Analysis_State_Name ON dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID INNER JOIN
               dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_For_Delete] TO [DDL_Viewer] AS [dbo]
GO
