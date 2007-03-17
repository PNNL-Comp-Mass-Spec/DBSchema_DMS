/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Predefined_Analysis_Scheduling_Rules_List_Report
AS
SELECT TOP 100 PERCENT PASR.ID, 
    PASR.SR_evaluationOrder AS [Evaluation Order], 
    PASR.SR_instrumentClass AS [Instrument Class], 
    PASR.SR_instrument_Name AS Instrument, 
    PASR.SR_dataset_Name AS Dataset, 
    PASR.SR_analysisToolName AS [Analysis Tool], 
    PASR.SR_priority AS Priority, ISNULL(AJPG.Group_Name, '') 
    AS [Processor Group]
FROM dbo.T_Predefined_Analysis_Scheduling_Rules PASR LEFT OUTER
     JOIN
    dbo.T_Analysis_Job_Processor_Group AJPG ON 
    PASR.SR_processorGroupID = AJPG.ID
ORDER BY PASR.SR_evaluationOrder

GO
