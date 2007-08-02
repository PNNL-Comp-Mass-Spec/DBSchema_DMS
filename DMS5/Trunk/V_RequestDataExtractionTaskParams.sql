/****** Object:  View [dbo].[V_RequestDataExtractionTaskParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_RequestDataExtractionTaskParams
AS
SELECT     A.AJ_jobID AS jobID, T.AJT_resultType AS ToolResultType, T.AJT_toolName AS ToolName, D.Dataset_Num AS DatasetNum, 
                      D.DS_folder_name AS DatasetFolderName, A.AJ_parmFileName AS ParmFileName, A.AJ_settingsFileName AS SettingsFileName, 
                      T.AJT_parmFileStoragePath AS ParmFileStoragePath, A.AJ_comment AS Comment, A.AJ_assignedProcessorName AS AssignedProcessor, 
                      A.AJ_resultsFolderName AS ResultsFolderName, T.AJT_parmFileStoragePath + 'SettingsFiles\' AS settingsFileStoragePath, 
                      S.SP_vol_name_client +
                          (SELECT     Client
                            FROM          dbo.T_MiscPaths
                            WHERE      ([Function] = 'AnalysisXfer')) AS transferFolderPath
FROM         dbo.T_Analysis_Job AS A INNER JOIN
                      dbo.T_Dataset AS D ON A.AJ_datasetID = D.Dataset_ID INNER JOIN
                      dbo.t_storage_path AS S ON D.DS_storage_path_ID = S.SP_path_ID INNER JOIN
                      dbo.T_Analysis_Tool AS T ON A.AJ_analysisToolID = T.AJT_toolID

GO
