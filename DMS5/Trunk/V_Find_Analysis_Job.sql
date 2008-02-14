/****** Object:  View [dbo].[V_Find_Analysis_Job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Find_Analysis_Job]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_priority AS Pri,
       AJ.AJ_StateNameCached AS State,
       AnalysisTool.AJT_toolName AS Tool,
       DS.Dataset_Num AS Dataset,
       C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       InstName.IN_name AS Instrument,
       AJ.AJ_parmFileName AS Parm_File,
       AJ.AJ_settingsFileName AS Settings_File,
       Org.OG_name AS Organism,
       AJ.AJ_organismDBName AS Organism_DB,
       AJ.AJ_proteinCollectionList AS ProteinCollection_List,
       AJ.AJ_proteinOptionsList AS Protein_Options,
       AJ.AJ_comment AS Comment,
       AJ.AJ_created AS Created,
       AJ.AJ_start AS Started,
       AJ.AJ_finish AS Finished,
       ISNULL(AJ.AJ_assignedProcessorName, '(none)') AS Processor,
       AJPG.Group_Name AS [Assoc. Proc. Group],
       AJ.AJ_requestID AS Run_Request,
       DAP.Archive_Path + '\' + DS.Dataset_Num  + '\' + AJ.AJ_resultsFolderName AS [Archive Folder Path]
FROM dbo.V_Dataset_Archive_Path AS DAP
     RIGHT OUTER JOIN dbo.T_Analysis_Job AS AJ
                      INNER JOIN dbo.T_Dataset AS DS
                        ON AJ.AJ_datasetID = DS.Dataset_ID
                      INNER JOIN dbo.T_Organisms AS Org
                        ON AJ.AJ_organismID = Org.Organism_ID
                      INNER JOIN dbo.t_storage_path AS SPath
                        ON DS.DS_storage_path_ID = SPath.SP_path_ID
                      INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool
                        ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
                      INNER JOIN dbo.T_Instrument_Name AS InstName
                        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                      INNER JOIN dbo.T_Experiments AS E
                        ON DS.Exp_ID = E.Exp_ID
                      INNER JOIN dbo.T_Campaign AS C
                        ON E.EX_campaign_ID = C.Campaign_ID
       ON DAP.Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_Analysis_Job_Processor_Group AS AJPG
                     INNER JOIN dbo.T_Analysis_Job_Processor_Group_Associations AS AJPGA
                       ON AJPG.ID = AJPGA.Group_ID
       ON AJ.AJ_jobID = AJPGA.Job_ID

GO
