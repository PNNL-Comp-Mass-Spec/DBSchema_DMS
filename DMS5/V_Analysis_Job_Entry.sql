/****** Object:  View [dbo].[V_Analysis_Job_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Entry]
AS
SELECT CONVERT(varchar(32), AJ.AJ_jobID) AS job,
       AJ.AJ_priority as priority,
       AnalysisTool.AJT_toolName AS tool_name,
       DS.Dataset_Num AS dataset,
       AJ.AJ_parmFileName AS param_file,
       AJ.AJ_settingsFileName AS settings_file,
       Org.OG_name AS organism,
       AJ.AJ_organismDBName AS organism_db,
       AJ.AJ_owner AS owner,
       AJ.AJ_comment AS comment,
       AJ.AJ_specialProcessing AS special_processing,
       AJ.AJ_batchID AS batch_id,
       AJ.AJ_assignedProcessorName AS assigned_processor_name,
       AJ.AJ_proteinCollectionList AS prot_coll_name_list,
       AJ.AJ_proteinOptionsList AS prot_coll_options_list,
       ASN.AJS_name AS state_name,
       CASE AJ.AJ_propagationMode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS propagation_mode,
       AJPG.Group_Name AS associated_processor_group
FROM T_Analysis_Job_Processor_Group AJPG
     INNER JOIN T_Analysis_Job_Processor_Group_Associations AJPGA
       ON AJPG.ID = AJPGA.Group_ID
     RIGHT OUTER JOIN T_Analysis_Job AJ
                      INNER JOIN T_Dataset DS
                        ON AJ.AJ_datasetID = DS.Dataset_ID
                      INNER JOIN T_Organisms Org
                        ON AJ.AJ_organismID = Org.Organism_ID
                      INNER JOIN T_Analysis_Tool AnalysisTool
                        ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
                      INNER JOIN T_Analysis_State_Name ASN
                        ON AJ.AJ_StateID = ASN.AJS_stateID
       ON AJPGA.Job_ID = AJ.AJ_jobID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Entry] TO [DDL_Viewer] AS [dbo]
GO
