/****** Object:  View [dbo].[V_Pipeline_Scripts_Enabled] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Pipeline_Scripts_Enabled]
AS
-- This view is used by DMS website page families pipeline_jobs and pipeline_jobs_history in the utility_queries section

SELECT Script
FROM T_Scripts
WHERE Enabled = 'Y' AND
      Pipeline_Job_Enabled > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Scripts_Enabled] TO [DDL_Viewer] AS [dbo]
GO
