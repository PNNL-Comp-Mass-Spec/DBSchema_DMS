/****** Object:  View [dbo].[V_Analysis_Job_Export_PDE] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Export_PDE]
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS Job, dbo.T_Analysis_Job.AJ_priority AS Priority, dbo.T_Dataset.Dataset_Num AS Dataset, 
                      dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Analysis_Job.AJ_datasetID AS DatasetID, 
                      dbo.T_Organisms.OG_name AS Organism, dbo.T_Instrument_Name.IN_class AS InstrumentClass, 
                      dbo.T_Analysis_Tool.AJT_toolName AS AnalysisTool, dbo.T_Analysis_Job.AJ_finish AS Completed, 
                      dbo.T_Analysis_Job.AJ_parmFileName AS ParameterFileName, dbo.T_Analysis_Job.AJ_settingsFileName AS SettingsFileName, 
                      dbo.T_Analysis_Job.AJ_organismDBName AS OrganismDBName, dbo.T_Analysis_Job.AJ_proteinCollectionList AS ProteinCollectionList, 
                      dbo.T_Analysis_Job.AJ_proteinOptionsList AS ProteinOptions, dbo.t_storage_path.SP_vol_name_client AS VolClient, 
                      dbo.t_storage_path.SP_vol_name_server AS VolServer, dbo.t_storage_path.SP_path AS StoragePath, 
                      dbo.T_Dataset.DS_folder_name AS DatasetFolder, dbo.T_Analysis_Job.AJ_resultsFolderName AS ResultsFolder, 
                      dbo.T_Analysis_Job.AJ_owner AS Owner, dbo.T_Analysis_Job.AJ_comment AS Comment, dbo.T_Dataset.DS_created AS DatasetCompleted, 
                      dbo.T_Analysis_Job.AJ_organismID AS OrganismID, dbo.T_Experiments.Exp_ID AS ExperimentID, dbo.T_Analysis_Job.AJ_batchID AS BatchNumber, 
                      dbo.T_Instrument_Name.IN_name AS InstrumentName
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID
WHERE     (dbo.T_Analysis_Job.AJ_StateID = 4) AND (dbo.T_Analysis_Tool.AJT_toolName LIKE '%sequest%')

GO
