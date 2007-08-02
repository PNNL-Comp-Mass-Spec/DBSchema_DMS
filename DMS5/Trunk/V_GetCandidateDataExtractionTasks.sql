/****** Object:  View [dbo].[V_GetCandidateDataExtractionTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetCandidateDataExtractionTasks
AS
SELECT     AJ.AJ_jobID AS JobID, AJ.AJ_StateID AS JobStateID, AJ.AJ_Last_Affected AS Last_Affected, AJ.AJ_priority AS Priority, 
                      TT.AJT_resultType AS ToolType
FROM         dbo.T_Analysis_Job AS AJ INNER JOIN
                      dbo.T_Dataset AS DS ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
                      dbo.T_Analysis_Tool AS TT ON AJ.AJ_analysisToolID = TT.AJT_toolID
WHERE     (AJ.AJ_StateID = 16)

GO
