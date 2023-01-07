/****** Object:  View [dbo].[V_Capture_Local_Processors_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Capture_Local_Processors_Detail_Report]
AS
SELECT processor_name, state, machine, latest_request, manager_version,
      dbo.GetProcessorStepToolList(Processor_Name) AS tools,
      dbo.GetProcessorAssignedInstrumentList(Processor_Name) AS instruments
FROM dbo.T_Local_Processors


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Local_Processors_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
