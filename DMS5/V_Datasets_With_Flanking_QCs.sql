/****** Object:  View [dbo].[V_Datasets_With_Flanking_QCs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Datasets_With_Flanking_QCs]
AS
SELECT Dataset_Num AS Dataset,
       Acq_Time Acq_Time_Start,
       DS_LC_column_ID AS LC_Column_ID,
       InstName.IN_name AS Instrument,
       QC_Dataset,
       SubsequentRun,
       Proximity_Rank,
       Diff_Days
FROM ( SELECT Dataset_Num,
              Acq_Time,
              DS_LC_column_ID,
              DS_instrument_name_ID,
              QC_Dataset,
              Diff_Hours / 24.0 AS Diff_Days,
              SubsequentRun,
              row_number() OVER ( PARTITION BY Dataset_Num, SubsequentRun ORDER BY Abs(Diff_Hours) ) AS 
                Proximity_Rank
       FROM ( SELECT DS.Dataset_Num,
                     ISNULL(DS.Acq_Time_Start, DS.DS_created) AS Acq_Time,
                     DS.DS_LC_column_ID,
                     DS.DS_instrument_name_ID,
                     QCDatasets.Dataset_Num AS QC_Dataset,
                     DateDiff(HOUR, ISNULL(DS.Acq_Time_Start, DS.DS_created), QCDatasets.Acq_Time) AS Diff_Hours,
					CASE WHEN (datediff(HOUR, ISNULL(DS.Acq_Time_Start, DS.DS_created), QCDatasets.Acq_Time)) < 0 
					THEN 0
					ELSE 1
					END AS SubsequentRun
              FROM T_Dataset DS
                   INNER JOIN ( SELECT QCD.Dataset_Num,
                                       ISNULL(QCD.Acq_Time_Start, QCD.DS_created) AS Acq_Time,
                                       QCD.DS_instrument_name_ID,
                                       QCD.DS_LC_column_ID
                                FROM T_Dataset QCD
                                WHERE QCD.Dataset_Num LIKE 'qc_shew%' OR 
                                      QCD.Dataset_Num LIKE 'qc_mam%' OR 
                                      QCD.Dataset_Num like 'qc_pp_mcf%' ) QCDatasets
                     ON DS.DS_instrument_name_ID = QCDatasets.DS_instrument_name_ID AND
                        DS.DS_LC_column_ID = QCDatasets.DS_LC_column_ID AND
                        DS.Dataset_Num <> QCDatasets.Dataset_Num
              WHERE Abs(DateDiff(HOUR, ISNULL(DS.Acq_Time_Start, DS.DS_created), QCDatasets.Acq_Time)) < 32 * 24 
             ) LookupQ 
   ) RankQ
     INNER JOIN T_Instrument_Name InstName
       ON InstName.Instrument_ID = RankQ.DS_instrument_name_ID
WHERE Proximity_Rank <= 4


GO
GRANT VIEW DEFINITION ON [dbo].[V_Datasets_With_Flanking_QCs] TO [DDL_Viewer] AS [dbo]
GO
