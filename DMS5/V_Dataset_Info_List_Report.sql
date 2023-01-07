/****** Object:  View [dbo].[V_Dataset_Info_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Info_List_Report]
AS
SELECT DS.Dataset_ID AS id,
       DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
       DTN.DST_name AS dataset_type,
       DSInfo.Scan_Types AS scan_types,
       DS.Scan_Count AS scan_count_total,
       DSInfo.ScanCountMS AS scan_count_ms,
       DSInfo.ScanCountMSn AS scan_count_msn,
       CONVERT(decimal(9, 2),
         CASE WHEN ISNULL(DSInfo.elution_time_max, 0) < 1E6
              THEN DSInfo.elution_time_max
              ELSE 1E6
         END) AS elution_time_max,
       DS.Acq_Length_Minutes AS acq_length,
       -- DATEDIFF(MINUTE, ISNULL(DS.acq_time_start, RR.RDS_Run_Start), ISNULL(DS.acq_time_end, RR.RDS_Run_Finish)) AS acq_length,
       CONVERT(decimal(9,1), DS.File_Size_Bytes / 1024.0 / 1024.0) AS file_size_mb,
       DSInfo.tic_max_ms,
       DSInfo.tic_max_msn,
       DSInfo.bpi_max_ms,
       DSInfo.bpi_max_msn,
       DSInfo.tic_median_ms,
       DSInfo.tic_median_msn,
       DSInfo.bpi_median_ms,
       DSInfo.bpi_median_msn,
       DS.DS_sec_sep AS separation_type,
       LC.SC_Column_Number AS lc_column,
       DS.Acq_Time_Start AS acquisition_start,
       DS.Acq_Time_End AS acquisition_end,
       DSN.DSS_name AS state,
       DSRating.DRN_name AS rating,
       DS.DS_comment AS comment,
       DS.DS_created AS created,
       DSInfo.Last_Affected AS dsinfo_updated
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
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Info_List_Report] TO [DDL_Viewer] AS [dbo]
GO
