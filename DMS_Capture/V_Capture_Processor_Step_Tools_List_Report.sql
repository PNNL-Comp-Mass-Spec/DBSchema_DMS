/****** Object:  View [dbo].[V_Capture_Processor_Step_Tools_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Processor_Step_Tools_List_Report]
AS
SELECT LP.processor_name,
       dbo.T_Processor_Tool.tool_name,
       dbo.T_Processor_Tool.priority,
       dbo.T_Processor_Tool.enabled,
       dbo.T_Processor_Tool.comment,
       LP.State AS processor_state,
       M.machine,
       M.total_cpus,
       M.bionet_available,
       LP.latest_request
FROM dbo.T_Machines AS M
     RIGHT OUTER JOIN dbo.T_Processor_Tool
                      INNER JOIN dbo.T_Step_Tools AS ST
                        ON dbo.T_Processor_Tool.Tool_Name = ST.Name
                      LEFT OUTER JOIN dbo.T_Local_Processors AS LP
                        ON dbo.T_Processor_Tool.Processor_Name = LP.Processor_Name
       ON M.Machine = LP.Machine
WHERE M.Enabled > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Processor_Step_Tools_List_Report] TO [DDL_Viewer] AS [dbo]
GO
