/****** Object:  View [dbo].[V_Analysis_Job_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Export]
AS
SELECT AJ.AJ_jobID AS Job, DS.Dataset_Num AS Dataset, 
    Exp.Experiment_Num AS Experiment, 
    Campaign.Campaign_Num AS Campaign, 
    AJ.AJ_datasetID AS DatasetID, Org.OG_name AS Organism, 
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
    dbo.combine_paths(SP.SP_vol_name_client, SP.SP_path) 
    AS StoragePathServer, DS.DS_folder_name AS DatasetFolder, 
    AJ.AJ_resultsFolderName AS ResultsFolder, 
    DS.DS_sec_sep AS SeparationSysType, 
    AnalysisTool.AJT_resultType AS ResultType, DS.DS_created, 
    Exp.EX_enzyme_ID AS EnzymeID
FROM dbo.T_Analysis_Job AJ INNER JOIN
    dbo.T_Dataset DS ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
    dbo.T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN
    dbo.t_storage_path SP ON DS.DS_storage_path_ID = SP.SP_path_ID INNER JOIN
    dbo.T_Experiments Exp ON DS.Exp_ID = Exp.Exp_ID INNER JOIN
    dbo.T_Analysis_Tool AnalysisTool ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID INNER JOIN
    dbo.T_Campaign Campaign ON Exp.EX_campaign_ID = Campaign.Campaign_ID INNER JOIN
    dbo.T_Organisms Org ON Exp.EX_organism_ID = Org.Organism_ID INNER JOIN
    dbo.V_Dataset_Archive_Path DSArch ON DS.Dataset_ID = DSArch.Dataset_ID
WHERE (AJ.AJ_StateID = 4) AND
      (DS.DS_rating >= 1 OR 
       -- Include datasets with rating "Rerun (Good Data)"
       DS.DS_rating = -6)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Export] TO [DDL_Viewer] AS [dbo]
GO
