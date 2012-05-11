/****** Object:  View [dbo].[V_Mage_Analysis_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mage_Analysis_Jobs]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_StateNameCached AS State,
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
           WHEN AJ.AJ_Purged = 0 THEN ISNULL(SPath.SP_vol_name_client + SPath.SP_path +
                                             ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName, '')
           ELSE ISNULL(DAP.Archive_Path + '\' + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '\' + AJ.AJ_resultsFolderName, '')
       END AS Folder,
       DS.DS_created AS Dataset_Created,
       AJ.AJ_finish AS Job_Finish
FROM dbo.V_Dataset_Archive_Path AS DAP
     RIGHT OUTER JOIN dbo.T_Analysis_Job AS AJ
                      INNER JOIN dbo.T_Dataset AS DS
                        ON AJ.AJ_datasetID = DS.Dataset_ID
                      INNER JOIN dbo.T_Organisms AS Org
                        ON AJ.AJ_organismID = Org.Organism_ID
                      INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool
                        ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
                      INNER JOIN dbo.T_Instrument_Name AS InstName
                        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                      INNER JOIN dbo.T_Experiments AS E
                        ON DS.Exp_ID = E.Exp_ID
                      INNER JOIN dbo.T_Campaign AS C
                        ON E.EX_campaign_ID = C.Campaign_ID
       ON DAP.Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_Storage_Path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID


GO
