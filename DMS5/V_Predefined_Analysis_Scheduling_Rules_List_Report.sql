/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report]
AS
SELECT PASR.id,
       PASR.SR_evaluationOrder AS evaluation_order,
       PASR.SR_instrumentClass AS instrument_class,
       PASR.SR_instrument_Name AS instrument,
       PASR.SR_dataset_Name AS dataset,
       PASR.SR_analysisToolName AS analysis_tool,
       PASR.SR_priority AS priority,
       ISNULL(AJPG.group_name, '') AS processor_group,
       PASR.SR_enabled AS enabled
FROM dbo.T_Predefined_Analysis_Scheduling_Rules AS pasr
     LEFT OUTER JOIN dbo.T_Analysis_Job_Processor_Group AS AJPG
       ON PASR.SR_processorGroupID = AJPG.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Rules_List_Report] TO [DDL_Viewer] AS [dbo]
GO
