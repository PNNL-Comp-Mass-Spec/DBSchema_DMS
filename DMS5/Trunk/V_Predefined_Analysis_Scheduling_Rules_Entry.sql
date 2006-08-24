/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Predefined_Analysis_Scheduling_Rules_Entry
AS
SELECT     SR_evaluationOrder AS evaluationOrder, SR_instrumentClass AS instrumentClass, SR_instrument_Name AS instrumentName, 
                      SR_dataset_Name AS datasetName, SR_analysisToolName AS analysisToolName, SR_priority AS priority, SR_processorName AS processorName, 
                      SR_enabled AS enabled, SR_Created AS Created, ID
FROM         dbo.T_Predefined_Analysis_Scheduling_Rules

GO
