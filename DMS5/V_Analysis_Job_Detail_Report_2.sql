/****** Object:  View [dbo].[V_Analysis_Job_Detail_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Analysis_Job_Detail_Report_2]
AS
SELECT AJ.AJ_jobID AS JobNum,
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       DS.DS_folder_name AS [Dataset Folder],
       DFP.Dataset_Folder_Path AS [Dataset Folder Path],
       DFP.Archive_Folder_Path AS [Archive Folder Path],
       InstName.IN_name AS Instrument,
       AnalysisTool.AJT_toolName AS [Tool Name],
       AJ.AJ_parmFileName AS [Parm File],
       AnalysisTool.AJT_parmFileStoragePath AS [Parm File Storage Path],
       AJ.AJ_settingsFileName AS [Settings File],
       Org.OG_name AS Organism,
       AJ.AJ_organismDBName AS [Organism DB],
       dbo.GetFASTAFilePath(AJ.AJ_organismDBName, Org.OG_name) AS [Organism DB Storage Path],
       AJ.AJ_proteinCollectionList AS [Protein Collection List],
       AJ.AJ_proteinOptionsList AS [Protein Options List],
       ASN.AJS_name AS State,
       CONVERT(decimal(9, 2), AJ.AJ_ProcessingTimeMinutes) AS [Runtime Minutes],
       AJ.AJ_owner AS Owner,
       AJ.AJ_comment AS [Comment],
       AJ.AJ_specialProcessing AS [Special Processing],
       CASE WHEN AJ.AJ_Purged = 0
       THEN DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName 
       ELSE 'Purged: ' + DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName
       END AS [Results Folder Path],
       DFP.Archive_Folder_Path + '\' + AJ.AJ_resultsFolderName AS [Archive Results Folder Path],
       CASE WHEN AJ.AJ_Purged = 0
       THEN DFP.Dataset_URL + AJ.AJ_resultsFolderName + '/' 
       ELSE DFP.Dataset_URL
       END AS [Data Folder Link],
       dbo.GetJobPSMStats(AJ.AJ_JobID) AS [PSM Stats],
       ISNULL(MTSPT.PT_DB_Count, 0) AS [MTS PT DB Count],
       ISNULL(MTSMT.MT_DB_Count, 0) AS [MTS MT DB Count],
       ISNULL(PMTaskCountQ.PMTasks, 0) AS [Peak Matching Results],
       AJ.AJ_created AS Created,
       AJ.AJ_start AS [Started],
       AJ.AJ_finish AS Finished,
       AJ.AJ_requestID AS Request,
       AJPGA.Group_ID AS [Processor Group ID],
       AJPG.Group_Name AS [Processor Group Name],
       AJPGA.Entered_By AS [Processor Group Assignee],
       AJ.AJ_priority AS Priority,
       AJ.AJ_assignedProcessorName AS [Assigned Processor],
       AJ.AJ_Analysis_Manager_Error AS [AM Code],
       dbo.GetDEMCodeString(AJ.AJ_Data_Extraction_Error) AS [DEM Code],
       CASE AJ.AJ_propagationMode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS [Export Mode],
       CASE WHEN AJ.AJ_DatasetUnreviewed = 0 Then 'No' Else 'Yes' End AS [Dataset Unreviewed]
FROM dbo.T_Analysis_Job AS AJ
     INNER JOIN dbo.T_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Experiments AS E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN dbo.V_Dataset_Folder_Paths AS DFP
       ON DFP.Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.t_storage_path AS SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN dbo.T_Analysis_State_Name AS ASN
       ON AJ.AJ_StateID = ASN.AJS_stateID
     INNER JOIN dbo.T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Organisms AS Org
       ON Org.Organism_ID = AJ.AJ_organismID
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) AS MT_DB_Count
                       FROM dbo.T_MTS_MT_DB_Jobs_Cached
                       GROUP BY Job ) AS MTSMT
       ON AJ.AJ_jobID = MTSMT.Job
     LEFT OUTER JOIN ( SELECT Job,
                              COUNT(*) AS PT_DB_Count
                       FROM dbo.T_MTS_PT_DB_Jobs_Cached
                       GROUP BY Job ) AS MTSPT
       ON AJ.AJ_jobID = MTSPT.Job
     LEFT OUTER JOIN ( SELECT DMS_Job,
                              COUNT(*) AS PMTasks
                       FROM dbo.T_MTS_Peak_Matching_Tasks_Cached AS PM
                       GROUP BY DMS_Job ) AS PMTaskCountQ
       ON PMTaskCountQ.DMS_Job = AJ.AJ_jobID
     LEFT OUTER JOIN dbo.T_Analysis_Job_Processor_Group AS AJPG
                     INNER JOIN dbo.T_Analysis_Job_Processor_Group_Associations AS AJPGA
                       ON AJPG.ID = AJPGA.Group_ID
       ON AJ.AJ_jobID = AJPGA.Job_ID




GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Detail_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Detail_Report_2] TO [PNL\D3M580] AS [dbo]
GO
