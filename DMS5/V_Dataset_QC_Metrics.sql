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
       CAST(DQC.P_2C as integer) AS P_2C, 
       Cast(DQC.MassErrorPPM AS decimal(9,2)) AS MassErrorPPM,
       Cast(DQC.MassErrorPPM_VIPER AS decimal(9,2)) AS MassErrorPPM_VIPER,
       Cast(DQC.AMTs_10pct_FDR AS integer) AS AMTs_10pct_FDR,
       Cast(DQC.XIC_FWHM_Q2 AS decimal(9,1)) AS XIC_FWHM_Q2,
       Cast(DQC.XIC_WideFrac AS decimal(9,2)) AS XIC_WideFrac,       
	   CAST(DQC.Phos_2C as integer) AS Phos_2C,
	   DQC.Quameter_Job,
	   Cast(DQC.XIC_FWHM_Q1 AS decimal(9,3)) AS XIC_FWHM_Q1,
	   Cast(DQC.XIC_FWHM_Q3 AS decimal(9,3)) AS XIC_FWHM_Q3,
	   Cast(DQC.XIC_Height_Q2 AS decimal(9,3)) AS XIC_Height_Q2,
	   Cast(DQC.XIC_Height_Q3 AS decimal(9,3)) AS XIC_Height_Q3,
	   Cast(DQC.XIC_Height_Q4 AS decimal(9,3)) AS XIC_Height_Q4,
	   Cast(DQC.RT_Duration AS decimal(9,3)) AS RT_Duration,
	   Cast(DQC.RT_TIC_Q1 AS decimal(9,3)) AS RT_TIC_Q1,
	   Cast(DQC.RT_TIC_Q2 AS decimal(9,3)) AS RT_TIC_Q2,
	   Cast(DQC.RT_TIC_Q3 AS decimal(9,3)) AS RT_TIC_Q3,
	   Cast(DQC.RT_TIC_Q4 AS decimal(9,3)) AS RT_TIC_Q4,
	   Cast(DQC.RT_MS_Q1 AS decimal(9,3)) AS RT_MS_Q1,
	   Cast(DQC.RT_MS_Q2 AS decimal(9,3)) AS RT_MS_Q2,
	   Cast(DQC.RT_MS_Q3 AS decimal(9,3)) AS RT_MS_Q3,
	   Cast(DQC.RT_MS_Q4 AS decimal(9,3)) AS RT_MS_Q4,
	   Cast(DQC.RT_MSMS_Q1 AS decimal(9,3)) AS RT_MSMS_Q1,
	   Cast(DQC.RT_MSMS_Q2 AS decimal(9,3)) AS RT_MSMS_Q2,
	   Cast(DQC.RT_MSMS_Q3 AS decimal(9,3)) AS RT_MSMS_Q3,
	   Cast(DQC.RT_MSMS_Q4 AS decimal(9,3)) AS RT_MSMS_Q4,
	   Cast(DQC.MS1_TIC_Change_Q2 AS decimal(9,3)) AS MS1_TIC_Change_Q2,
	   Cast(DQC.MS1_TIC_Change_Q3 AS decimal(9,3)) AS MS1_TIC_Change_Q3,
	   Cast(DQC.MS1_TIC_Change_Q4 AS decimal(9,3)) AS MS1_TIC_Change_Q4,
	   Cast(DQC.MS1_TIC_Q2 AS decimal(9,3)) AS MS1_TIC_Q2,
	   Cast(DQC.MS1_TIC_Q3 AS decimal(9,3)) AS MS1_TIC_Q3,
	   Cast(DQC.MS1_TIC_Q4 AS decimal(9,3)) AS MS1_TIC_Q4,
	   CAST(DQC.MS1_Count as integer) AS MS1_Count,
	   Cast(DQC.MS1_Freq_Max AS decimal(9,3)) AS MS1_Freq_Max,
	   CAST(DQC.MS1_Density_Q1 as integer) AS MS1_Density_Q1,
	   CAST(DQC.MS1_Density_Q2 as integer) AS MS1_Density_Q2,
	   CAST(DQC.MS1_Density_Q3 as integer) AS MS1_Density_Q3,
	   CAST(DQC.MS2_Count as integer) AS MS2_Count,
	   Cast(DQC.MS2_Freq_Max AS decimal(9,3)) AS MS2_Freq_Max,
	   DQC.MS2_Density_Q1,
	   DQC.MS2_Density_Q2,
	   DQC.MS2_Density_Q3,
	   Cast(DQC.MS2_PrecZ_1 AS decimal(9,3)) AS MS2_PrecZ_1,
	   Cast(DQC.MS2_PrecZ_2 AS decimal(9,3)) AS MS2_PrecZ_2,
	   Cast(DQC.MS2_PrecZ_3 AS decimal(9,3)) AS MS2_PrecZ_3,
	   Cast(DQC.MS2_PrecZ_4 AS decimal(9,3)) AS MS2_PrecZ_4,
	   Cast(DQC.MS2_PrecZ_5 AS decimal(9,3)) AS MS2_PrecZ_5,
	   Cast(DQC.MS2_PrecZ_more AS decimal(9,3)) AS MS2_PrecZ_more,
	   Cast(DQC.MS2_PrecZ_likely_1 AS decimal(9,3)) AS MS2_PrecZ_likely_1,
	   Cast(DQC.MS2_PrecZ_likely_multi AS decimal(9,3)) AS MS2_PrecZ_likely_multi,
	   DQC.Quameter_Last_Affected AS Quameter_Last_Affected,
	   DQC.SMAQC_Job,
	   Cast(DQC.C_1A AS decimal(9,3)) AS C_1A,
	   Cast(DQC.C_1B AS decimal(9,3)) AS C_1B,
	   Cast(DQC.C_2A AS decimal(9,3)) AS C_2A,
	   Cast(DQC.C_2B AS decimal(9,3)) AS C_2B,
	   Cast(DQC.C_3A AS decimal(9,3)) AS C_3A,
	   Cast(DQC.C_3B AS decimal(9,3)) AS C_3B,
	   Cast(DQC.C_4A AS decimal(9,3)) AS C_4A,
	   Cast(DQC.C_4B AS decimal(9,3)) AS C_4B,
	   Cast(DQC.C_4C AS decimal(9,3)) AS C_4C,
	   Cast(DQC.DS_1A AS decimal(9,3)) AS DS_1A,
	   Cast(DQC.DS_1B AS decimal(9,3)) AS DS_1B,
	   CAST(DQC.DS_2A as integer) AS DS_2A,
	   CAST(DQC.DS_2B as integer) AS DS_2B,
	   Cast(DQC.DS_3A AS decimal(9,3)) AS DS_3A,
	   Cast(DQC.DS_3B AS decimal(9,3)) AS DS_3B,
	   CAST(DQC.IS_1A as integer) AS IS_1A,
	   CAST(DQC.IS_1B as integer) AS IS_1B,
	   Cast(DQC.IS_2 AS decimal(9,3)) AS IS_2,
	   Cast(DQC.IS_3A AS decimal(9,3)) AS IS_3A,
	   Cast(DQC.IS_3B AS decimal(9,3)) AS IS_3B,
	   Cast(DQC.IS_3C AS decimal(9,3)) AS IS_3C,
	   Cast(DQC.MS1_1 AS decimal(9,3)) AS MS1_1,
	   Cast(DQC.MS1_2A AS decimal(9,3)) AS MS1_2A,
	   DQC.MS1_2B,    -- Do not cast because can be large
	   DQC.MS1_3A,    -- Do not cast because can be large
	   DQC.MS1_3B,    -- Do not cast because can be large	   
	   Cast(DQC.MS1_5A AS decimal(9,3)) AS MS1_5A,
	   Cast(DQC.MS1_5B AS decimal(9,3)) AS MS1_5B,
	   Cast(DQC.MS1_5C AS decimal(9,3)) AS MS1_5C,
	   Cast(DQC.MS1_5D AS decimal(9,3)) AS MS1_5D,
	   Cast(DQC.MS2_1 AS decimal(9,3)) AS MS2_1,
	   Cast(DQC.MS2_2 AS decimal(9,3)) AS MS2_2,
	   CAST(DQC.MS2_3 as integer) AS MS2_3,
	   Cast(DQC.MS2_4A AS decimal(9,3)) AS MS2_4A,
	   Cast(DQC.MS2_4B AS decimal(9,3)) AS MS2_4B,
	   Cast(DQC.MS2_4C AS decimal(9,3)) AS MS2_4C,
	   Cast(DQC.MS2_4D AS decimal(9,3)) AS MS2_4D,
	   Cast(DQC.P_1A AS decimal(9,3)) AS P_1A,
	   Cast(DQC.P_1B AS decimal(9,3)) AS P_1B,
	   CAST(DQC.P_2A as integer) AS P_2A,
	   CAST(DQC.P_2B as integer) AS P_2B,
	   Cast(DQC.P_3 AS decimal(9,3)) AS P_3,
	   CAST(DQC.Phos_2A as integer) AS Phos_2A,
	   CAST(DQC.Keratin_2A as integer) AS Keratin_2A,
	   Cast(DQC.P_4A AS decimal(9,3)) AS P_4A,
	   Cast(DQC.P_4B AS decimal(9,3)) AS P_4B,
	   Cast(DQC.MassErrorPPM_Refined AS decimal(9,2)) AS MassErrorPPM_Refined,
	   DQC.Last_Affected AS Smaqc_Last_Affected,
	   DQC.PSM_Source_Job,
	   Cast(DQC.QCDM AS decimal(9,3)) AS QCDM,
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
