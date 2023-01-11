/****** Object:  View [dbo].[V_Analysis_Job_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Ex]
AS
SELECT AJ.AJ_jobID AS job,
       Tool.AJT_toolName AS tool_name,
       DS.Dataset_Num AS dataset,
       DS.DS_folder_name AS dataset_folder_name,
       SPath.SP_vol_name_client + SPath.SP_path AS dataset_storage_path,
       AJ.AJ_parmFileName AS param_file_name,
       AJ.AJ_settingsFileName AS settings_file_name,
       Tool.AJT_parmFileStoragePath AS param_file_storage_path,
       AJ.AJ_organismDBName AS organism_db_name,
       AJ.AJ_proteinCollectionList AS protein_collection_list,
       AJ.AJ_proteinOptionsList AS protein_options,
       Org.OG_organismDBPath AS organism_db_storage_path,
       AJ.AJ_StateID AS state_id,
       AJ.AJ_priority AS priority,
       AJ.AJ_comment AS comment,
       InstName.IN_class AS inst_class,
       AJ.AJ_owner AS owner,
       CONVERT(varchar(32), AJ.AJ_jobID) AS JobNum,     -- This column is obsolete
       DS.DS_Comp_State AS comp_state                   -- This column is obsolete
FROM dbo.T_Analysis_Job AJ
     INNER JOIN dbo.T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Organisms Org
       ON AJ.AJ_organismID = Org.Organism_ID
     INNER JOIN dbo.t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Analysis_Tool Tool
       ON AJ.AJ_analysisToolID = Tool.AJT_toolID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Ex] TO [DDL_Viewer] AS [dbo]
GO
