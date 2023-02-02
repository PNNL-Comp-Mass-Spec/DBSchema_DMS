/****** Object:  View [dbo].[V_Get_Pipeline_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Get_Pipeline_Jobs]
AS
SELECT AJ.AJ_jobID AS job,
       AJ.AJ_priority AS priority,
       AnTool.AJT_toolName AS tool,
       DS.Dataset_Num AS dataset,
       DS.dataset_id,
       AJ.AJ_settingsFileName AS settings_file_name,
       AJ.AJ_parmFileName AS parameter_file_name,
       AJ.AJ_StateID AS state,
       SPath.SP_vol_name_client + 'DMS3_XFER\' + DS.Dataset_Num + '\' AS transfer_folder_path,
       AJ.AJ_Comment AS comment,
       AJ.AJ_specialProcessing as special_processing,
       AJ.AJ_Owner AS owner
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
GRANT VIEW DEFINITION ON [dbo].[V_Get_Pipeline_Jobs] TO [DDL_Viewer] AS [dbo]
GO
