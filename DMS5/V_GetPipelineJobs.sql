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
       AJ.AJ_parmFileName AS Parameter_File_Name,
       AJ.AJ_StateID AS State,
       SPath.SP_vol_name_client + 'DMS3_XFER\' + DS.Dataset_Num + '\' AS Transfer_Folder_Path,
       AJ.AJ_Comment AS Comment,
       AJ.AJ_specialProcessing as Special_Processing,
       AJ.AJ_Owner AS Owner       
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
      (
	    -- Ideally we only allow a job to start processing if the dataset is archived (states 3 or 10)
		-- or purged (states 4, 9, 14, 15) or NonPurgeable (10)
		(DA.AS_state_ID IN (3, 4, 9, 10, 14, 15))
		Or
		-- But if the archive state is "New" for over 60 minutes, let the job start
		(DA.AS_state_ID IN (1) And DA.AS_state_Last_Affected < DateAdd(minute, -60, GetDate()))
		OR
		-- And if the dataset has been in state "Archive in progress" or "Operation Failed" for over 60 minutes, let the job start
		(DA.AS_state_ID IN (2, 6) And DA.AS_state_Last_Affected < DateAdd(minute, -60, GetDate()))
		OR
		-- If the archive state is "Purge in Progress" or "Purge failed" for over 60 minutes, let the job start
		(DA.AS_state_ID IN (7, 8) And DA.AS_state_Last_Affected < DateAdd(minute, -60, GetDate()))
		Or
		-- Lastly, let QC_Shew and QC_Mam datasets start if they have been dispositioned (DS_Rating >= 1) and the archive state changed more than 15 minutes ago
		-- However, exclude QC datasets with an archive state of 6 (Operation Failed) or 7 (Purge In Progress)
		((Dataset_Num Like 'QC_Shew%' Or Dataset_Num Like 'QC_Mam%') AND 
         DS.DS_Rating >= 1 AND 
         NOT DA.AS_state_ID IN (6,7) AND 
         DA.AS_state_Last_Affected < DateAdd(minute, -15, GetDate()))
      )


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineJobs] TO [DDL_Viewer] AS [dbo]
GO
