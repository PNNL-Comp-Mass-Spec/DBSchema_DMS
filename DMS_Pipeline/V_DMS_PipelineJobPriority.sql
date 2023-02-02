/****** Object:  View [dbo].[V_DMS_PipelineJobPriority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_PipelineJobPriority
AS
SELECT Job,
       Priority
FROM S_DMS_V_Get_Pipeline_Job_Priority


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineJobPriority] TO [DDL_Viewer] AS [dbo]
GO
