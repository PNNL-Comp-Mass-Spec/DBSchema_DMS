/****** Object:  View [dbo].[V_EUS_Export_JobMetadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EUS_Export_JobMetadata
AS
SELECT D.Dataset_ID AS Dataset_ID,
       D.Dataset_Num AS Dataset,
       Inst.IN_name AS Instrument,
       DTN.DST_name AS Dataset_Type,
       DSN.DSS_name AS Dataset_State,
       DRN.DRN_name AS Dataset_Rating,
       E.Experiment_Num AS Experiment,
       O.OG_name AS Organism,
       AJ.AJ_jobID AS Analysis_Job,
       AnTool.AJT_toolName AS Analysis_Tool,
       AnTool.AJT_resultType AS Analysis_Result_Type,
       AJ.AJ_proteinCollectionList AS Protein_Collection_List,
       AJ.AJ_resultsFolderName AS Analysis_Job_Results_Folder,
       dbo.udfCombinePaths(V_Dataset_Folder_Paths.Archive_Folder_Path, AJ.AJ_resultsFolderName) AS 
         Folder_Path_Aurora
FROM T_Dataset D
     INNER JOIN T_Instrument_Name Inst
       ON D.DS_instrument_name_ID = Inst.Instrument_ID
     INNER JOIN T_DatasetTypeName DTN
       ON D.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_DatasetStateName DSN
       ON D.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN T_DatasetRatingName DRN
       ON D.DS_rating = DRN.DRN_state_ID
     INNER JOIN T_Experiments E
       ON D.Exp_ID = E.Exp_ID
     INNER JOIN T_Organisms O
       ON E.EX_organism_ID = O.Organism_ID
     INNER JOIN T_Analysis_Job AJ
       ON D.Dataset_ID = AJ.AJ_datasetID
     INNER JOIN T_Analysis_Tool AnTool
       ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
     INNER JOIN V_Dataset_Folder_Paths
       ON D.Dataset_ID = V_Dataset_Folder_Paths.Dataset_ID
WHERE (AJ.AJ_StateID = 4)

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Export_JobMetadata] TO [DDL_Viewer] AS [dbo]
GO
