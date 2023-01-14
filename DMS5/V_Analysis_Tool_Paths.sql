/****** Object:  View [dbo].[V_Analysis_Tool_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Analysis_Tool_Paths
AS
SELECT AJT_toolID As analysis_tool_id,
       AJT_toolName AS tool_name, 
       AJT_toolBasename AS tool_base_name, 
       AJT_parmFileStoragePath As param_file_storage_path,
       AJT_parmFileStoragePathLocal As param_file_storage_path_local,
       AJT_resultType As result_type,
       AJT_active As tool_active
FROM dbo.T_Analysis_Tool
WHERE AJT_toolID > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Paths] TO [DDL_Viewer] AS [dbo]
GO
