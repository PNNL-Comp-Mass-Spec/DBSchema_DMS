/****** Object:  View [dbo].[V_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job]
AS
SELECT CONVERT(varchar(32), AJ.AJ_jobID) AS JobNum,
       AnTool.AJT_toolName AS ToolName,
       DS.Dataset_Num AS DatasetNum,
       DS.DS_folder_name AS DatasetFolderName,
       SP.SP_vol_name_client + SP.SP_path AS DatasetStoragePath,
       AJ.AJ_parmFileName AS ParmFileName,
       AJ.AJ_settingsFileName AS SettingsFileName,
       AnTool.AJT_parmFileStoragePath AS ParmFileStoragePath,
       AJ.AJ_organismDBName AS OrganismDBName,
       AJ.AJ_proteinCollectionList AS ProteinCollectionList,
       AJ.AJ_proteinOptionsList AS ProteinOptions,
       O.OG_organismDBPath AS OrganismDBStoragePath,
       AJ.AJ_StateID AS StateID,
       AJ.AJ_jobID AS jobID,
       AJ.AJ_priority AS priority,
       AJ.AJ_comment AS [Comment],
       DS.DS_Comp_State AS CompState,
       InstName.IN_class AS InstClass,
       SP.SP_vol_name_client AS StorageServerPath,
       AJ.AJ_datasetID AS DatasetID,
       AJ.AJ_assignedProcessorName AS AssignedProcessor,
       AJ.AJ_jobID AS Job,
       AJ.AJ_RequestID AS RequestID
FROM T_Analysis_Job AJ
     INNER JOIN T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Organisms O
       ON AJ.AJ_organismID = O.Organism_ID
     INNER JOIN T_Storage_Path SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
     INNER JOIN T_Analysis_Tool AnTool
       ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID




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
