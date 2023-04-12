/****** Object:  View [dbo].[V_MyEMSL_Uploads2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MyEMSL_Uploads2]
AS
SELECT MU.Entry_ID,
       MU.Job,
       DS.Dataset_Num AS Dataset,
       MU.Dataset_ID,
       MU.Subfolder,
       MU.FileCountNew AS File_Count_New,
       MU.FileCountUpdated AS File_Count_Updated,
       CONVERT(decimal(9,3), Case When MU.Bytes / 1024.0 / 1024.0 > 999999          Then 999999 Else MU.Bytes / 1024.0 / 1024.0 End) AS MB,
       CONVERT(decimal(9,3), Case When MU.Bytes / 1024.0 / 1024.0 / 1024.0 > 999999 Then 999999 Else MU.Bytes / 1024.0 / 1024.0 / 1024.0 End) AS GB,
       CONVERT(decimal(9,1), MU.UploadTimeSeconds) AS Upload_Time_Seconds,
       MU.StatusURI_PathID AS Status_URI_Path_ID,
       MU.StatusNum AS Status_Num,
       MU.ErrorCode AS Error_Code,
	   MU.TransactionID AS Transaction_ID, 
       StatusU.URI_Path + CONVERT(varchar(12), MU.StatusNum) + 
         CASE
             WHEN StatusU.URI_Path LIKE '%/status/%' 
             THEN '/xml'
             ELSE ''
         END AS Status_URI,
       MU.Verified,
       MU.Ingest_Steps_Completed,
       MU.Entered,
       MU.EUS_InstrumentID AS EUS_Instrument_ID,
	   MU.EUS_ProposalID AS EUS_Proposal_ID,
	   MU.EUS_UploaderID AS EUS_Uploader_ID,
       TF.TransferFolderPath AS Transfer_Folder_Path,
       DI.SP_vol_name_client + DI.SP_path + DI.DS_folder_name AS Dataset_Folder_Path
FROM T_MyEMSL_Uploads MU
     LEFT OUTER JOIN T_URI_Paths StatusU
       ON MU.StatusURI_PathID = StatusU.URI_PathID
     LEFT OUTER JOIN S_DMS_T_Dataset DS
       ON MU.Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN ( SELECT DS.Dataset_ID,
                              TransferQ.SP_vol_name_client + TransferQ.SP_path + Dataset_Num AS 
                                TransferFolderPath
                       FROM S_DMS_T_Dataset DS
                            INNER JOIN S_DMS_T_Storage_Path SPath
                              ON DS.DS_storage_path_ID = SPath.SP_path_ID
                            INNER JOIN ( SELECT SP_machine_name,
                                                SP_path,
                                                SP_vol_name_client
                                         FROM S_DMS_T_Storage_Path
                                         WHERE SP_function = 'results_transfer' ) TransferQ
                              ON SPath.SP_machine_name = TransferQ.SP_machine_name ) TF
       ON MU.Dataset_ID = TF.Dataset_ID
     LEFT OUTER JOIN dbo.S_DMS_V_DatasetFullDetails DI
       ON MU.Dataset_ID = DI.Dataset_ID

GO
