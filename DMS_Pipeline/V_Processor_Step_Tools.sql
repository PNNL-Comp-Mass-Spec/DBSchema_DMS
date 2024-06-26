/****** Object:  View [dbo].[V_Processor_Step_Tools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Processor_Step_Tools]
AS
SELECT LP.processor_name,
       PTGD.tool_name,
       PTGD.priority,
       PTGD.enabled,
       PTGD.comment,
       ST.CPU_Load As tool_cpu_load,
       LP.latest_request,
       LP.manager_version,
       LP.WorkDir_AdminShare As work_dir_admin_share,
       LP.ID As proc_id,
       LP.State AS processor_state,
       M.machine,
       M.total_cpus,
       M.cpus_available,
       M.total_memory_mb,
       M.memory_available,
       M.Comment AS machine_comment,
       PTG.group_id,
       PTG.group_name,
       PTG.Enabled AS group_enabled,
       PTG.Comment AS group_comment
FROM T_Machines AS M
     INNER JOIN T_Local_Processors AS LP
       ON M.Machine = LP.Machine
     INNER JOIN T_Processor_Tool_Groups AS PTG
       ON M.ProcTool_Group_ID = PTG.Group_ID
     INNER JOIN T_Processor_Tool_Group_Details AS PTGD
       ON PTG.Group_ID = PTGD.Group_ID AND
          LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
     INNER JOIN T_Step_Tools AS ST
       ON PTGD.Tool_Name = ST.Name
WHERE M.Enabled > 0

GO
