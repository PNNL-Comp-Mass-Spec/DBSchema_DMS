/****** Object:  View [dbo].[V_MyEMSL_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_MyEMSL_Uploads]
AS
SELECT MU.Entry_ID,
       MU.Job,
       MU.Dataset_ID,
       MU.Subfolder,
       MU.FileCountNew,
       MU.FileCountUpdated,
       CONVERT(decimal(9,3), MU.Bytes / 1024.0 / 1024.0) as MB,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS UploadTimeSeconds,
       MU.StatusURI_PathID,
       -- MU.ContentURI_PathID,
       MU.StatusNum,
       MU.ErrorCode,
       StatusU.URI_Path + CONVERT(varchar(12), MU.StatusNum) + '/xml' AS Status_URI,
       MU.Verified,
       -- CASE WHEN ISNULL(MU.ContentURI_PathID, 1) <= 1 THEN 'Undefined'
       --      ELSE ContentU.URI_Path + DS.Dataset_Num + CASE WHEN SubFolder <> '' THEN '/' + SubFolder ELSE '' END
       -- END AS Content_URI,
       MU.Entered
FROM T_MyEMSL_Uploads MU
     LEFT OUTER JOIN T_URI_Paths StatusU
       ON MU.StatusURI_PathID = StatusU.URI_PathID
     -- LEFT OUTER JOIN T_URI_Paths ContentU
     --   ON MU.ContentURI_PathID = ContentU.URI_PathID
     LEFT OUTER JOIN S_DMS_T_Dataset DS
       ON MU.Dataset_ID = DS.Dataset_ID


GO
