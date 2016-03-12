/****** Object:  View [dbo].[V_DMS_PipelineProcessors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_PipelineProcessors
AS
SELECT ID,
       Processor_Name,
       State,
       Groups,
       GP_Groups,
       Machine
FROM S_DMS_V_GetPipelineProcessors

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineProcessors] TO [PNL\D3M578] AS [dbo]
GO
