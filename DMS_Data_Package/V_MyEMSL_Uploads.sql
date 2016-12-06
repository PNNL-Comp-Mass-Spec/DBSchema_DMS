/****** Object:  View [dbo].[V_MyEMSL_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_MyEMSL_Uploads
AS
SELECT MU.Entry_ID,
       MU.Data_Package_ID,
       MU.Subfolder,
       MU.FileCountNew,
       MU.FileCountUpdated,
       CONVERT(decimal(9,3), MU.Bytes / 1024.0 / 1024.0) as MB,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS UploadTimeSeconds,
       MU.StatusURI_PathID,
       MU.StatusNum,
       MU.ErrorCode,
       StatusU.URI_Path + CONVERT(varchar(12), MU.StatusNum) + '/xml' AS Status_URI,
       MU.Available,
       MU.Verified,
       MU.Entered
FROM T_MyEMSL_Uploads MU
     LEFT OUTER JOIN T_URI_Paths StatusU
       ON MU.StatusURI_PathID = StatusU.URI_PathID     

GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Uploads] TO [DDL_Viewer] AS [dbo]
GO
