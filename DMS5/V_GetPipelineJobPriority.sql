/****** Object:  View [dbo].[V_GetPipelineJobPriority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_GetPipelineJobPriority]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_priority AS Priority
FROM dbo.T_Analysis_Job AS AJ
WHERE (AJ.AJ_StateID IN (1, 2, 8))


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineJobPriority] TO [DDL_Viewer] AS [dbo]
GO
