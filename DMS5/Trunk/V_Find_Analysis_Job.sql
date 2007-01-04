/****** Object:  View [dbo].[V_Find_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Find_Analysis_Job
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS Job, dbo.T_Analysis_Job.AJ_priority AS Pri, dbo.V_Analysis_Job_and_Dataset_Archive_State.Job_State AS State, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Tool, dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Campaign.Campaign_Num AS Campaign, 
                      dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Instrument_Name.IN_name AS Instrument, 
                      dbo.T_Analysis_Job.AJ_parmFileName AS Parm_File, dbo.T_Analysis_Job.AJ_settingsFileName AS Settings_File, 
                      dbo.T_Organisms.OG_name AS Organism, dbo.T_Analysis_Job.AJ_organismDBName AS Organism_DB, 
                      dbo.T_Analysis_Job.AJ_proteinCollectionList AS ProteinCollection_List, dbo.T_Analysis_Job.AJ_proteinOptionsList AS Protein_Options, 
                      dbo.T_Analysis_Job.AJ_comment AS Comment, dbo.T_Analysis_Job.AJ_created AS Created, dbo.T_Analysis_Job.AJ_start AS Started, 
                      dbo.T_Analysis_Job.AJ_finish AS Finished, ISNULL(dbo.T_Analysis_Job.AJ_assignedProcessorName, '(none)') AS Processor, 
                      dbo.T_Analysis_Job.AJ_requestID AS Run_Request, 
                      dbo.V_Dataset_Folder_Paths.Archive_Folder_Path + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName AS [Archive Folder Path]
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.V_Analysis_Job_and_Dataset_Archive_State ON 
                      dbo.T_Analysis_Job.AJ_jobID = dbo.V_Analysis_Job_and_Dataset_Archive_State.Job LEFT OUTER JOIN
                      dbo.V_Dataset_Folder_Paths ON dbo.T_Dataset.Dataset_ID = dbo.V_Dataset_Folder_Paths.Dataset_ID

GO
