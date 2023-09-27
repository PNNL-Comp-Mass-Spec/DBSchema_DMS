/****** Object:  View [dbo].[V_Data_Package_Dataset_Files_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Dataset_Files_List_Report]
AS
SELECT DPD.Data_Pkg_ID AS id,
       DL.dataset,
       DPD.dataset_id,
       DF.file_path,
       DF.file_size_bytes,
       DF.file_hash,
       DF.file_size_rank,
       DL.experiment,
       DL.instrument,
       DPD.package_comment,
       DL.campaign,
       DL.state,
       DL.created,
       DL.rating,
       DL.dataset_folder_path,
       DL.acq_start,
       DL.acq_end,
       DL.acq_length,
       DL.scan_count,
       DL.lc_column,
       DL.separation_type,
       DL.request,
       DPD.item_added,
       DL.comment,
       DL.dataset_type
FROM dbo.T_Data_Package_Datasets AS DPD
     INNER JOIN dbo.S_V_Dataset_List_Report_2 AS DL
       ON DPD.Dataset_ID = DL.ID
     LEFT OUTER JOIN (
        SELECT Dataset_ID,
               File_Path,
               File_Size_Bytes,
               File_Hash,
               File_Size_Rank,
               Dataset_File_ID
        FROM dbo.S_Dataset_Files
        WHERE Deleted = 0
     ) DF ON DPD.Dataset_ID = DF.Dataset_ID

GO
