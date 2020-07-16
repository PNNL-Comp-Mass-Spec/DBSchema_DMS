/****** Object:  View [dbo].[V_Analysis_Job_PSM_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_PSM_Detail_Report]
AS
SELECT AJ.AJ_jobID AS Job,
       DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
       InstName.IN_name AS Instrument,
       CASE WHEN AJ.AJ_Purged = 0
       THEN DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName 
       ELSE 'Purged: ' + DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName
       END AS [Results Folder Path],
       DFP.Archive_Folder_Path + '\' + AJ.AJ_resultsFolderName AS [Archive Results Folder Path],
       CASE WHEN AJ.AJ_Purged = 0
       THEN DFP.Dataset_URL + AJ.AJ_resultsFolderName + '/' 
       ELSE DFP.Dataset_URL
       END AS [Data Folder Link],
       PSM.Spectra_Searched AS [Spectra Searched],
       PSM.Total_PSMs AS [Total PSMs (MSGF-filtered)],
       PSM.Unique_Peptides AS [Unique Peptides (MSGF-filtered)],
       PSM.Unique_Proteins AS [Unique Proteins (MSGF-filtered)],
       PSM.Total_PSMs_FDR_Filter AS [Total PSMs (FDR-filtered)],
       PSM.Unique_Peptides_FDR_Filter AS [Unique Peptides (FDR-filtered)],
       PSM.Unique_Proteins_FDR_Filter AS [Unique Proteins (FDR-filtered)],
       PSM.MSGF_Threshold AS [MSGF Threshold],
       CONVERT(varchar(12), CONVERT(decimal(5,2), PSM.FDR_Threshold * 100)) + '%' AS [FDR Threshold],
	   PSM.Tryptic_Peptides_FDR AS [Unique Tryptic Peptides],
	   CAST(PSM.Tryptic_Peptides_FDR / Cast(NullIf(PSM.Unique_Peptides_FDR_Filter, 0) AS float) * 100 AS decimal(9,1)) AS PctTryptic,
	   CAST(PSM.Missed_Cleavage_Ratio_FDR * 100 AS decimal(9,1)) AS [Pct Missed Cleavage],
	   PSM.Keratin_Peptides_FDR AS [Unique Keratin Peptides],
	   PSM.Trypsin_Peptides_FDR AS [Unique Trypsin Peptides],
       Convert(decimal(9,2), PSM.Percent_PSMs_Missing_NTermReporterIon) AS [Pct Missing NTerm Reporter Ions],
       Convert(decimal(9,2), PSM.Percent_PSMs_Missing_ReporterIon) AS [Pct Missing Reporter Ions],
       PSM.Last_Affected AS [PSM Stats Date],       
       PhosphoPSM.PhosphoPeptides AS PhosphoPep,
       PhosphoPSM.CTermK_Phosphopeptides AS [CTermK PhosphoPep],
       PhosphoPSM.CTermR_Phosphopeptides AS [CTermR PhosphoPep],
	   CAST(PhosphoPSM.MissedCleavageRatio * 100 AS decimal(9,1)) AS [Phospho Pct Missed Cleavage],
       ISNULL(MTSPT.PT_DB_Count, 0) AS [MTS PT DB Count],
       ISNULL(MTSMT.MT_DB_Count, 0) AS [MTS MT DB Count],
       ISNULL(PMTaskCountQ.PMTasks, 0) AS [Peak Matching Results],
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
       AJ.AJ_created AS Created,
       AJ.AJ_start AS [Started],
       AJ.AJ_finish AS Finished,
       AJ.AJ_requestID AS Request,
       AJ.AJ_priority AS Priority,
       AJ.AJ_assignedProcessorName AS [Assigned Processor],
       AJ.AJ_Analysis_Manager_Error AS [AM Code],
       dbo.GetDEMCodeString(AJ.AJ_Data_Extraction_Error) AS [DEM Code],
       CASE AJ.AJ_propagationMode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS [Export Mode],
       T_YesNo.Description AS [Dataset Unreviewed]
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
     INNER JOIN dbo.T_YesNo 
       ON AJ.AJ_DatasetUnreviewed = T_YesNo.Flag
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
     LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats AS PSM 
       ON AJ.AJ_JobID = PSM.Job
	 LEFT OUTER JOIN dbo.T_Analysis_Job_PSM_Stats_Phospho PhosphoPSM 
	   ON PSM.Job = PhosphoPSM.Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_PSM_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
