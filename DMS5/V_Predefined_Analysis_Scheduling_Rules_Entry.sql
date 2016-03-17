/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Rules_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Predefined_Analysis_Scheduling_Rules_Entry
AS
SELECT PASR.SR_evaluationOrder AS evaluationOrder, 
    PASR.SR_instrumentClass AS instrumentClass, 
    PASR.SR_instrument_Name AS instrumentName, 
    PASR.SR_dataset_Name AS datasetName, 
    PASR.SR_analysisToolName AS analysisToolName, 
    PASR.SR_priority AS priority, ISNULL(AJPG.Group_Name, '') 
    AS processorGroup, PASR.SR_enabled AS enabled, 
    PASR.SR_Created AS Created, PASR.ID
FROM dbo.T_Predefined_Analysis_Scheduling_Rules PASR LEFT OUTER
     JOIN
    dbo.T_Analysis_Job_Processor_Group AJPG ON 
    PASR.SR_processorGroupID = AJPG.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Rules_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Rules_Entry] TO [PNL\D3M580] AS [dbo]
GO
