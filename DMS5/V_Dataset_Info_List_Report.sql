/****** Object:  View [dbo].[V_Dataset_Info_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_Info_List_Report]
AS
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
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
       -- DATEDIFF(MINUTE, ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start), ISNULL(DS.Acq_Time_End, RR.RDS_Run_Finish)) AS [Acq Length],
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)],
       DSInfo.TIC_Max_MS,
       DSInfo.TIC_Max_MSn,
       DSInfo.BPI_Max_MS,
       DSInfo.BPI_Max_MSn,
       DSInfo.TIC_Median_MS,
       DSInfo.TIC_Median_MSn,
       DSInfo.BPI_Median_MS,
       DSInfo.BPI_Median_MSn,
       DS.DS_sec_sep AS [Separation Type],
       LC.SC_Column_Number AS [LC Column],
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       DSN.DSS_name AS State,
       DSRating.DRN_name AS Rating,
       DS.DS_comment AS [Comment________________],
       DS.DS_created AS Created,
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
     LEFT OUTER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID



GO
