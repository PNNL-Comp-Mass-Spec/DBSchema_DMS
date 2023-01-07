/****** Object:  View [dbo].[V_Analysis_Request_Jobs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Request_Jobs_List_Report]
AS
SELECT AJ.AJ_jobID AS job,
       AJ.AJ_priority AS priority,
       ASN.AJS_name AS state,
       Tool.AJT_toolName AS tool_name,
       DS.Dataset_Num AS dataset,
       AJ.AJ_parmFileName AS param_file,
       AJ.AJ_settingsFileName AS settings_file,
       Org.OG_name AS organism,
       AJ.AJ_organismDBName AS organism_db,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       AJ.AJ_proteinOptionsList AS protein_options,
       AJ.AJ_comment AS comment,
       AJ.AJ_created AS created,
       AJ.AJ_start AS started,
       AJ.AJ_finish AS finished,
	   CAST(AJ.Progress AS DECIMAL(9,2)) AS job_progress,
	   CAST(AJ.ETA_Minutes AS DECIMAL(18,1)) AS job_eta_minutes,
       AJ.AJ_batchID AS batch,
       AJ.AJ_requestID AS request_id,
       DFP.Dataset_Folder_Path + '\' + AJ.AJ_resultsFolderName AS results_folder,
       Convert(decimal(9,2), AJ.AJ_ProcessingTimeMinutes) AS runtime_minutes,
	   DS.dataset_id
FROM dbo.T_Analysis_Job AJ
     INNER JOIN dbo.T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Organisms Org
       ON AJ.AJ_organismID = Org.Organism_ID
     INNER JOIN dbo.T_Analysis_Tool Tool
       ON AJ.AJ_analysisToolID = Tool.AJT_toolID
     INNER JOIN dbo.T_Analysis_State_Name ASN
       ON AJ.AJ_StateID = ASN.AJS_stateID
     LEFT OUTER JOIN V_Dataset_Folder_Paths DFP
       ON AJ.AJ_datasetID = DFP.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Request_Jobs_List_Report] TO [DDL_Viewer] AS [dbo]
GO
