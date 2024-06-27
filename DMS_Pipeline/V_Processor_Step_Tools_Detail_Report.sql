/****** Object:  View [dbo].[V_Processor_Step_Tools_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Processor_Step_Tools_Detail_Report]
AS
SELECT LP.processor_name,
       LP.ID As processor_id,
       LP.State AS processor_state,
       M.machine,
       LP.latest_request,
       LP.manager_version,
       dbo.get_processor_step_tool_list(LP.processor_name) AS enabled_tools,
       dbo.get_disabled_processor_step_tool_list(LP.processor_name) AS disabled_tools,
       M.total_cpus,
       M.cpus_available,
       M.total_memory_mb,
       M.memory_available,
       M.Comment AS machine_comment,
       LP.WorkDir_AdminShare As work_dir_admin_share
FROM T_Machines AS M
     INNER JOIN T_Local_Processors AS LP
       ON M.Machine = LP.Machine

GO
