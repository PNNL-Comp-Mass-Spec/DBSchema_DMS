/****** Object:  View [dbo].[V_Analysis_Job_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Analysis_Job_Entry as 
SELECT CONVERT(varchar(32), AJ.AJ_jobID) AS Job,
       AJ.AJ_priority,
       AnalysisTool.AJT_toolName AS AJ_ToolName,
       DS.Dataset_Num AS AJ_Dataset,
       AJ.AJ_parmFileName AS AJ_ParmFile,
       AJ.AJ_settingsFileName AS AJ_SettingsFile,
       Org.OG_name AS AJ_Organism,
       AJ.AJ_organismDBName AS AJ_OrganismDB,
       AJ.AJ_owner,
       AJ.AJ_comment,
       AJ.AJ_specialProcessing,
       AJ.AJ_batchID,
       AJ.AJ_assignedProcessorName,
       AJ.AJ_proteinCollectionList AS protCollNameList,
       AJ.AJ_proteinOptionsList AS protCollOptionsList,
       ASN.AJS_name AS stateName,
       CASE AJ.AJ_propagationMode
           WHEN 0 THEN 'Export'
           ELSE 'No Export'
       END AS propagationMode,
       AJPG.Group_Name AS associatedProcessorGroup
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
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Entry] TO [PNL\D3M580] AS [dbo]
GO
