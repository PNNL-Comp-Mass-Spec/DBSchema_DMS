/****** Object:  View [dbo].[V_Analysis_Job_ReportEx] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_ReportEx]
AS
SELECT     CONVERT(varchar(32), dbo.T_Analysis_Job.AJ_jobID) AS JobNum, dbo.T_Dataset.Dataset_Num AS Dataset, 
                      dbo.T_Dataset.DS_folder_name AS [Dataset Folder], dbo.V_Dataset_Folder_Paths.Dataset_Folder_Path AS [Dataset Folder Path], 
                      dbo.V_Dataset_Folder_Paths.Archive_Folder_Path AS [Archive Folder Path], dbo.T_Instrument_Name.IN_name AS Instrument, 
                      dbo.T_Analysis_Tool.AJT_toolName AS [Tool Name], dbo.T_Analysis_Job.AJ_parmFileName AS [Parm File], 
                      dbo.T_Analysis_Tool.AJT_parmFileStoragePath AS [Parm File Storage Path], dbo.T_Analysis_Job.AJ_settingsFileName AS [Settings File], 
                      dbo.T_Organisms.OG_name AS Organism, dbo.T_Analysis_Job.AJ_organismDBName AS [Organism DB], 
                      dbo.GetFASTAFilePath(dbo.T_Analysis_Job.AJ_organismDBName, dbo.T_Organisms.OG_name) AS [Organism DB Storage Path], 
                      dbo.T_Analysis_Job.AJ_proteinCollectionList AS [Protein Collection List], dbo.T_Analysis_Job.AJ_proteinOptionsList AS [Protein Options List], 
                      dbo.T_Analysis_State_Name.AJS_name AS State, dbo.T_Analysis_Job.AJ_owner AS Owner, dbo.T_Analysis_Job.AJ_priority AS Priority, 
                      dbo.T_Analysis_Job.AJ_comment AS Comment, dbo.T_Analysis_Job.AJ_assignedProcessorName AS [Assigned Processor], 
                      dbo.T_Analysis_Job.AJ_extractionProcessor AS [DEX Processor], dbo.T_Analysis_Job_Processor_Group_Associations.Group_ID, 
                      dbo.T_Analysis_Job_Processor_Group.Group_Name, 
                      dbo.V_Dataset_Folder_Paths.Dataset_Folder_Path + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName AS [Results Folder Path], 
                      dbo.V_Dataset_Folder_Paths.Archive_Folder_Path + '\' + dbo.T_Analysis_Job.AJ_resultsFolderName AS [Archive Results Folder Path], 
                      dbo.T_Analysis_Job.AJ_created AS Created, dbo.T_Analysis_Job.AJ_start AS Started, dbo.T_Analysis_Job.AJ_finish AS Finished, 
                      dbo.T_Analysis_Job.AJ_requestID AS Request, dbo.T_Analysis_Job.AJ_Analysis_Manager_Error AS [AM Code], 
                      dbo.GetDEMCodeString(dbo.T_Analysis_Job.AJ_Data_Extraction_Error) AS [DEM Code], 
                      CASE dbo.T_Analysis_Job.AJ_propagationMode WHEN 0 THEN 'Export' ELSE 'No Export' END AS [Export Mode]
FROM         dbo.T_Analysis_Job_Processor_Group INNER JOIN
                      dbo.T_Analysis_Job_Processor_Group_Associations ON 
                      dbo.T_Analysis_Job_Processor_Group.ID = dbo.T_Analysis_Job_Processor_Group_Associations.Group_ID RIGHT OUTER JOIN
                      dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID INNER JOIN
                      dbo.V_Dataset_Folder_Paths ON dbo.V_Dataset_Folder_Paths.Dataset_ID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Analysis_State_Name ON dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID ON 
                      dbo.T_Analysis_Job_Processor_Group_Associations.Job_ID = dbo.T_Analysis_Job.AJ_jobID

GO
