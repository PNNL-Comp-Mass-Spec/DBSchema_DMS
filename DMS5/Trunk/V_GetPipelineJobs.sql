/****** Object:  View [dbo].[V_GetPipelineJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_GetPipelineJobs]
AS
SELECT AJ.AJ_jobID AS Job,
       AJ.AJ_priority AS Priority,
       AnTool.AJT_toolName AS Tool,
       DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       AJ.AJ_settingsFileName AS Settings_File_Name,
       AJ.AJ_StateID AS State,
       SPath.SP_vol_name_client + 'DMS3_XFER\' + DS.Dataset_Num + '\' AS Transfer_Folder_Path,
       AJ.AJ_Comment AS Comment
FROM dbo.T_Analysis_Job AS AJ
     INNER JOIN dbo.T_Dataset_Archive AS DA
       ON AJ.AJ_datasetID = DA.AS_Dataset_ID
     INNER JOIN dbo.T_Analysis_Tool AnTool
       ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
     INNER JOIN dbo.T_Dataset DS
       ON AJ.AJ_datasetID = DS.Dataset_ID AND
          DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
WHERE (AJ.AJ_StateID IN (1, 8)) AND
      (DA.AS_state_ID IN (3, 4, 10)) AND
      (DA.AS_update_state_ID <> 3)


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineJobs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineJobs] TO [PNL\D3M580] AS [dbo]
GO
