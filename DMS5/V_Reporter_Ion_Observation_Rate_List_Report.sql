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
       + '_RepIonObsRateHighAbundance.png' AS ObsRate_TopNPct_Link,
       DFP.Dataset_URL + '/' + J.AJ_resultsFolderName + '/' + DS.Dataset_Num + '_RepIonObsRate.png' 
         AS ObsRate_All_Link,
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
       RIOR.Channel1_All,
       RIOR.Channel2_All,
       RIOR.Channel3_All,
       RIOR.Channel4_All,
       RIOR.Channel5_All,
       RIOR.Channel6_All,
       RIOR.Channel7_All,
       RIOR.Channel8_All,
       RIOR.Channel9_All,
       RIOR.Channel10_All,
       RIOR.Channel11_All,
       RIOR.Channel12_All,
       RIOR.Channel13_All,
       RIOR.Channel14_All,
       RIOR.Channel15_All,
       RIOR.Channel16_All,
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
