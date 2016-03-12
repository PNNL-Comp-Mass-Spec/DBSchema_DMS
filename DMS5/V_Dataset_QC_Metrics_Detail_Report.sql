/****** Object:  View [dbo].[V_Dataset_QC_Metrics_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_QC_Metrics_Detail_Report
AS
SELECT DISTINCT
    [Instrument Group],
    Instrument,
    Acq_Time_Start,
    Dataset_ID,
    Dataset,
    [Dataset Folder Path],
    [QC Metric Stats],
    Quameter_Job,
    Cast(XIC_WideFrac as varchar(12)) + '; Fraction of precursor ions accounting for the top half of all peak width' AS XIC_WideFrac,
    Cast(XIC_FWHM_Q1 as varchar(12)) + ' seconds; 25%ile of peak widths for the wide XICs' AS XIC_FWHM_Q1,
    Cast(XIC_FWHM_Q2 as varchar(12)) + ' seconds; 50%ile of peak widths for the wide XICs' AS XIC_FWHM_Q2,
    Cast(XIC_FWHM_Q3 as varchar(12)) + ' seconds; 75%ile of peak widths for the wide XICs' AS XIC_FWHM_Q3,
    Cast(XIC_Height_Q2 as varchar(12)) + '; The log ratio for 50%ile of wide XIC heights over 25%ile of heights.' AS XIC_Height_Q2,
    Cast(XIC_Height_Q3 as varchar(12)) + '; The log ratio for 75%ile of wide XIC heights over 50%ile of heights.' AS XIC_Height_Q3,
    Cast(XIC_Height_Q4 as varchar(12)) + '; The log ratio for maximum of wide XIC heights over 75%ile of heights.' AS XIC_Height_Q4,
    Cast(RT_Duration as varchar(12)) + ' seconds; Highest scan time observed minus the lowest scan time observed' AS RT_Duration,
    Cast(RT_TIC_Q1 as varchar(12)) + '; The interval when the first 25% of TIC accumulates divided by RT-Duration' AS RT_TIC_Q1,
    Cast(RT_TIC_Q2 as varchar(12)) + '; The interval when the second 25% of TIC accumulates divided by RT-Duration' AS RT_TIC_Q2,
    Cast(RT_TIC_Q3 as varchar(12)) + '; The interval when the third 25% of TIC accumulates divided by RT-Duration' AS RT_TIC_Q3,
    Cast(RT_TIC_Q4 as varchar(12)) + '; The interval when the fourth 25% of TIC accumulates divided by RT-Duration' AS RT_TIC_Q4,
    Cast(RT_MS_Q1 as varchar(12)) + '; The interval for the first 25% of all MS events divided by RT-Duration' AS RT_MS_Q1,
    Cast(RT_MS_Q2 as varchar(12)) + '; The interval for the second 25% of all MS events divided by RT-Duration' AS RT_MS_Q2,
    Cast(RT_MS_Q3 as varchar(12)) + '; The interval for the third 25% of all MS events divided by RT-Duration' AS RT_MS_Q3,
    Cast(RT_MS_Q4 as varchar(12)) + '; The interval for the fourth 25% of all MS events divided by RT-Duration' AS RT_MS_Q4,
    Cast(RT_MSMS_Q1 as varchar(12)) + '; The interval for the first 25% of all MS/MS events divided by RT-Duration' AS RT_MSMS_Q1,
    Cast(RT_MSMS_Q2 as varchar(12)) + '; The interval for the second 25% of all MS/MS events divided by RT-Duration' AS RT_MSMS_Q2,
    Cast(RT_MSMS_Q3 as varchar(12)) + '; The interval for the third 25% of all MS/MS events divided by RT-Duration' AS RT_MSMS_Q3,
    Cast(RT_MSMS_Q4 as varchar(12)) + '; The interval for the fourth 25% of all MS/MS events divided by RT-Duration' AS RT_MSMS_Q4,
    Cast(MS1_TIC_Change_Q2 as varchar(12)) + '; The log ratio for 50%ile of TIC changes over 25%ile of TIC changes' AS MS1_TIC_Change_Q2,
    Cast(MS1_TIC_Change_Q3 as varchar(12)) + '; The log ratio for 75%ile of TIC changes over 50%ile of TIC changes' AS MS1_TIC_Change_Q3,
    Cast(MS1_TIC_Change_Q4 as varchar(12)) + '; The log ratio for largest TIC change over 75%ile of TIC changes' AS MS1_TIC_Change_Q4,
    Cast(MS1_TIC_Q2 as varchar(12)) + '; The log ratio for 50%ile of TIC over 25%ile of TIC' AS MS1_TIC_Q2,
    Cast(MS1_TIC_Q3 as varchar(12)) + '; The log ratio for 75%ile of TIC over 50%ile of TIC' AS MS1_TIC_Q3,
    Cast(MS1_TIC_Q4 as varchar(12)) + '; The log ratio for largest TIC over 75%ile TIC' AS MS1_TIC_Q4,
    Cast(MS1_Count as varchar(12)) + '; Number of MS spectra collected' AS MS1_Count,
    Cast(MS1_Freq_Max as varchar(12)) + ' Hz; Fastest frequency for MS collection in any minute' AS MS1_Freq_Max,
    Cast(MS1_Density_Q1 as varchar(12)) + '; 25%ile of MS scan peak counts' AS MS1_Density_Q1,
    Cast(MS1_Density_Q2 as varchar(12)) + '; 50%ile of MS scan peak counts' AS MS1_Density_Q2,
    Cast(MS1_Density_Q3 as varchar(12)) + '; 75%ile of MS scan peak counts' AS MS1_Density_Q3,
    Cast(MS2_Count as varchar(12)) + '; Number of MS/MS spectra collected' AS MS2_Count,
    Cast(MS2_Freq_Max as varchar(12)) + ' Hz; Fastest frequency for MS/MS collection in any minute' AS MS2_Freq_Max,
    Cast(MS2_Density_Q1 as varchar(12)) + '; 25%ile of MS/MS scan peak counts' AS MS2_Density_Q1,
    Cast(MS2_Density_Q2 as varchar(12)) + '; 50%ile of MS/MS scan peak counts' AS MS2_Density_Q2,
    Cast(MS2_Density_Q3 as varchar(12)) + '; 75%ile of MS/MS scan peak counts' AS MS2_Density_Q3,
    Cast(MS2_PrecZ_1 as varchar(12)) + '; Fraction of MS/MS precursors that are singly charged' AS MS2_PrecZ_1,
    Cast(MS2_PrecZ_2 as varchar(12)) + '; Fraction of MS/MS precursors that are doubly charged' AS MS2_PrecZ_2,
    Cast(MS2_PrecZ_3 as varchar(12)) + '; Fraction of MS/MS precursors that are triply charged' AS MS2_PrecZ_3,
    Cast(MS2_PrecZ_4 as varchar(12)) + '; Fraction of MS/MS precursors that are quadruply charged' AS MS2_PrecZ_4,
    Cast(MS2_PrecZ_5 as varchar(12)) + '; Fraction of MS/MS precursors that are quintuply charged' AS MS2_PrecZ_5,
    Cast(MS2_PrecZ_more as varchar(12)) + '; Fraction of MS/MS precursors that are charged higher than +5' AS MS2_PrecZ_more,
    Cast(MS2_PrecZ_likely_1 as varchar(12)) + '; Fraction of MS/MS precursors lack known charge but look like 1+' AS MS2_PrecZ_likely_1,
    Cast(MS2_PrecZ_likely_multi as varchar(12)) + '; Fraction of MS/MS precursors lack known charge but look like 2+ or higher' AS MS2_PrecZ_likely_multi,
    Quameter_Last_Affected,
    SMAQC_Job,
    Cast(C_1A as varchar(12)) + '; Fraction of peptides identified more than 4 minutes earlier than the chromatographic peak apex' AS C_1A,
    Cast(C_1B as varchar(12)) + '; Fraction of peptides identified more than 4 minutes later than the chromatographic peak apex' AS C_1B,
    Cast(C_2A as varchar(12)) + ' minutes; Time period over which 50% of peptides are identified' AS C_2A,
    Cast(C_2B as varchar(12)) + '; Rate of peptide identification during C-2A' AS C_2B,
    Cast(C_3A as varchar(12)) + ' seconds; Median peak width for all peptides' AS C_3A,
    Cast(C_3B as varchar(12)) + ' seconds; Median peak width during middle 50% of separation' AS C_3B,
    Cast(C_4A as varchar(12)) + ' seconds; Median peak width during first 10% of separation' AS C_4A,
    Cast(C_4B as varchar(12)) + ' seconds; Median peak width during last 10% of separation' AS C_4B,
    Cast(C_4C as varchar(12)) + ' seconds; Median peak width during middle 10% of separation' AS C_4C,
    Cast(DS_1A as varchar(12)) + '; Count of peptides with one spectrum / count of peptides with two spectra' AS DS_1A,
    Cast(DS_1B as varchar(12)) + '; Count of peptides with two spectra / count of peptides with three spectra' AS DS_1B,
    Cast(DS_2A as varchar(12)) + '; Number of MS1 scans taken over middle 50% of separation' AS DS_2A,
    Cast(DS_2B as varchar(12)) + '; Number of MS2 scans taken over middle 50% of separation' AS DS_2B,
    Cast(DS_3A as varchar(12)) + '; Median of MS1 max / MS1 sampled abundance' AS DS_3A,
    Cast(DS_3B as varchar(12)) + '; Median of MS1 max / MS1 sampled abundance; limit to bottom 50% of peptides by abundance' AS DS_3B,
    Cast(IS_1A as varchar(12)) + '; Occurrences of MS1 jumping >10x' AS IS_1A,
    Cast(IS_1B as varchar(12)) + '; Occurrences of MS1 falling >10x' AS IS_1B,
    Cast(IS_2 as varchar(12)) + '; Median precursor m/z for all peptides' AS IS_2,
    Cast(IS_3A as varchar(12)) + '; Count of 1+ peptides / count of 2+ peptides' AS IS_3A,
    Cast(IS_3B as varchar(12)) + '; Count of 3+ peptides / count of 2+ peptides' AS IS_3B,
    Cast(IS_3C as varchar(12)) + '; Count of 4+ peptides / count of 2+ peptides' AS IS_3C,
    Cast(MS1_1 as varchar(12)) + ' milliseconds; Median MS1 ion injection time' AS MS1_1,
    Cast(MS1_2A as varchar(12)) + '; Median S/N value for MS1 spectra from run start through middle 50% of separation' AS MS1_2A,
    Cast(MS1_2B as varchar(12)) + '; Median TIC value for identified peptides from run start through middle 50% of separation' AS MS1_2B,
    Cast(MS1_3A as varchar(12)) + '; Dynamic range estimate using 95th percentile peptide peak apex intensity / 5th percentile' AS MS1_3A,
    Cast(MS1_3B as varchar(12)) + '; Median peak apex intensity for all peptides' AS MS1_3B,
    Cast(MS1_5A as varchar(12)) + ' Th; Median of precursor mass error' AS MS1_5A,
    Cast(MS1_5B as varchar(12)) + ' Th; Median of absolute value of precursor mass error' AS MS1_5B,
    Cast(MS1_5C as varchar(12)) + ' ppm; Median of precursor mass error' AS MS1_5C,
    Cast(MS1_5D as varchar(12)) + ' ppm; Interquartile distance in ppm-based precursor mass error' AS MS1_5D,
    Cast(MS2_1 as varchar(12)) + ' milliseconds; Median MS2 ion injection time for identified peptides' AS MS2_1,
    Cast(MS2_2 as varchar(12)) + '; Median S/N value for identified MS2 spectra' AS MS2_2,
    Cast(MS2_3 as varchar(12)) + '; Median number of peaks in all MS2 spectra' AS MS2_3,
    Cast(MS2_4A as varchar(12)) + '; Fraction of all MS2 spectra identified; low abundance quartile (determined using MS1 intensity of identified peptides)' AS MS2_4A,
    Cast(MS2_4B as varchar(12)) + '; Fraction of all MS2 spectra identified; second quartile (determined using MS1 intensity of identified peptides)' AS MS2_4B,
    Cast(MS2_4C as varchar(12)) + '; Fraction of all MS2 spectra identified; third quartile (determined using MS1 intensity of identified peptides)' AS MS2_4C,
    Cast(MS2_4D as varchar(12)) + '; Fraction of all MS2 spectra identified; high abundance quartile (determined using MS1 intensity of identified peptides)' AS MS2_4D,
    Cast(P_1A as varchar(12)) + '; Median peptide ID score (-Log10(MSGF_SpecProb) or X!Tandem hyperscore)' AS P_1A,
    Cast(P_1B as varchar(12)) + '; Median peptide ID score ( Log10(MSGF_SpecProb) or X!Tandem Peptide_Expectation_Value_Log(e))' AS P_1B,
    Cast(P_2A as varchar(12)) + '; Number of tryptic peptides; total spectra count' AS P_2A,
    Cast(P_2B as varchar(12)) + '; Number of tryptic peptides; unique peptide & charge count' AS P_2B,
    Cast(P_2C as varchar(12)) + '; Number of tryptic peptides; unique peptide count' AS P_2C,
    Cast(P_3 as varchar(12)) + '; Ratio of unique semi-tryptic / unique fully tryptic peptides' AS P_3,
    Cast(Phos_2A as varchar(12)) + '; Number of tryptic phosphopeptides; total spectra count' AS Phos_2A,
    Cast(Phos_2C as varchar(12)) + '; Number of tryptic phosphopeptides; unique peptide count' AS Phos_2C,
    Cast(Keratin_2A as varchar(12)) + '; Number of keratin peptides (full or partial trypsin); total spectra count' AS Keratin_2A,
    Cast(Keratin_2C as varchar(12)) + '; Number of keratin peptides (full or partial trypsin); unique peptide count' AS Keratin_2C,
    Cast(P_4A as varchar(12)) + '; Ratio of unique fully tryptic peptides / total unique peptides' AS P_4A,
    Cast(P_4B as varchar(12)) + '; Ratio of total missed cleavages (among unique peptides) / total unique peptides' AS P_4B,
    Cast(Trypsin_2A as varchar(12)) + '; Number of peptides from trypsin; total spectra count' AS Trypsin_2A,
    Cast(Trypsin_2C as varchar(12)) + '; Number of peptides from trypsin; unique peptide count' AS Trypsin_2C,
	Cast(MS2_RepIon_All as varchar(12)) + '; Number of peptides (PSMs) where all reporter ions were seen' AS MS2_RepIon_All,
	Cast(MS2_RepIon_1Missing as varchar(12)) + '; Number of peptides (PSMs) where all but 1 of the reporter ions were seen' AS MS2_RepIon_1Missing,
	Cast(MS2_RepIon_2Missing as varchar(12)) + '; Number of peptides (PSMs) where all but 2 of the reporter ions were seen' AS MS2_RepIon_2Missing,
	Cast(MS2_RepIon_3Missing as varchar(12)) + '; Number of peptides (PSMs) where all but 3 of the reporter ions were seen' AS MS2_RepIon_3Missing,
    SMAQC_Last_Affected,
    Cast(QCDM as varchar(12)) + '; Overall confidence using model developed by Brett Amidan' AS QCDM,
    QCDM_Last_Affected,
    MassErrorPPM,
    MassErrorPPM_Refined,
    MassErrorPPM_VIPER,
    AMTs_10pct_FDR,
    Cast(QCART as varchar(12)) + '; Overall confidence using model developed by Allison Thompson and Ryan Butner' AS QCART
	FROM (SELECT InstName.IN_Group AS [Instrument Group],
		   InstName.IN_name AS Instrument,
		   DS.Acq_Time_Start,
		   DQC.Dataset_ID,
		   DS.Dataset_Num AS Dataset,
		   DFP.Dataset_Folder_Path AS [Dataset Folder Path],
		   'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name AS 'QC Metric Stats',
		   DQC.Quameter_Job,
			Cast(DQC.XIC_WideFrac AS Decimal(9,3)) AS XIC_WideFrac,  
			Cast(DQC.XIC_FWHM_Q1 AS Decimal(9,3)) AS XIC_FWHM_Q1,  
			Cast(DQC.XIC_FWHM_Q2 AS Decimal(9,3)) AS XIC_FWHM_Q2,  
			Cast(DQC.XIC_FWHM_Q3 AS Decimal(9,3)) AS XIC_FWHM_Q3,  
			Cast(DQC.XIC_Height_Q2 AS Decimal(9,3)) AS XIC_Height_Q2,  
			Cast(DQC.XIC_Height_Q3 AS Decimal(9,3)) AS XIC_Height_Q3,  
			Cast(DQC.XIC_Height_Q4 AS Decimal(9,3)) AS XIC_Height_Q4,  
			Cast(DQC.RT_Duration AS Decimal(9,3)) AS RT_Duration,  
			Cast(DQC.RT_TIC_Q1 AS Decimal(9,3)) AS RT_TIC_Q1,  
			Cast(DQC.RT_TIC_Q2 AS Decimal(9,3)) AS RT_TIC_Q2,  
			Cast(DQC.RT_TIC_Q3 AS Decimal(9,3)) AS RT_TIC_Q3,  
			Cast(DQC.RT_TIC_Q4 AS Decimal(9,3)) AS RT_TIC_Q4,  
			Cast(DQC.RT_MS_Q1 AS Decimal(9,3)) AS RT_MS_Q1,  
			Cast(DQC.RT_MS_Q2 AS Decimal(9,3)) AS RT_MS_Q2,  
			Cast(DQC.RT_MS_Q3 AS Decimal(9,3)) AS RT_MS_Q3,  
			Cast(DQC.RT_MS_Q4 AS Decimal(9,3)) AS RT_MS_Q4,  
			Cast(DQC.RT_MSMS_Q1 AS Decimal(9,3)) AS RT_MSMS_Q1,  
			Cast(DQC.RT_MSMS_Q2 AS Decimal(9,3)) AS RT_MSMS_Q2,  
			Cast(DQC.RT_MSMS_Q3 AS Decimal(9,3)) AS RT_MSMS_Q3,  
			Cast(DQC.RT_MSMS_Q4 AS Decimal(9,3)) AS RT_MSMS_Q4,  
			Cast(DQC.MS1_TIC_Change_Q2 AS Decimal(9,3)) AS MS1_TIC_Change_Q2,  
			Cast(DQC.MS1_TIC_Change_Q3 AS Decimal(9,3)) AS MS1_TIC_Change_Q3,  
			Cast(DQC.MS1_TIC_Change_Q4 AS Decimal(9,3)) AS MS1_TIC_Change_Q4,  
			Cast(DQC.MS1_TIC_Q2 AS Decimal(9,3)) AS MS1_TIC_Q2,  
			Cast(DQC.MS1_TIC_Q3 AS Decimal(9,3)) AS MS1_TIC_Q3,  
			Cast(DQC.MS1_TIC_Q4 AS Decimal(9,3)) AS MS1_TIC_Q4,  
			Cast(DQC.MS1_Count AS Integer) AS MS1_Count,  
			Cast(DQC.MS1_Freq_Max AS Decimal(9,3)) AS MS1_Freq_Max,  
			Cast(DQC.MS1_Density_Q1 AS integer) AS MS1_Density_Q1,  
			Cast(DQC.MS1_Density_Q2 AS integer) AS MS1_Density_Q2,  
			Cast(DQC.MS1_Density_Q3 AS integer) AS MS1_Density_Q3,  
			Cast(DQC.MS2_Count AS integer) AS MS2_Count,  
			Cast(DQC.MS2_Freq_Max AS Decimal(9,3)) AS MS2_Freq_Max,  
			Cast(DQC.MS2_Density_Q1 AS integer) AS MS2_Density_Q1,  
			Cast(DQC.MS2_Density_Q2 AS integer) AS MS2_Density_Q2,  
			Cast(DQC.MS2_Density_Q3 AS integer) AS MS2_Density_Q3,  
			Cast(DQC.MS2_PrecZ_1 AS Decimal(9,3)) AS MS2_PrecZ_1,  
			Cast(DQC.MS2_PrecZ_2 AS Decimal(9,3)) AS MS2_PrecZ_2,  
			Cast(DQC.MS2_PrecZ_3 AS Decimal(9,3)) AS MS2_PrecZ_3,  
			Cast(DQC.MS2_PrecZ_4 AS Decimal(9,3)) AS MS2_PrecZ_4,  
			Cast(DQC.MS2_PrecZ_5 AS Decimal(9,3)) AS MS2_PrecZ_5,  
			Cast(DQC.MS2_PrecZ_more AS Decimal(9,3)) AS MS2_PrecZ_more,  
			Cast(DQC.MS2_PrecZ_likely_1 AS Decimal(9,3)) AS MS2_PrecZ_likely_1,  
			Cast(DQC.MS2_PrecZ_likely_multi AS Decimal(9,3)) AS MS2_PrecZ_likely_multi,  
			DQC.Quameter_Last_Affected AS Quameter_Last_Affected,
			DQC.SMAQC_Job,
			Cast(DQC.C_1A AS Decimal(9,3)) AS C_1A,  
			Cast(DQC.C_1B AS Decimal(9,3)) AS C_1B,  
			Cast(DQC.C_2A AS Decimal(9,3)) AS C_2A,  
			Cast(DQC.C_2B AS Decimal(9,3)) AS C_2B,  
			Cast(DQC.C_3A AS Decimal(9,3)) AS C_3A,  
			Cast(DQC.C_3B AS Decimal(9,3)) AS C_3B,  
			Cast(DQC.C_4A AS Decimal(9,3)) AS C_4A,  
			Cast(DQC.C_4B AS Decimal(9,3)) AS C_4B,  
			Cast(DQC.C_4C AS Decimal(9,3)) AS C_4C,  
			Cast(DQC.DS_1A AS Decimal(9,3)) AS DS_1A,  
			Cast(DQC.DS_1B AS Decimal(9,3)) AS DS_1B,  
			Cast(DQC.DS_2A AS integer) AS DS_2A,  
			Cast(DQC.DS_2B AS integer) AS DS_2B,  
			Cast(DQC.DS_3A AS Decimal(9,3)) AS DS_3A,  
			Cast(DQC.DS_3B AS Decimal(9,3)) AS DS_3B,  
			Cast(DQC.IS_1A AS integer) AS IS_1A,  
			Cast(DQC.IS_1B AS integer) AS IS_1B,  
			Cast(DQC.IS_2 AS Decimal(9,3)) AS IS_2,  
			Cast(DQC.IS_3A AS Decimal(9,3)) AS IS_3A,  
			Cast(DQC.IS_3B AS Decimal(9,3)) AS IS_3B,  
			Cast(DQC.IS_3C AS Decimal(9,3)) AS IS_3C,  
			Cast(DQC.MS1_1 AS Decimal(9,3)) AS MS1_1,  
			Cast(DQC.MS1_2A AS Decimal(9,3)) AS MS1_2A,  
			DQC.MS1_2B,    -- Do not cast because can be large
			DQC.MS1_3A,    -- Do not cast because can be large
			DQC.MS1_3B,    -- Do not cast because can be large
			Cast(DQC.MS1_5A AS Decimal(9,3)) AS MS1_5A,
			Cast(DQC.MS1_5B AS Decimal(9,3)) AS MS1_5B,
			Cast(DQC.MS1_5C AS Decimal(9,3)) AS MS1_5C,
			Cast(DQC.MS1_5D AS Decimal(9,3)) AS MS1_5D,
			Cast(DQC.MS2_1 AS Decimal(9,3)) AS MS2_1,
			Cast(DQC.MS2_2 AS Decimal(9,3)) AS MS2_2,
			Cast(DQC.MS2_3 AS integer) AS MS2_3,
			Cast(DQC.MS2_4A AS Decimal(9,3)) AS MS2_4A,  
			Cast(DQC.MS2_4B AS Decimal(9,3)) AS MS2_4B,  
			Cast(DQC.MS2_4C AS Decimal(9,3)) AS MS2_4C,  
			Cast(DQC.MS2_4D AS Decimal(9,3)) AS MS2_4D,  
			Cast(DQC.P_1A AS Decimal(9,3)) AS P_1A,  
			Cast(DQC.P_1B AS Decimal(9,3)) AS P_1B,  
			Cast(DQC.P_2A AS integer) AS P_2A,  
			Cast(DQC.P_2B AS integer) AS P_2B,  
			Cast(DQC.P_2C AS integer) AS P_2C,
			Cast(DQC.P_3 AS Decimal(9,3)) AS P_3,
			Cast(DQC.Phos_2A AS integer) AS Phos_2A,
			Cast(DQC.Phos_2C AS integer) AS Phos_2C,
			Cast(DQC.Keratin_2A AS integer) AS Keratin_2A,
			Cast(DQC.Keratin_2C AS integer) AS Keratin_2C,
			Cast(DQC.P_4A AS Decimal(9,3)) AS P_4A,
			Cast(DQC.P_4B AS Decimal(9,3)) AS P_4B,
			Cast(DQC.Trypsin_2A AS integer) AS Trypsin_2A,
			Cast(DQC.Trypsin_2C AS integer) AS Trypsin_2C,
			Cast(DQC.MS2_RepIon_All AS integer) AS MS2_RepIon_All,
			Cast(DQC.MS2_RepIon_1Missing AS integer) AS MS2_RepIon_1Missing,
			Cast(DQC.MS2_RepIon_2Missing AS integer) AS MS2_RepIon_2Missing,
			Cast(DQC.MS2_RepIon_3Missing AS integer) AS MS2_RepIon_3Missing,
			DQC.Last_Affected AS SMAQC_Last_Affected,
			Cast(DQC.QCDM AS Decimal(9,3)) AS QCDM,  
			DQC.QCDM_Last_Affected,
			Cast(DQC.MassErrorPPM AS Decimal(9,2)) AS MassErrorPPM,  
			Cast(DQC.MassErrorPPM_Refined AS Decimal(9,2)) AS MassErrorPPM_Refined,  
			Cast(DQC.MassErrorPPM_VIPER AS Decimal(9,2)) AS MassErrorPPM_VIPER,  
			DQC.AMTs_10pct_FDR,
			Cast(DQC.QCART AS Decimal(9,3)) AS QCART
	FROM T_Dataset_QC DQC
		 INNER JOIN T_Dataset DS
		   ON DQC.Dataset_ID = DS.Dataset_ID
		 INNER JOIN T_Instrument_Name InstName
		   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
		 LEFT OUTER JOIN dbo.V_Dataset_Folder_Paths DFP
		   ON DQC.Dataset_ID = DFP.Dataset_ID
	) DataQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metrics_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
