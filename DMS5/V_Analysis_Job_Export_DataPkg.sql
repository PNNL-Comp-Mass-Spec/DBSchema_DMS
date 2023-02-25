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
       DSArch.Archive_Path + '\' AS Archive_Storage_Path,
       dbo.combine_paths(SP.SP_vol_name_client, SP.SP_path) AS Server_Storage_Path,
       DS.DS_folder_name AS Dataset_Folder,
       AJ.AJ_resultsFolderName AS Results_Folder,
       AJ.AJ_datasetID AS Dataset_ID,
       Org.Name AS Organism,
       InstName.IN_name AS Instrument_Name,
       InstName.IN_Group as Instrument_Group,
       InstName.IN_class AS Instrument_Class,
       AJ.AJ_finish AS Completed,
       AJ.AJ_parmFileName AS Parameter_File_Name,
       AJ.AJ_settingsFileName AS Settings_File_Name,
       AJ.AJ_organismDBName AS Organism_DB_Name,
       AJ.AJ_proteinCollectionList AS Protein_Collection_List,
       AJ.AJ_proteinOptionsList AS Protein_Options,
       AnalysisTool.AJT_resultType AS Result_Type,
       DS.DS_created AS Dataset_Created,
       InstClass.Raw_Data_Type,
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
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Export_DataPkg] TO [DDL_Viewer] AS [dbo]
GO
