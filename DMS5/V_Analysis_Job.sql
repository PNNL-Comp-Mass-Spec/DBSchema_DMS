/****** Object:  View [dbo].[V_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Analysis_Job]
AS
SELECT AJ.AJ_jobID AS Job,
       AnTool.AJT_toolName AS Tool,
       DS.Dataset_Num AS Dataset,
       DFP.Dataset_Folder_Path AS Dataset_Storage_Path,
	   DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName As Results_Folder_Path,
       AJ.AJ_parmFileName AS ParmFileName,
       AJ.AJ_settingsFileName AS SettingsFileName,
       AnTool.AJT_parmFileStoragePath AS ParmFileStoragePath,
       AJ.AJ_organismDBName AS OrganismDBName,
       AJ.AJ_proteinCollectionList AS ProteinCollectionList,
       AJ.AJ_proteinOptionsList AS ProteinOptions,
       O.OG_organismDBPath AS OrganismDBStoragePath,
       AJ.AJ_StateID AS StateID,
       AJ.AJ_priority AS priority,
       AJ.AJ_comment AS [Comment],
       DS.DS_Comp_State AS CompState,
       InstName.IN_class AS InstClass,
       AJ.AJ_datasetID AS DatasetID,
       AJ.AJ_requestID AS RequestID,
       DFP.Archive_Folder_Path,
       DFP.MyEMSL_Path_Flag,
       DFP.Instrument_Data_Purged,
	   E.Experiment_Num As Experiment,
	   C.Campaign_Num As Campaign,
	   InstName.IN_name AS Instrument,
	   AJ.AJ_StateNameCached AS State,
	   AJ.AJ_jobID,
	   AJ.AJ_datasetID,
	   DS.DS_rating AS Rating,
       AJ.AJ_created AS Created,
       AJ.AJ_start AS Started,
       AJ.AJ_finish AS Finished,
	   CONVERT(DECIMAL(9, 2), AJ.AJ_ProcessingTimeMinutes) AS Runtime,
	   AJ.AJ_specialProcessing AS SpecialProcessing,
	   AJ.AJ_batchID
FROM T_Analysis_Job AJ
     INNER JOIN T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Organisms O
       ON AJ.AJ_organismID = O.Organism_ID
     INNER JOIN T_Analysis_Tool AnTool
       ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID



GO
GRANT DELETE ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_Analysis_Job] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job] TO [PNL\D3M578] AS [dbo]
GO
