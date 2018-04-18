/****** Object:  View [dbo].[V_Mage_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mage_Analysis_Jobs]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_StateNameCached AS [State],
       DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       AnalysisTool.AJT_toolName AS Tool,
       AJ.AJ_parmFileName AS Parameter_File,
       AJ.AJ_settingsFileName AS Settings_File,
       InstName.IN_name AS Instrument,
       E.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       Org.OG_name AS Organism,
       AJ.AJ_organismDBName AS [Organism DB],
       AJ.AJ_proteinCollectionList AS [Protein Collection List],
       AJ.AJ_proteinOptionsList AS [Protein Options],
       AJ.AJ_comment AS [Comment],
       ISNULL(AJ.AJ_resultsFolderName, '(none)') AS [Results Folder],
       CASE
           WHEN AJ.AJ_Purged = 0 THEN ISNULL(DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName, '')
           ELSE CASE
                    WHEN AJ.AJ_MyEMSLState >= 1 THEN ISNULL(DFP.MyEMSL_Path_Flag + '\' + AJ.AJ_resultsFolderName, '')
                    ELSE ISNULL(DFP.Archive_Folder_Path + '\' + AJ.AJ_resultsFolderName, '')
                END
       END AS Folder,
       DS.DS_created AS Dataset_Created,
       AJ.AJ_finish AS Job_Finish,
       DR.DRN_name AS Dataset_Rating,
       DS.DS_Sec_Sep AS Separation_Type,
       DTN.DST_name AS Dataset_Type,
       AJ.AJ_requestID AS Request_ID
FROM T_Analysis_Job AJ
     INNER JOIN T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Organisms Org
       ON AJ.AJ_organismID = Org.Organism_ID
     INNER JOIN T_Analysis_Tool AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Storage_Path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_DatasetRatingName DR
       ON DS.DS_rating = DR.DRN_state_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
WHERE AJ.AJ_StateID IN (4,7,14)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Analysis_Jobs] TO [DDL_Viewer] AS [dbo]
GO
