/****** Object:  View [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report]
AS
SELECT Tool.AJT_toolName AS name,
       Tool.AJT_resultType AS result_type,
       InstClasses.AllowedInstrumentClasses AS allowed_inst_classes,
       Tool.AJT_orgDbReqd AS org_db_req,
       Tool.AJT_extractionRequired AS extract_req,
       DSTypes.AllowedDatasetTypes AS allowed_ds_types
FROM dbo.T_Analysis_Tool Tool
     CROSS APPLY dbo.get_analysis_tool_allowed_dataset_type_list ( Tool.AJT_toolID ) DSTypes
     CROSS APPLY dbo.get_analysis_tool_allowed_inst_class_list ( Tool.AJT_toolID ) InstClasses
WHERE (Tool.AJT_toolID > 0) AND
      (Tool.AJT_active = 1)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Tool_Helper_List_Report] TO [DDL_Viewer] AS [dbo]
GO
