/****** Object:  View [dbo].[V_MyEMSL_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_MyEMSL_Uploads]
AS
/*
** Note that this view is used by clsPluginMain of the ArchiveStatusCheckPlugin
*/

SELECT MU.Entry_ID,
       MU.Job,
       DS.Dataset_Num AS Dataset,
       MU.Dataset_ID,
       MU.Subfolder,
       MU.FileCountNew,
       MU.FileCountUpdated,
       CONVERT(decimal(9,3), MU.Bytes / 1024.0 / 1024.0) as MB,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS UploadTimeSeconds,
       MU.StatusURI_PathID,
       MU.StatusNum,
       MU.ErrorCode,
       StatusU.URI_Path + CONVERT(varchar(12), MU.StatusNum) + '/xml' AS Status_URI,
       MU.Verified,
	   MU.Ingest_Steps_Completed,
       MU.Entered,
	   MU.EUS_InstrumentID,
	   MU.EUS_ProposalID,
	   MU.EUS_UploaderID
FROM T_MyEMSL_Uploads MU
     LEFT OUTER JOIN T_URI_Paths StatusU
       ON MU.StatusURI_PathID = StatusU.URI_PathID
     LEFT OUTER JOIN S_DMS_T_Dataset DS
       ON MU.Dataset_ID = DS.Dataset_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Uploads] TO [DDL_Viewer] AS [dbo]
GO
