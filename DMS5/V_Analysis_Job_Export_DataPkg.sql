/****** Object:  View [dbo].[V_Analysis_Job_Export_DataPkg] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Export_DataPkg]
AS
/*
** This view is used by V_DMS_Data_Package_Aggregation_Jobs in the DMS_Data_Package database
** It is also used by LookupJobInfo in the DMS Analysis Manager
**
*/
SELECT AJ.AJ_jobID AS Job,
       AnalysisTool.AJT_toolName AS Tool,
       DS.Dataset_Num AS Dataset,
       DSArch.Archive_Path + '\' AS ArchiveStoragePath,
       dbo.udfCombinePaths(SP.SP_vol_name_client, SP.SP_path) AS ServerStoragePath,
       DS.DS_folder_name AS DatasetFolder,
       AJ.AJ_resultsFolderName AS ResultsFolder,
       AJ.AJ_datasetID AS DatasetID,
       Org.Name AS Organism,
       InstName.IN_name AS InstrumentName,
       InstName.IN_Group as InstrumentGroup,
       InstName.IN_class AS InstrumentClass,
       AJ.AJ_finish AS Completed,
       AJ.AJ_parmFileName AS ParameterFileName,
       AJ.AJ_settingsFileName AS SettingsFileName,
       AJ.AJ_organismDBName AS OrganismDBName,
       AJ.AJ_proteinCollectionList AS ProteinCollectionList,
       AJ.AJ_proteinOptionsList AS ProteinOptions,
       AnalysisTool.AJT_resultType AS ResultType,
       DS.DS_created,
       InstClass.raw_data_type as RawDataType,
       E.Experiment_Num AS Experiment,
       E.EX_reason AS Experiment_Reason,
       E.EX_comment AS Experiment_Comment,
       Org.NEWT_ID AS Experiment_NEWT_ID,
       Org.NEWT_Name AS Experiment_NEWT_Name
FROM T_Analysis_Job AS AJ
     INNER JOIN T_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Instrument_Class AS InstClass 
       ON InstName.IN_class = InstClass.IN_class
     INNER JOIN T_Storage_Path AS SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
     INNER JOIN T_Experiments AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Analysis_Tool AS AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN V_Organism_Export AS Org
       ON E.EX_organism_ID = Org.Organism_ID     
     INNER JOIN V_Dataset_Archive_Path AS DSArch
       ON DS.Dataset_ID = DSArch.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Export_DataPkg] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Export_DataPkg] TO [PNL\D3M580] AS [dbo]
GO
