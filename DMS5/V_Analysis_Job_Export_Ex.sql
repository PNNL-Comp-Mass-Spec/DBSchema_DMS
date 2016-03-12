/****** Object:  View [dbo].[V_Analysis_Job_Export_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Export_Ex]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_priority AS Priority,
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       Campaign.Campaign_Num AS Campaign,
       AJ.AJ_datasetID AS DatasetID,
       Org.OG_name AS Organism,
       InstName.IN_name AS InstrumentName,
       InstName.IN_class AS InstrumentClass,
       AnalysisTool.AJT_toolName AS AnalysisTool,
       AJ.AJ_finish AS Completed,
       AJ.AJ_parmFileName AS ParameterFileName,
       AJ.AJ_settingsFileName AS SettingsFileName,
       AJ.AJ_organismDBName AS OrganismDBName,
       AJ.AJ_proteinCollectionList AS ProteinCollectionList,
       AJ.AJ_proteinOptionsList AS ProteinOptions,
       DSArch.Archive_Path + '\' AS StoragePathClient,
       dbo.udfCombinePaths(SP.SP_vol_name_client, SP.SP_path) AS StoragePathServer,
       DS.DS_folder_name AS DatasetFolder,
       AJ.AJ_resultsFolderName AS ResultsFolder,
       AJ.AJ_owner AS Owner,
       AJ.AJ_comment AS Comment,
       DS.DS_sec_sep AS SeparationSysType,
       AnalysisTool.AJT_resultType AS ResultType,
       Dataset_Int_Std.Name AS [Dataset Int Std],
       DS.DS_created,
       CASE WHEN DS.Acq_Time_End - DS.Acq_Time_Start < 90
       THEN DATEDIFF(second, DS.Acq_Time_Start, DS.Acq_Time_End) / 60.0 
       ELSE NULL End AS DS_Acq_Length,
       E.EX_enzyme_ID AS EnzymeID,
       E.EX_Labelling AS Labelling,
       PreDigest_Int_Std.Name AS [PreDigest Int Std],
       PostDigest_Int_Std.Name AS [PostDigest Int Std],
       AJ_assignedProcessorName AS Processor,
       AJ.AJ_requestID AS RequestID,
       AJ.AJ_MyEMSLState AS MyEMSLState
FROM dbo.T_Analysis_Job AJ
     INNER JOIN dbo.T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.t_storage_path SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
     INNER JOIN dbo.T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Analysis_Tool AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN dbo.T_Campaign Campaign
       ON E.EX_campaign_ID = Campaign.Campaign_ID
     INNER JOIN dbo.T_Internal_Standards Dataset_Int_Std
       ON DS.DS_internal_standard_ID = Dataset_Int_Std.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Internal_Standards PreDigest_Int_Std
       ON E.EX_internal_standard_ID = PreDigest_Int_Std.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Internal_Standards PostDigest_Int_Std
       ON E.EX_postdigest_internal_std_ID = PostDigest_Int_Std.Internal_Std_Mix_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN dbo.V_Dataset_Archive_Path DSArch
       ON DS.Dataset_ID = DSArch.Dataset_ID
WHERE (AJ.AJ_StateID = 4) AND
      (DS.DS_rating >= 1 OR 
       -- Include datasets with rating "Rerun (Good Data)"
       DS.DS_rating = -6)



GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Export_Ex] TO [PNL\D3M578] AS [dbo]
GO
