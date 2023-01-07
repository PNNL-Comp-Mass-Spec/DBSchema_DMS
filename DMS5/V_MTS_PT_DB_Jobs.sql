/****** Object:  View [dbo].[V_MTS_PT_DB_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MTS_PT_DB_Jobs]
AS
SELECT JM.job,
       DS.Dataset_Num AS dataset,
       JM.server_name,
       JM.peptide_db_name,
       JM.ResultType AS result_type,
       JM.last_affected,
       JM.process_state,
       Inst.IN_name AS instrument,
       C.Campaign_Num AS campaign,
       AnTool.AJT_toolName AS tool,
       AJ.AJ_parmFileName AS param_file,
       AJ.AJ_settingsFileName AS settings_file,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       JM.SortKey AS sort_key
FROM T_MTS_PT_DB_Jobs_Cached JM
     LEFT OUTER JOIN T_Dataset DS
                     INNER JOIN T_Analysis_Job AJ
                       ON DS.Dataset_ID = AJ.AJ_datasetID
                     INNER JOIN T_Instrument_Name Inst
                       ON DS.DS_instrument_name_ID = Inst.Instrument_ID
                     INNER JOIN T_Experiments E
                       ON DS.Exp_ID = E.Exp_ID
                     INNER JOIN T_Campaign C
                       ON E.EX_campaign_ID = C.Campaign_ID
                     INNER JOIN T_Analysis_Tool AnTool
                       ON AJ.AJ_analysisToolID = ANTool.AJT_toolID
       ON JM.Job = AJ.AJ_jobID


GO
GRANT VIEW DEFINITION ON [dbo].[V_MTS_PT_DB_Jobs] TO [DDL_Viewer] AS [dbo]
GO
