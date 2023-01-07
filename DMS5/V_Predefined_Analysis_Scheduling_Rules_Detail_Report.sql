/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Predefined_Analysis_Scheduling_Rules_Detail_Report]
AS
SELECT PASR.id,
       PASR.SR_evaluationOrder AS evaluation_order,
       PASR.SR_instrumentClass AS instrument_class,
       PASR.SR_instrument_Name AS instrument_name,
       PASR.SR_dataset_Name AS dataset_name,
       PASR.SR_analysisToolName AS analysis_tool_name,
       PASR.SR_priority AS priority,
       ISNULL(AJPG.group_name, '') AS processor_group,
       PASR.SR_enabled AS enabled,
       PASR.SR_Created AS created
FROM dbo.T_Predefined_Analysis_Scheduling_Rules PASR LEFT OUTER
     JOIN
    dbo.T_Analysis_Job_Processor_Group AJPG ON
    PASR.SR_processorGroupID = AJPG.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Rules_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
