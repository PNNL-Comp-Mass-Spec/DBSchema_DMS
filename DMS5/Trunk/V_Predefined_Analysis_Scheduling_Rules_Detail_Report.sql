/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Predefined_Analysis_Scheduling_Rules_Detail_Report
CREATE VIEW V_Predefined_Analysis_Scheduling_Rules_Detail_Report
AS
SELECT PASR.ID, 
    PASR.SR_evaluationOrder AS [Evaluation Order], 
    PASR.SR_instrumentClass AS [Instrument Class], 
    PASR.SR_instrument_Name AS [Instrument Name], 
    PASR.SR_dataset_Name AS [Dataset Name], 
    PASR.SR_analysisToolName AS [Analysis Tool Name], 
    PASR.SR_priority AS priority, ISNULL(AJPG.Group_Name, '') 
    AS [Processor Group], PASR.SR_enabled AS Enabled, 
    PASR.SR_Created AS Created
FROM dbo.T_Predefined_Analysis_Scheduling_Rules PASR LEFT OUTER
     JOIN
    dbo.T_Analysis_Job_Processor_Group AJPG ON 
    PASR.SR_processorGroupID = AJPG.ID

GO
