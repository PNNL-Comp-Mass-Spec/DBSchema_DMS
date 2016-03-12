/****** Object:  View [dbo].[V_PDE_All_Completed_Analysis_Jobs_Ext] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_PDE_All_Completed_Analysis_Jobs_Ext]
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS AnalysisID, dbo.T_Dataset.Dataset_Num AS DatasetName, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Analysis_Job.AJ_finish AS Completed, 
                      dbo.T_Analysis_Job.AJ_parmFileName AS ParamFileUsed, dbo.T_Organisms.OG_name AS Organism, 
                      dbo.T_Analysis_Job.AJ_organismDBName AS OrganismDatabaseUsed, dbo.T_Analysis_Job.AJ_proteinCollectionList AS ProteinCollectionsUsed, 
                      dbo.T_Analysis_Job.AJ_proteinOptionsList AS ProteinCollectionOptions, 
                      dbo.V_Dataset_Folder_Paths.Dataset_Folder_Path + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName + '\' AS AnalysisJobPath, 
                      dbo.T_Instrument_Name.IN_name AS InstrumentName, dbo.T_Analysis_Job.AJ_requestID AS AnalysisJobRequestID, 
                      dbo.T_Analysis_Job_Request.AJR_requestName AS AnalysisJobRequestName, 
                      dbo.V_Dataset_Folder_Paths.Archive_Folder_Path + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName + '\' AS AnalysisJobArchivePath
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Analysis_Job_Request ON dbo.T_Analysis_Job.AJ_requestID = dbo.T_Analysis_Job_Request.AJR_requestID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.V_Dataset_Folder_Paths ON dbo.T_Dataset.Dataset_ID = dbo.V_Dataset_Folder_Paths.Dataset_ID
WHERE     (dbo.T_Analysis_Job.AJ_StateID = 4) AND (dbo.T_Dataset.DS_rating > 1)


GO
GRANT VIEW DEFINITION ON [dbo].[V_PDE_All_Completed_Analysis_Jobs_Ext] TO [PNL\D3M578] AS [dbo]
GO
