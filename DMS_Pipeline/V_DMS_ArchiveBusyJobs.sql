/****** Object:  View [dbo].[V_DMS_ArchiveBusyJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_ArchiveBusyJobs
AS
SELECT AJ_jobID AS Job
FROM S_DMS_V_GetAnalysisJobsForArchiveBusy

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_ArchiveBusyJobs] TO [DDL_Viewer] AS [dbo]
GO
