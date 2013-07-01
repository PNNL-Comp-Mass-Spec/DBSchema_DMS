/****** Object:  View [dbo].[V_Dataset_QC_Metrics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Dataset_QC_Metrics]
AS
SELECT InstName.IN_Group AS [Instrument Group],
       InstName.IN_name AS Instrument,
       DS.Acq_Time_Start,
       DQC.Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DRN.DRN_name AS Dataset_Rating,
       DS.DS_rating AS Dataset_Rating_ID,
       DQC.Quameter_Job,
       DQC.XIC_WideFrac, DQC.XIC_FWHM_Q1, DQC.XIC_FWHM_Q2, DQC.XIC_FWHM_Q3, DQC.XIC_Height_Q2, DQC.XIC_Height_Q3, DQC.XIC_Height_Q4, 
       DQC.RT_Duration, DQC.RT_TIC_Q1, DQC.RT_TIC_Q2, DQC.RT_TIC_Q3, DQC.RT_TIC_Q4, DQC.RT_MS_Q1, DQC.RT_MS_Q2, DQC.RT_MS_Q3, DQC.RT_MS_Q4, 
       DQC.RT_MSMS_Q1, DQC.RT_MSMS_Q2, DQC.RT_MSMS_Q3, DQC.RT_MSMS_Q4, 
       DQC.MS1_TIC_Change_Q2, DQC.MS1_TIC_Change_Q3, DQC.MS1_TIC_Change_Q4, DQC.MS1_TIC_Q2, DQC.MS1_TIC_Q3, DQC.MS1_TIC_Q4, 
       DQC.MS1_Count, DQC.MS1_Freq_Max, DQC.MS1_Density_Q1, DQC.MS1_Density_Q2, DQC.MS1_Density_Q3, 
       DQC.MS2_Count, DQC.MS2_Freq_Max, DQC.MS2_Density_Q1, DQC.MS2_Density_Q2, DQC.MS2_Density_Q3, 
       DQC.MS2_PrecZ_1, DQC.MS2_PrecZ_2, DQC.MS2_PrecZ_3, DQC.MS2_PrecZ_4, DQC.MS2_PrecZ_5, 
       DQC.MS2_PrecZ_more, DQC.MS2_PrecZ_likely_1, DQC.MS2_PrecZ_likely_multi,
       DQC.Quameter_Last_Affected AS Quameter_Last_Affected,       
       DQC.SMAQC_Job,
       DQC.C_1A, DQC.C_1B, DQC.C_2A, DQC.C_2B, DQC.C_3A, DQC.C_3B, DQC.C_4A, DQC.C_4B, DQC.C_4C, 
       DQC.DS_1A, DQC.DS_1B, DQC.DS_2A, DQC.DS_2B, DQC.DS_3A, DQC.DS_3B, 
       DQC.IS_1A, DQC.IS_1B, DQC.IS_2, DQC.IS_3A, DQC.IS_3B, DQC.IS_3C, 
       DQC.MS1_1, DQC.MS1_2A, DQC.MS1_2B, DQC.MS1_3A, DQC.MS1_3B,
       DQC.MS1_5A, DQC.MS1_5B, DQC.MS1_5C, DQC.MS1_5D, 
       DQC.MS2_1, DQC.MS2_2, DQC.MS2_3, 
       DQC.MS2_4A, DQC.MS2_4B, DQC.MS2_4C, DQC.MS2_4D,
       DQC.P_1A, DQC.P_1B, DQC.P_2A, DQC.P_2B, DQC.P_2C, DQC.P_3,
       DQC.Last_Affected AS Smaqc_Last_Affected,
       DQC.QCDM,
       DQC.QCDM_Last_Affected
FROM T_Dataset_QC DQC
     INNER JOIN T_Dataset DS
       ON DQC.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName DRN
       ON DS.DS_rating = DRN.DRN_state_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metrics] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metrics] TO [PNL\D3M580] AS [dbo]
GO
