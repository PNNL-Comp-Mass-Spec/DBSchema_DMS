/****** Object:  Table [dbo].[T_Dataset_QC] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_QC](
	[Dataset_ID] [int] NOT NULL,
	[SMAQC_Job] [int] NULL,
	[PSM_Source_Job] [int] NULL,
	[Last_Affected] [datetime] NULL,
	[C_1A] [real] NULL,
	[C_1B] [real] NULL,
	[C_2A] [real] NULL,
	[C_2B] [real] NULL,
	[C_3A] [real] NULL,
	[C_3B] [real] NULL,
	[C_4A] [real] NULL,
	[C_4B] [real] NULL,
	[C_4C] [real] NULL,
	[DS_1A] [real] NULL,
	[DS_1B] [real] NULL,
	[DS_2A] [real] NULL,
	[DS_2B] [real] NULL,
	[DS_3A] [real] NULL,
	[DS_3B] [real] NULL,
	[IS_1A] [real] NULL,
	[IS_1B] [real] NULL,
	[IS_2] [real] NULL,
	[IS_3A] [real] NULL,
	[IS_3B] [real] NULL,
	[IS_3C] [real] NULL,
	[MS1_1] [real] NULL,
	[MS1_2A] [real] NULL,
	[MS1_2B] [real] NULL,
	[MS1_3A] [real] NULL,
	[MS1_3B] [real] NULL,
	[MS1_5A] [real] NULL,
	[MS1_5B] [real] NULL,
	[MS1_5C] [real] NULL,
	[MS1_5D] [real] NULL,
	[MS2_1] [real] NULL,
	[MS2_2] [real] NULL,
	[MS2_3] [real] NULL,
	[MS2_4A] [real] NULL,
	[MS2_4B] [real] NULL,
	[MS2_4C] [real] NULL,
	[MS2_4D] [real] NULL,
	[P_1A] [real] NULL,
	[P_1B] [real] NULL,
	[P_2A] [real] NULL,
	[P_2B] [real] NULL,
	[P_2C] [real] NULL,
	[P_3] [real] NULL,
	[Quameter_Job] [int] NULL,
	[Quameter_Last_Affected] [datetime] NULL,
	[XIC_WideFrac] [real] NULL,
	[XIC_FWHM_Q1] [real] NULL,
	[XIC_FWHM_Q2] [real] NULL,
	[XIC_FWHM_Q3] [real] NULL,
	[XIC_Height_Q2] [real] NULL,
	[XIC_Height_Q3] [real] NULL,
	[XIC_Height_Q4] [real] NULL,
	[RT_Duration] [real] NULL,
	[RT_TIC_Q1] [real] NULL,
	[RT_TIC_Q2] [real] NULL,
	[RT_TIC_Q3] [real] NULL,
	[RT_TIC_Q4] [real] NULL,
	[RT_MS_Q1] [real] NULL,
	[RT_MS_Q2] [real] NULL,
	[RT_MS_Q3] [real] NULL,
	[RT_MS_Q4] [real] NULL,
	[RT_MSMS_Q1] [real] NULL,
	[RT_MSMS_Q2] [real] NULL,
	[RT_MSMS_Q3] [real] NULL,
	[RT_MSMS_Q4] [real] NULL,
	[MS1_TIC_Change_Q2] [real] NULL,
	[MS1_TIC_Change_Q3] [real] NULL,
	[MS1_TIC_Change_Q4] [real] NULL,
	[MS1_TIC_Q2] [real] NULL,
	[MS1_TIC_Q3] [real] NULL,
	[MS1_TIC_Q4] [real] NULL,
	[MS1_Count] [real] NULL,
	[MS1_Freq_Max] [real] NULL,
	[MS1_Density_Q1] [real] NULL,
	[MS1_Density_Q2] [real] NULL,
	[MS1_Density_Q3] [real] NULL,
	[MS2_Count] [real] NULL,
	[MS2_Freq_Max] [real] NULL,
	[MS2_Density_Q1] [real] NULL,
	[MS2_Density_Q2] [real] NULL,
	[MS2_Density_Q3] [real] NULL,
	[MS2_PrecZ_1] [real] NULL,
	[MS2_PrecZ_2] [real] NULL,
	[MS2_PrecZ_3] [real] NULL,
	[MS2_PrecZ_4] [real] NULL,
	[MS2_PrecZ_5] [real] NULL,
	[MS2_PrecZ_more] [real] NULL,
	[MS2_PrecZ_likely_1] [real] NULL,
	[MS2_PrecZ_likely_multi] [real] NULL,
	[QCDM_Last_Affected] [datetime] NULL,
	[QCDM] [real] NULL,
	[MassErrorPPM] [real] NULL,
	[MassErrorPPM_Refined] [real] NULL,
	[MassErrorPPM_VIPER] [numeric](9, 4) NULL,
	[AMTs_10pct_FDR] [int] NULL,
	[Phos_2A] [real] NULL,
	[Phos_2C] [real] NULL,
	[Keratin_2A] [real] NULL,
	[Keratin_2C] [real] NULL,
	[P_4A] [real] NULL,
	[P_4B] [real] NULL,
	[QCART] [real] NULL,
 CONSTRAINT [PK_T_Dataset_QC_DatasetID] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
