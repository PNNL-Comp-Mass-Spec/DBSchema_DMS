/****** Object:  View [dbo].[V_Reporter_Ion_Observation_Rate_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Reporter_Ion_Observation_Rate_List_Report]
AS
SELECT RIOR.Job,
       RIOR.Dataset_ID,
       DS.Dataset_Num As Dataset,
       RIOR.Reporter_Ion,
       DFP.Dataset_URL + '/' + J.AJ_resultsFolderName + '/' + DS.Dataset_Num 
       + '_RepIonObsRateHighAbundance.png' AS Observation_Rate_Link,
       DFP.Dataset_URL + '/' + J.AJ_resultsFolderName + '/' + DS.Dataset_Num 
       + '_RepIonStatsHighAbundance.png' AS Intensity_Stats_Link,
       Inst.IN_name as Instrument,
       RIOR.Channel1,
       RIOR.Channel2,
       RIOR.Channel3,
       RIOR.Channel4,
       RIOR.Channel5,
       RIOR.Channel6,
       RIOR.Channel7,
       RIOR.Channel8,
       RIOR.Channel9,
       RIOR.Channel10,
       RIOR.Channel11,
       RIOR.Channel12,
       RIOR.Channel13,
       RIOR.Channel14,
       RIOR.Channel15,
       RIOR.Channel16,
       RIOR.Channel1_Median_Intensity  AS Channel1_Intensity,
       RIOR.Channel2_Median_Intensity  AS Channel2_Intensity,
       RIOR.Channel3_Median_Intensity  AS Channel3_Intensity,
       RIOR.Channel4_Median_Intensity  AS Channel4_Intensity,
       RIOR.Channel5_Median_Intensity  AS Channel5_Intensity,
       RIOR.Channel6_Median_Intensity  AS Channel6_Intensity,
       RIOR.Channel7_Median_Intensity  AS Channel7_Intensity,
       RIOR.Channel8_Median_Intensity  AS Channel8_Intensity,
       RIOR.Channel9_Median_Intensity  AS Channel9_Intensity,
       RIOR.Channel10_Median_Intensity AS Channel10_Intensity,
       RIOR.Channel11_Median_Intensity AS Channel11_Intensity,
       RIOR.Channel12_Median_Intensity AS Channel12_Intensity,
       RIOR.Channel13_Median_Intensity AS Channel13_Intensity,
       RIOR.Channel14_Median_Intensity AS Channel14_Intensity,
       RIOR.Channel15_Median_Intensity AS Channel15_Intensity,
       RIOR.Channel16_Median_Intensity AS Channel16_Intensity,
       J.AJ_parmFileName AS [Param_File],
       RIOR.Entered
FROM T_Reporter_Ion_Observation_Rates RIOR
     INNER JOIN T_Analysis_Job J
       ON RIOR.Job = J.AJ_jobID
     INNER JOIN T_Cached_Dataset_Folder_Paths DFP
       ON J.AJ_datasetID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON J.AJ_datasetID = DS.Dataset_ID
       INNER JOIN T_Instrument_Name Inst
       ON  DS.DS_instrument_name_ID = Inst.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Reporter_Ion_Observation_Rate_List_Report] TO [DDL_Viewer] AS [dbo]
GO
