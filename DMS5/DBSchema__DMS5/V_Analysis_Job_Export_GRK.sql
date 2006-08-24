/****** Object:  View [dbo].[V_Analysis_Job_Export_GRK] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Export_GRK
AS
SELECT     
	T_Analysis_Job.AJ_jobID AS Job,
	T_Dataset.Dataset_Num AS Dataset,
	T_Experiments.Experiment_Num AS Experiment,
	T_Campaign.Campaign_Num AS Campaign,
	T_Analysis_Job.AJ_datasetID AS DatasetID,
	T_Experiments.EX_organism_name AS Organism,
	T_Instrument_Name.IN_class AS InstrumentClass,
	T_Analysis_Tool.AJT_toolName AS AnalysisTool,
	T_Analysis_Job.AJ_finish AS Completed,
	T_Analysis_Job.AJ_parmFileName AS ParameterFileName,
	T_Analysis_Job.AJ_settingsFileName AS SettingsFileName,
	T_Analysis_Job.AJ_organismDBName AS OrganismDBName,
	dbo.T_Analysis_Job.AJ_proteinCollectionList AS [ProteinCollectionList], 
	dbo.T_Analysis_Job.AJ_proteinOptionsList AS [ProteinOptions], 
	t_storage_path.SP_vol_name_client AS VolClient,
	t_storage_path.SP_vol_name_server AS VolServer,
	t_storage_path.SP_path AS StoragePath,
	T_Dataset.DS_folder_name AS DatasetFolder,
	T_Analysis_Job.AJ_resultsFolderName AS ResultsFolder
FROM         T_Analysis_Job INNER JOIN
                      T_Dataset ON T_Analysis_Job.AJ_datasetID = T_Dataset.Dataset_ID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
                      t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
                      T_Experiments ON T_Dataset.Exp_ID = T_Experiments.Exp_ID INNER JOIN
                      T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID INNER JOIN
                      T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
WHERE     (T_Analysis_Job.AJ_StateID = 5) AND (T_Dataset.DS_rating > 1) AND (T_Instrument_Name.IN_class = 'QTOF') AND 
                      (T_Campaign.Campaign_Num = 'Shewanella')



GO
