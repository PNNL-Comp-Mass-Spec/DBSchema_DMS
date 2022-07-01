/****** Object:  View [dbo].[V_Data_Extraction_Task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Data_Extraction_Task
AS
SELECT CONVERT(varchar(32), A.AJ_jobID) AS TaskNum,
       T.AJT_toolName AS ToolName,
       D.Dataset_Num AS DatasetNum,
       D.DS_folder_name AS DatasetFolderName,
       S.SP_vol_name_client + S.SP_path AS DatasetStoragePath,
       A.AJ_parmFileName AS ParamFileName,
       A.AJ_settingsFileName AS SettingsFileName,
       T.AJT_parmFileStoragePath AS ParamFileStoragePath,
       A.AJ_organismDBName AS OrganismDBName,
       O.OG_organismDBPath AS OrganismDBStoragePath,
       A.AJ_StateID AS StateID,
       A.AJ_jobID AS jobID,
       A.AJ_priority AS priority,
       A.AJ_comment AS Comment,
       D.DS_Comp_State AS CompState,
       I.IN_class AS InstClass,
       S.SP_vol_name_client AS StorageServerPath,
       A.AJ_datasetID AS DatasetID,
       A.AJ_assignedProcessorName AS AssignedProcessor,
       A.AJ_resultsFolderName AS ResultsFolderName,
       T.AJT_resultType AS toolResultType,
       DAS.DASN_StateName AS ArchiveState
FROM T_Analysis_Job A
     INNER JOIN T_Dataset D
       ON A.AJ_datasetID = D.Dataset_ID
     INNER JOIN T_Organisms O
       ON A.AJ_organismID = O.Organism_ID
     INNER JOIN t_storage_path S
       ON D.DS_storage_path_ID = S.SP_path_ID
     INNER JOIN T_Analysis_Tool T
       ON A.AJ_analysisToolID = T.AJT_toolID
     INNER JOIN T_Instrument_Name I
       ON D.DS_instrument_name_ID = I.Instrument_ID
     INNER JOIN T_Dataset_Archive DA
       ON A.AJ_DatasetID = DA.AS_Dataset_ID
     INNER JOIN T_DatasetArchiveStateName DAS
       ON DA.AS_state_ID = DAS.DASN_StateID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Extraction_Task] TO [DDL_Viewer] AS [dbo]
GO
