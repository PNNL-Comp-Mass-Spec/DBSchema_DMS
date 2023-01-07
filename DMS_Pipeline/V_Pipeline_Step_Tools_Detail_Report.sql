/****** Object:  View [dbo].[V_Pipeline_Step_Tools_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Step_Tools_Detail_Report]
AS
SELECT id,
       name,
       type,
       description,
       comment,
       shared_result_version,
       filter_version,
       cpu_load,
       uses_all_cores,
       memory_usage_mb,
       available_for_general_processing,
       param_file_storage_path,
       parameter_template,
       tag,
       avgruntime_minutes as avg_runtime_minutes,
       disable_output_folder_name_override_on_skip,
       primary_step_tool,
       holdoff_interval_minutes
FROM T_Step_Tools


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
