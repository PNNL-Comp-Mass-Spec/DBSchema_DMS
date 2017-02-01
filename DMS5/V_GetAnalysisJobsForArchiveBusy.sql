/****** Object:  View [dbo].[V_GetAnalysisJobsForArchiveBusy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_GetAnalysisJobsForArchiveBusy]
AS
SELECT AJ.AJ_jobID, DS.Dataset_ID, DS.Dataset_Num, DS.DS_created, DS.DS_state_ID
FROM dbo.T_Analysis_Job AJ
     INNER JOIN dbo.T_Dataset_Archive DA
       ON AJ.AJ_datasetID = DA.AS_Dataset_ID
     INNER JOIN dbo.T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
WHERE AJ.AJ_stateid IN (1,2,3,8) AND
      ( (Dataset_Num Like 'QC_Shew%' AND DA.AS_state_ID = 7 And DA.AS_state_Last_Affected > DateAdd(Minute, -15, GetDate()))
        OR
        (Dataset_Num Not Like 'QC_Shew%' AND DA.AS_state_ID IN (1)    And DA.AS_state_Last_Affected > DateAdd(Minute, -180, GetDate()))
		OR
		(Dataset_Num Not Like 'QC_Shew%' AND DA.AS_state_ID IN (7, 8) And DA.AS_state_Last_Affected > DateAdd(Minute, -120, GetDate()))
		OR
		(Dataset_Num Not Like 'QC_Shew%' AND DA.AS_state_ID IN (2, 6) And DA.AS_state_Last_Affected > DateAdd(Minute,  -60, GetDate()))
      )

GO
GRANT VIEW DEFINITION ON [dbo].[V_GetAnalysisJobsForArchiveBusy] TO [DDL_Viewer] AS [dbo]
GO
