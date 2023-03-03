/****** Object:  View [dbo].[V_Analysis_Job_Report_Numeric] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Report_Numeric]
AS
SELECT AJ.AJ_jobID AS job,
       AJ.AJ_priority AS priority,
       AJ.AJ_StateNameCached AS state,
       ATool.AJT_toolName AS tool_name,
       DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
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
       Convert(decimal(9,2), AJ.AJ_ProcessingTimeMinutes) AS runtime_minutes,
       ISNULL(AJ.AJ_assignedProcessorName, '(none)') AS cpu,
       ISNULL(AJ.AJ_resultsFolderName, '(none)') AS results_folder,
       AJ.AJ_batchID AS batch,
       AJ.AJ_requestID AS request,
       Spath.SP_machine_name AS storage_server,
       DSR.DRN_name AS dataset_rating
FROM T_Dataset_Rating_Name DSR
     INNER JOIN T_Analysis_Job AJ
                INNER JOIN T_Dataset DS
                  ON AJ.AJ_datasetID = DS.Dataset_ID
                INNER JOIN T_Organisms Org
                  ON AJ.AJ_organismID = Org.Organism_ID
                INNER JOIN T_Storage_Path Spath
                  ON DS.DS_storage_path_ID = Spath.SP_path_ID
                INNER JOIN T_Analysis_Tool ATool
                  ON AJ.AJ_analysisToolID = ATool.AJT_toolID
                INNER JOIN T_Instrument_Name InstName
                  ON DS.DS_instrument_name_ID = InstName.Instrument_ID
       ON DSR.DRN_state_ID = DS.DS_rating

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Report_Numeric] TO [DDL_Viewer] AS [dbo]
GO
