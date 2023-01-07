/****** Object:  View [dbo].[V_Analysis_Tool_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Tool_Report]
AS
SELECT Tool.AJT_toolName AS name,
       Tool.AJT_toolID AS id,
       Tool.AJT_resultType AS result_type,
       Tool.AJT_parmFileStoragePath AS param_file_storage_client,
       Tool.AJT_parmFileStoragePathLocal AS param_file_storage_server,
       InstClasses.AllowedInstrumentClasses AS allowed_inst_classes,
       Tool.AJT_defaultSettingsFileName AS default_settings_file,
       Tool.AJT_active AS active,
       AJT_orgDbReqd AS org_db_req,
       Tool.AJT_extractionRequired AS extract_req,
       DSTypes.AllowedDatasetTypes AS allowed_ds_types
FROM T_Analysis_Tool Tool
     CROSS APPLY dbo.GetAnalysisToolAllowedDSTypeList ( Tool.AJT_toolID ) DSTypes
     CROSS APPLY dbo.GetAnalysisToolAllowedInstClassList ( Tool.AJT_toolID ) InstClasses
WHERE (Tool.AJT_toolID > 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Report] TO [DDL_Viewer] AS [dbo]
GO
