/****** Object:  View [dbo].[V_DMS_PipelineJobProcessors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_PipelineJobProcessors
AS
SELECT Job,
       Processor,
       General_Processing
FROM S_DMS_V_GetPipelineJobProcessors

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineJobProcessors] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineJobProcessors] TO [PNL\D3M580] AS [dbo]
GO
