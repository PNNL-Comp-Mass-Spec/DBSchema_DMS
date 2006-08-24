/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Predefined_Analysis_Scheduling_Rules_Detail_Report
AS
SELECT     ID, SR_evaluationOrder AS [Evaluation Order], SR_instrumentClass AS [Instrument Class], SR_instrument_Name AS [Instrument Name], 
                      SR_dataset_Name AS [Dataset Name], SR_analysisToolName AS [Analysis Tool Name], SR_priority AS priority, 
                      SR_processorName AS [Processor Name], SR_enabled AS Enabled, SR_Created AS Created
FROM         dbo.T_Predefined_Analysis_Scheduling_Rules

GO
