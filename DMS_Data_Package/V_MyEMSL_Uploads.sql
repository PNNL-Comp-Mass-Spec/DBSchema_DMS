/****** Object:  View [dbo].[V_MyEMSL_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Uploads]
AS
/*
** Note that this view is used by clsDataPackageArchiver in the DataPackage Archive Manager
*/

SELECT MU.Entry_ID,
       MU.Data_Package_ID,
       MU.Subfolder,
       MU.FileCountNew As File_Count_New,
       MU.FileCountUpdated As File_Count_Updated,
       CONVERT(decimal(9,3), MU.Bytes / 1024.0 / 1024.0) AS MB,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS Upload_Time_Seconds,
       MU.StatusURI_PathID As Status_URI_Path_ID,
       MU.StatusNum As Status_Num,
       MU.ErrorCode As Error_Code,
	   P.URI_Path + CONVERT(varchar(12), MU.StatusNum) + CASE WHEN P.URI_Path LIKE '%/status/%' Then '/xml' ELSE '' End AS Status_URI,
       MU.Available,
       MU.Verified,
       MU.Entered
FROM T_MyEMSL_Uploads MU
     LEFT OUTER JOIN T_URI_Paths P
       ON MU.StatusURI_PathID = P.URI_PathID     


GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Uploads] TO [DDL_Viewer] AS [dbo]
GO
