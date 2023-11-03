/****** Object:  View [dbo].[V_MyEMSL_Test_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Test_Uploads]
AS
SELECT MU.entry_id,
       MU.job,
       DS.Dataset_Num AS dataset,
       MU.dataset_id,
       MU.subfolder,
       MU.FileCountNew AS file_count_new,
       MU.FileCountUpdated AS file_count_updated,
       CONVERT(decimal(9,3), MU.Bytes / 1024.0 / 1024.0) as mb,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS upload_time_seconds,
       MU.StatusURI_PathID AS status_uri_path_id,
       MU.StatusNum AS status_num,
       MU.ErrorCode AS error_code,
       StatusU.URI_Path + CONVERT(varchar(12), MU.StatusNum) + CASE WHEN StatusU.URI_Path LIKE '%/status/%' Then '/xml' ELSE '' End AS status_uri,
       MU.verified,
	   MU.ingest_steps_completed,
       MU.entered
FROM T_MyEMSL_TestUploads MU
     LEFT OUTER JOIN T_URI_Paths StatusU
       ON MU.StatusURI_PathID = StatusU.URI_PathID
     LEFT OUTER JOIN S_DMS_T_Dataset DS
       ON MU.Dataset_ID = DS.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Test_Uploads] TO [DDL_Viewer] AS [dbo]
GO
