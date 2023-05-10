/****** Object:  View [dbo].[V_MyEMSL_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MyEMSL_Uploads]
AS
SELECT MU.Entry_ID,
       MU.Data_Package_ID,
       MU.Subfolder,
       MU.FileCountNew AS File_Count_New,
       MU.FileCountUpdated AS File_Count_Updated,
       CONVERT(decimal(9,3), Case When MU.Bytes / 1024.0 / 1024.0 > 999999          Then 999999 Else MU.Bytes / 1024.0 / 1024.0 End) AS MB,
       CONVERT(decimal(9,3), Case When MU.Bytes / 1024.0 / 1024.0 / 1024.0 > 999999 Then 999999 Else MU.Bytes / 1024.0 / 1024.0 / 1024.0 End) AS GB,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS Upload_Time_Seconds,
       MU.StatusURI_PathID AS Status_URI_Path_ID,
       MU.StatusNum AS Status_Num,
       MU.ErrorCode AS Error_Code,
       StatusU.URI_Path + CONVERT(varchar(12), MU.StatusNum) + CASE WHEN StatusU.URI_Path LIKE '%/status/%' Then '/xml' ELSE '' End AS Status_URI,
       MU.Verified,
       MU.Entered
FROM T_MyEMSL_Uploads MU
     LEFT OUTER JOIN T_URI_Paths StatusU
       ON MU.StatusURI_PathID = StatusU.URI_PathID

GO
