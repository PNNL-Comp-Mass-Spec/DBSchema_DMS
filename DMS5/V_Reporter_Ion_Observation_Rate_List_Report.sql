/****** Object:  View [dbo].[V_Reporter_Ion_Observation_Rate_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Reporter_Ion_Observation_Rate_List_Report]
AS
SELECT RIOR.dataset_id,
       DS.Dataset_Num As dataset,
       RIOR.reporter_ion,
       DFP.Dataset_URL + '/' + J.AJ_resultsFolderName + '/' + DS.dataset_num + '_RepIonObsRateHighAbundance.png' AS observation_rate_link,
       DFP.Dataset_URL + '/' + J.AJ_resultsFolderName + '/' + DS.dataset_num + '_RepIonStatsHighAbundance.png' AS intensity_stats_link,
       Inst.IN_name AS instrument,
       DS.Acq_Length_Minutes AS acq_length,
       ISNULL(DS.acq_time_start, RR.RDS_Run_Start) AS acq_start,
       ISNULL(DS.acq_time_end, RR.RDS_Run_Finish) AS acq_end,
       RR.ID AS request,
       RR.RDS_BatchID AS batch,
       RIOR.job,
       J.AJ_parmFileName AS param_file,
       RIOR.channel1,
       RIOR.channel2,
       RIOR.channel3,
       RIOR.channel4,
       RIOR.channel5,
       RIOR.channel6,
       RIOR.channel7,
       RIOR.channel8,
       RIOR.channel9,
       RIOR.channel10,
       RIOR.channel11,
       RIOR.channel12,
       RIOR.channel13,
       RIOR.channel14,
       RIOR.channel15,
       RIOR.channel16,
       RIOR.Channel1_Median_Intensity  AS channel1_intensity,
       RIOR.Channel2_Median_Intensity  AS channel2_intensity,
       RIOR.Channel3_Median_Intensity  AS channel3_intensity,
       RIOR.Channel4_Median_Intensity  AS channel4_intensity,
       RIOR.Channel5_Median_Intensity  AS channel5_intensity,
       RIOR.Channel6_Median_Intensity  AS channel6_intensity,
       RIOR.Channel7_Median_Intensity  AS channel7_intensity,
       RIOR.Channel8_Median_Intensity  AS channel8_intensity,
       RIOR.Channel9_Median_Intensity  AS channel9_intensity,
       RIOR.Channel10_Median_Intensity AS channel10_intensity,
       RIOR.Channel11_Median_Intensity AS channel11_intensity,
       RIOR.Channel12_Median_Intensity AS channel12_intensity,
       RIOR.Channel13_Median_Intensity AS channel13_intensity,
       RIOR.Channel14_Median_Intensity AS channel14_intensity,
       RIOR.Channel15_Median_Intensity AS channel15_intensity,
       RIOR.Channel16_Median_Intensity AS channel16_intensity,
       RIOR.entered
FROM T_Reporter_Ion_Observation_Rates RIOR
     INNER JOIN T_Analysis_Job J
       ON RIOR.Job = J.AJ_jobID
     INNER JOIN T_Cached_Dataset_Folder_Paths DFP
       ON J.AJ_datasetID = DFP.Dataset_ID
     INNER JOIN T_Dataset DS
       ON J.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name Inst
       ON  DS.DS_instrument_name_ID = Inst.Instrument_ID
     LEFT OUTER JOIN T_Requested_Run AS RR
       ON DS.Dataset_ID = RR.DatasetID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Reporter_Ion_Observation_Rate_List_Report] TO [DDL_Viewer] AS [dbo]
GO
