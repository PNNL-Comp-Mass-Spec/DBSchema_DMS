/****** Object:  View [dbo].[V_Dataset_Info_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_Info_Detail_Report]
AS
SELECT DS.Dataset_Num AS Dataset,
       TE.Experiment_Num AS Experiment,
       OG.OG_name AS Organism,
       InstName.IN_name AS Instrument,
       DTN.DST_name AS [Dataset Type],
       DSInfo.Scan_Types AS [Scan Types],
       DS.Scan_Count AS [Scan Count Total],
       DSInfo.ScanCountMS AS [Scan Count MS],
       DSInfo.ScanCountMSn AS [Scan Count MSn],
       CONVERT(decimal(9, 2), 
         CASE WHEN ISNULL(DSInfo.Elution_Time_Max, 0) < 1E6 
              THEN DSInfo.Elution_Time_Max
              ELSE 1E6
         END) AS [Elution Time Max],
       DS.Acq_Length_Minutes AS [Acq Length],
       --DATEDIFF(MINUTE, ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start), ISNULL(DS.Acq_Time_End, RR.RDS_Run_Finish)) AS [Acq Length],
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)],
       CONVERT(varchar(32), DSInfo.TIC_Max_MS) AS TIC_Max_MS,
       CONVERT(varchar(32), DSInfo.TIC_Max_MSn) AS TIC_Max_MSn,
       CONVERT(varchar(32), DSInfo.BPI_Max_MS) AS BPI_Max_MS,
       CONVERT(varchar(32), DSInfo.BPI_Max_MSn) AS BPI_Max_MSn,
       CONVERT(varchar(32), DSInfo.TIC_Median_MS) AS TIC_Median_MS,
       CONVERT(varchar(32), DSInfo.TIC_Median_MSn) AS TIC_Median_MSn,
       CONVERT(varchar(32), DSInfo.BPI_Median_MS) AS BPI_Median_MS,
       CONVERT(varchar(32), DSInfo.BPI_Median_MSn) AS BPI_Median_MSn,
       DS.DS_sec_sep AS [Separation Type],
       LCCart.Cart_Name AS [LC Cart],
       LC.SC_Column_Number AS [LC Column],
       DS.DS_wellplate_num AS [Wellplate Number],
       DS.DS_well_num AS [Well Number],
       U.Name_with_PRN AS Operator,
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       RR.RDS_Run_Start AS [Run Start],
       RR.RDS_Run_Finish AS [Run Finish],
       DSN.DSS_name AS State,
       DSRating.DRN_name AS Rating,
       DS.DS_comment AS Comment,
       DS.DS_created AS Created,
       DS.Dataset_ID AS ID,
       CASE
           WHEN DS.DS_state_ID IN (3, 4) AND
                ISNULL(DSA.AS_state_ID, 0) <> 4 THEN SPath.SP_vol_name_client + SPath.SP_path + ISNULL(DS.DS_folder_name, DS.Dataset_Num)
           ELSE '(not available)'
       END AS [Dataset Folder Path],
       CASE
           WHEN ISNULL(DSA.AS_state_ID, 0) IN (3, 4, 10, 14, 15) THEN DAP.Archive_Path + '\' + ISNULL(DS.DS_folder_name, DS.Dataset_Num)
           ELSE '(not available)'
       END AS [Archive Folder Path],
	   SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/' AS [Data Folder Link],
       SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/QC/index.html' AS [QC Link],
       DSInfo.Last_Affected AS [DSInfo Updated]
FROM T_DatasetStateName DSN
     INNER JOIN T_Dataset DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_LC_Column LC
       ON DS.DS_LC_column_ID = LC.ID
     INNER JOIN T_Dataset_Info DSInfo
       ON DS.Dataset_ID = DSInfo.Dataset_ID
     INNER JOIN dbo.T_Experiments TE
       ON DS.Exp_ID = TE.Exp_ID 
     INNER JOIN dbo.T_Organisms OG 
       ON TE.EX_organism_ID = OG.Organism_ID 
     INNER JOIN dbo.T_Users U 
       ON DS.DS_Oper_PRN = U.U_PRN
     LEFT OUTER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN T_Storage_Path SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
     LEFT OUTER JOIN dbo.T_LC_Cart LCCart 
       ON LCCart.ID = RR.RDS_Cart_ID
     LEFT OUTER JOIN dbo.T_Dataset_Archive DSA 
       ON DSA.AS_Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path DAP
       ON DS.Dataset_ID = DAP.Dataset_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Info_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
