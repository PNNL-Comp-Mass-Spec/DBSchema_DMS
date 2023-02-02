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
FROM S_DMS_V_Get_Pipeline_Job_Processors


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineJobProcessors] TO [DDL_Viewer] AS [dbo]
GO
