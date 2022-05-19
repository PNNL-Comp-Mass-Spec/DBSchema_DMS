/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Predefined_Analysis_Scheduling_Rules_Entry
AS
SELECT PASR.SR_evaluationOrder AS evaluation_order,
       PASR.SR_instrumentClass AS instrument_class,
       PASR.SR_instrument_Name AS instrument_name,
       PASR.SR_dataset_Name AS dataset_name,
       PASR.SR_analysisToolName AS analysis_tool_name,
       PASR.SR_priority AS priority,
       ISNULL(AJPG.Group_Name, '') AS processor_group,
       PASR.SR_enabled AS enabled,
       PASR.SR_Created AS created,
       PASR.id
FROM dbo.T_Predefined_Analysis_Scheduling_Rules PASR
     LEFT OUTER JOIN dbo.T_Analysis_Job_Processor_Group AJPG
       ON PASR.SR_processorGroupID = AJPG.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Rules_Entry] TO [DDL_Viewer] AS [dbo]
GO
