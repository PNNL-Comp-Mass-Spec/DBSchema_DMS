/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Predefined_Analysis_Scheduling_Rules_List_Report
AS
SELECT     TOP 100 PERCENT ID, SR_evaluationOrder AS [Evaluation Order], SR_instrumentClass AS [Instrument Class], SR_instrument_Name AS Instrument, 
                      SR_dataset_Name AS Dataset, SR_analysisToolName AS [Analysis Tool], SR_priority AS Priority, SR_processorName AS Processor
FROM         dbo.T_Predefined_Analysis_Scheduling_Rules
ORDER BY SR_evaluationOrder

GO
