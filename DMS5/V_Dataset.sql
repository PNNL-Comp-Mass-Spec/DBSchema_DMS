/****** Object:  View [dbo].[V_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Dataset] as
SELECT DS.Dataset_ID,
       DS.Dataset_Num,
       DS.DS_comment,
       DS.DS_created,
       DS.DS_state_ID,
       DSN.DSS_name AS State,
       DS.DS_rating,
       DSRating.DRN_name AS Rating,
       DS.DS_Last_Affected,
       DS.DS_instrument_name_ID,
       InstName.IN_name AS Instrument,
       DS.DS_Oper_PRN,
       DS.DS_type_ID,
       DTN.DST_name AS [Dataset Type],
       DS.DS_sec_sep,
       DS.DS_folder_name,
       DS.DS_storage_path_ID,
       DFP.Dataset_Folder_Path,
	   DFP.Dataset_URL + 'QC/index.html' AS QC_Link,
       DS.Exp_ID,
       Exp.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       DS.DS_internal_standard_ID,
       DS.Acq_Time_Start,
       DS.Acq_Time_End,
       DS.Acq_Length_Minutes,
	   DS.DS_LC_column_ID,
       DS.Scan_Count,
       DS.File_Size_Bytes,
       DS.File_Info_Last_Modified,
       DS.Dataset_Num AS Dataset,
	   DS.DateSortKey AS #date_sort_key
FROM T_DatasetStateName DSN
     INNER JOIN T_Dataset DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_Experiments Exp
       ON DS.Exp_ID = Exp.Exp_ID
     INNER JOIN T_Campaign C
       ON Exp.EX_campaign_ID = C.Campaign_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset] TO [DDL_Viewer] AS [dbo]
GO
