/****** Object:  View [dbo].[V_EUS_Export_DataPackageJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Export_DataPackageJobs]
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
       DP.ID AS Data_Package_ID,
       DP.Name AS Data_Package_Name,
       dbo.udfCombinePaths('\\aurora.emsl.pnl.gov\archive\prismarch\DataPkgs', DP.Storage_Path_Relative) AS 
         Data_Package_Path_Aurora
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
     LEFT OUTER JOIN S_V_Data_Package_Analysis_Jobs_Export DPJ
       ON AJ.AJ_jobID = DPJ.Job
     INNER JOIN S_V_Data_Package_Export DP
       ON DP.ID = DPJ.Data_Package_ID
WHERE (AJ.AJ_StateID = 4)


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Export_DataPackageJobs] TO [DDL_Viewer] AS [dbo]
GO
