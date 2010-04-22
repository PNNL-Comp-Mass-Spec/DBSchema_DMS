/****** Object:  View [dbo].[V_GetAnalysisJobsForArchiveBusy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GetAnalysisJobsForArchiveBusy]
AS
SELECT AJ.AJ_jobID
FROM dbo.T_Analysis_Job AJ
     INNER JOIN dbo.T_Dataset_Archive DA
       ON AJ.AJ_datasetID = DA.AS_Dataset_ID
WHERE AJ.AJ_stateid IN (1,2,3,8) AND
      (DA.AS_state_ID IN (2, 7, 12) OR DA.AS_update_state_ID = 3)


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetAnalysisJobsForArchiveBusy] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetAnalysisJobsForArchiveBusy] TO [PNL\D3M580] AS [dbo]
GO
