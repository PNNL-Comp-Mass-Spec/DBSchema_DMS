/****** Object:  View [dbo].[V_PDE_Analysis_Jobs_Ext] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_PDE_Analysis_Jobs_Ext]
AS
SELECT AJ.AJ_jobID AS AnalysisID,
       DS.Dataset_Num AS DatasetName,
       E.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       AJ.AJ_finish AS Completed,
       AJ.AJ_parmFileName AS ParamFileUsed,
       Org.OG_name AS Organism,
       AJ.AJ_organismDBName AS OrganismDatabaseUsed,
       AJ.AJ_proteinCollectionList AS ProteinCollectionsUsed,
       AJ.AJ_proteinOptionsList AS ProteinCollectionOptions,
       DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName + '\' AS AnalysisJobPath,
       InstName.IN_name AS InstrumentName,
       AJ.AJ_requestID AS AnalysisJobRequestID,
       AJR.AJR_requestName AS AnalysisJobRequestName,
       DFP.Archive_Folder_Path + '\' + AJ.AJ_resultsFolderName + '\' AS AnalysisJobArchivePath
FROM T_Analysis_Job AJ
     INNER JOIN T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Analysis_Tool AnTool
       ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Analysis_Job_Request AJR
       ON AJ.AJ_requestID = AJR.AJR_requestID
     INNER JOIN T_Organisms Org
       ON AJ.AJ_organismID = Org.Organism_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
WHERE (AJ.AJ_StateID = 4) AND
      (AnTool.AJT_toolName LIKE '%sequest%')

GO
GRANT VIEW DEFINITION ON [dbo].[V_PDE_Analysis_Jobs_Ext] TO [PNL\D3M578] AS [dbo]
GO
