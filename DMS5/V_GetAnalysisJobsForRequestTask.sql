/****** Object:  View [dbo].[V_GetAnalysisJobsForRequestTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GetAnalysisJobsForRequestTask]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_priority AS Priority,
       AJ.AJ_StateID AS JobStateID,
       AnalysisTool.AJT_toolName AS AnalysisToolName,
       AJ.AJ_analysisToolID AS AnalysisToolID,
       DS.Dataset_Num AS Dataset,
       AJ.AJ_datasetID AS DatasetID,
       DASN.DASN_StateName AS ArchiveState,
       AUSN.AUS_name AS ArchiveUpdateState
FROM dbo.T_Analysis_Job AS AJ
     INNER JOIN dbo.T_Dataset AS DS
       ON AJ.AJ_datasetID = DS.Dataset_ID
     INNER JOIN dbo.T_Analysis_Tool AS AnalysisTool
       ON AJ.AJ_analysisToolID = AnalysisTool.AJT_toolID
     INNER JOIN dbo.T_Dataset_Archive AS DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
     INNER JOIN dbo.T_DatasetArchiveStateName AS DASN
       ON DA.AS_state_ID = DASN.DASN_StateID
     INNER JOIN dbo.T_Archive_Update_State_Name AS AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
WHERE (AJ.AJ_StateID = 1) AND
      (NOT (DA.AS_state_ID IN (2, 7, 8))) AND
      (DA.AS_update_state_ID <> 3)


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetAnalysisJobsForRequestTask] TO [PNL\D3M578] AS [dbo]
GO
