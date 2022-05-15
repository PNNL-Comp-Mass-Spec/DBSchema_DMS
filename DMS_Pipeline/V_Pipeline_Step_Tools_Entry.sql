/****** Object:  View [dbo].[V_Pipeline_Step_Tools_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Step_Tools_Entry]
AS
SELECT id,
       name,
       type,
       description,
       shared_result_version,
       filter_version,
       cpu_load,
       memory_usage_mb,
       parameter_template,
       param_file_storage_path
FROM T_Step_Tools


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_Entry] TO [DDL_Viewer] AS [dbo]
GO
