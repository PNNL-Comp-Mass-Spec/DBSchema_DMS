/****** Object:  View [dbo].[V_Dataset_QC_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_QC_List_Report] as
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/QC/' + DS.Dataset_Num + '_BPI_MS.png' AS QC_Link,
       Exp.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DS.DS_comment AS [Comment],
       DSN.DSS_name AS State,
       DSRating.DRN_name AS Rating,
       DTN.DST_name AS [Dataset Type],
       DS.DS_Oper_PRN AS Operator,
       LC.SC_Column_Number AS [LC Column],
       RRH.ID AS Request,
       ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start) AS [Acq Start],
       ISNULL(DS.Acq_Time_End, RRH.RDS_Run_Finish) AS [Acq. End],
       DS.Acq_Length_Minutes AS [Acq Length],
       --DATEDIFF(MINUTE, ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start), ISNULL(DS.Acq_Time_End, RRH.RDS_Run_Finish)) AS [Acq Length],
       DS.DS_sec_sep AS [Separation Type]
       -- QCM.*
FROM T_DatasetStateName AS DSN
     INNER JOIN T_Dataset AS DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName AS DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_Experiments AS Exp
       ON DS.Exp_ID = Exp.Exp_ID
     INNER JOIN T_Campaign AS C
       ON Exp.EX_campaign_ID = C.Campaign_ID
     INNER JOIN t_storage_path AS SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
     INNER JOIN T_LC_Column AS LC
       ON DS.DS_LC_column_ID = LC.ID
     LEFT OUTER JOIN T_Requested_Run AS RRH
       ON DS.Dataset_ID = RRH.DatasetID
     -- LEFT OUTER JOIN V_Dataset_QC_Metrics QCM ON DS.Dataset_ID = QCM.Dataset_ID


GO
