/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report]
AS
SELECT PASR.ID,
       PASR.SR_evaluationOrder AS [Evaluation Order],
       PASR.SR_instrumentClass AS [Instrument Class],
       PASR.SR_instrument_Name AS Instrument,
       PASR.SR_dataset_Name AS Dataset,
       PASR.SR_analysisToolName AS [Analysis Tool],
       PASR.SR_priority AS Priority,
       ISNULL(AJPG.Group_Name, '') AS [Processor Group],
       PASR.SR_enabled AS Enabled
FROM dbo.T_Predefined_Analysis_Scheduling_Rules AS PASR
     LEFT OUTER JOIN dbo.T_Analysis_Job_Processor_Group AS AJPG
       ON PASR.SR_processorGroupID = AJPG.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report] TO [PNL\D3M578] AS [dbo]
GO
