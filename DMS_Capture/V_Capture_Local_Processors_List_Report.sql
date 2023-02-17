/****** Object:  View [dbo].[V_Capture_Local_Processors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Local_Processors_List_Report]
AS
SELECT processor_name, state, machine, manager_version,
       dbo.get_processor_step_tool_list(Processor_Name) AS tools,
       dbo.get_processor_assigned_instrument_list(Processor_Name) AS instruments, latest_request
FROM dbo.T_Local_Processors

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Local_Processors_List_Report] TO [DDL_Viewer] AS [dbo]
GO
