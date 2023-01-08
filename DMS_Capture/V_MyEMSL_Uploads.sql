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
       MU.FileCountNew AS File_Count_New,
       MU.FileCountUpdated AS File_Count_Updated,
       CONVERT(decimal(9,3), MU.Bytes / 1024.0 / 1024.0) AS MB,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS Upload_Time_Seconds,
       MU.StatusURI_PathID AS Status_URI_Path_ID,
       MU.StatusNum AS Status_Num,
       MU.ErrorCode AS Error_Code,
	   MU.TransactionID AS Transaction_ID, 
       StatusU.URI_Path + CONVERT(varchar(12), MU.StatusNum) + CASE WHEN StatusU.URI_Path LIKE '%/status/%' Then '/xml' ELSE '' End AS Status_URI,
       MU.Verified,
	   MU.Ingest_Steps_Completed,
       MU.Entered,
	   MU.EUS_InstrumentID AS EUS_Instrument_ID,
	   MU.EUS_ProposalID AS EUS_Proposal_ID,
	   MU.EUS_UploaderID AS EUS_Uploader_ID
FROM T_MyEMSL_Uploads MU
     LEFT OUTER JOIN T_URI_Paths StatusU
       ON MU.StatusURI_PathID = StatusU.URI_PathID
     LEFT OUTER JOIN S_DMS_T_Dataset DS
       ON MU.Dataset_ID = DS.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_MyEMSL_Uploads] TO [DDL_Viewer] AS [dbo]
GO
