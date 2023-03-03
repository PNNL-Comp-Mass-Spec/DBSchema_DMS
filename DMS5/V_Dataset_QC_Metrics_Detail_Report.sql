/****** Object:  View [dbo].[V_Dataset_QC_Metrics_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_QC_Metrics_Detail_Report]
AS
SELECT DISTINCT
    instrument_group,
    instrument,
    acq_time_start,
    dataset_id,
    dataset,
    dataset_rating,
    dataset_rating_id,
    dataset_folder_path,
    qc_metric_stats,
    quameter_job,
    XIC_WideFrac + '| Fraction of precursor ions accounting for the top half of all peak width' AS xic_wide_frac,
    XIC_FWHM_Q1 + ' seconds| 25%ile of peak widths for the wide XICs' AS xic_fwhm_q1,
    XIC_FWHM_Q2 + ' seconds| 50%ile of peak widths for the wide XICs' AS xic_fwhm_q2,
    XIC_FWHM_Q3 + ' seconds| 75%ile of peak widths for the wide XICs' AS xic_fwhm_q3,
    XIC_Height_Q2 + '| The log ratio for 50%ile of wide XIC heights over 25%ile of heights.' AS xic_height_q2,
    XIC_Height_Q3 + '| The log ratio for 75%ile of wide XIC heights over 50%ile of heights.' AS xic_height_q3,
    XIC_Height_Q4 + '| The log ratio for maximum of wide XIC heights over 75%ile of heights.' AS xic_height_q4,
    RT_Duration + ' seconds| Highest scan time observed minus the lowest scan time observed' AS rt_duration,
    RT_TIC_Q1 + '| The interval when the first 25% of TIC accumulates divided by RT-Duration' AS rt_tic_q1,
    RT_TIC_Q2 + '| The interval when the second 25% of TIC accumulates divided by RT-Duration' AS rt_tic_q2,
    RT_TIC_Q3 + '| The interval when the third 25% of TIC accumulates divided by RT-Duration' AS rt_tic_q3,
    RT_TIC_Q4 + '| The interval when the fourth 25% of TIC accumulates divided by RT-Duration' AS rt_tic_q4,
    RT_MS_Q1 + '| The interval for the first 25% of all MS events divided by RT-Duration' AS rt_ms_q1,
    RT_MS_Q2 + '| The interval for the second 25% of all MS events divided by RT-Duration' AS rt_ms_q2,
    RT_MS_Q3 + '| The interval for the third 25% of all MS events divided by RT-Duration' AS rt_ms_q3,
    RT_MS_Q4 + '| The interval for the fourth 25% of all MS events divided by RT-Duration' AS rt_ms_q4,
    RT_MSMS_Q1 + '| The interval for the first 25% of all MS/MS events divided by RT-Duration' AS rt_msms_q1,
    RT_MSMS_Q2 + '| The interval for the second 25% of all MS/MS events divided by RT-Duration' AS rt_msms_q2,
    RT_MSMS_Q3 + '| The interval for the third 25% of all MS/MS events divided by RT-Duration' AS rt_msms_q3,
    RT_MSMS_Q4 + '| The interval for the fourth 25% of all MS/MS events divided by RT-Duration' AS rt_msms_q4,
    MS1_TIC_Change_Q2 + '| The log ratio for 50%ile of TIC changes over 25%ile of TIC changes' AS ms1_tic_change_q2,
    MS1_TIC_Change_Q3 + '| The log ratio for 75%ile of TIC changes over 50%ile of TIC changes' AS ms1_tic_change_q3,
    MS1_TIC_Change_Q4 + '| The log ratio for largest TIC change over 75%ile of TIC changes' AS ms1_tic_change_q4,
    MS1_TIC_Q2 + '| The log ratio for 50%ile of TIC over 25%ile of TIC' AS ms1_tic_q2,
    MS1_TIC_Q3 + '| The log ratio for 75%ile of TIC over 50%ile of TIC' AS ms1_tic_q3,
    MS1_TIC_Q4 + '| The log ratio for largest TIC over 75%ile TIC' AS ms1_tic_q4,
    MS1_Count + '| Number of MS spectra collected' AS ms1_count,
    MS1_Freq_Max + ' Hz| Fastest frequency for MS collection in any minute' AS ms1_freq_max,
    MS1_Density_Q1 + '| 25%ile of MS scan peak counts' AS ms1_density_q1,
    MS1_Density_Q2 + '| 50%ile of MS scan peak counts' AS ms1_density_q2,
    MS1_Density_Q3 + '| 75%ile of MS scan peak counts' AS ms1_density_q3,
    MS2_Count + '| Number of MS/MS spectra collected' AS ms2_count,
    MS2_Freq_Max + ' Hz| Fastest frequency for MS/MS collection in any minute' AS ms2_freq_max,
    MS2_Density_Q1 + '| 25%ile of MS/MS scan peak counts' AS ms2_density_q1,
    MS2_Density_Q2 + '| 50%ile of MS/MS scan peak counts' AS ms2_density_q2,
    MS2_Density_Q3 + '| 75%ile of MS/MS scan peak counts' AS ms2_density_q3,
    MS2_PrecZ_1 + '| Fraction of MS/MS precursors that are singly charged' AS ms2_prec_z_1,
    MS2_PrecZ_2 + '| Fraction of MS/MS precursors that are doubly charged' AS ms2_prec_z_2,
    MS2_PrecZ_3 + '| Fraction of MS/MS precursors that are triply charged' AS ms2_prec_z_3,
    MS2_PrecZ_4 + '| Fraction of MS/MS precursors that are quadruply charged' AS ms2_prec_z_4,
    MS2_PrecZ_5 + '| Fraction of MS/MS precursors that are quintuply charged' AS ms2_prec_z_5,
    MS2_PrecZ_more + '| Fraction of MS/MS precursors that are charged higher than +5' AS ms2_prec_z_more,
    MS2_PrecZ_likely_1 + '| Fraction of MS/MS precursors lack known charge but look like 1+' AS ms2_prec_z_likely_1,
    MS2_PrecZ_likely_multi + '| Fraction of MS/MS precursors lack known charge but look like 2+ or higher' AS ms2_prec_z_likely_multi,
    quameter_last_affected,
    smaqc_job,
    C_1A + '| Fraction of peptides identified more than 4 minutes earlier than the chromatographic peak apex' AS c_1a,
    C_1B + '| Fraction of peptides identified more than 4 minutes later than the chromatographic peak apex' AS c_1b,
    C_2A + ' minutes| Time period over which 50% of peptides are identified' AS c_2a,
    C_2B + '| Rate of peptide identification during C-2A' AS c_2b,
    C_3A + ' seconds| Median peak width for all peptides' AS c_3a,
    C_3B + ' seconds| Median peak width during middle 50% of separation' AS c_3b,
    C_4A + ' seconds| Median peak width during first 10% of separation' AS c_4a,
    C_4B + ' seconds| Median peak width during last 10% of separation' AS c_4b,
    C_4C + ' seconds| Median peak width during middle 10% of separation' AS c_4c,
    DS_1A + '| Count of peptides with one spectrum / count of peptides with two spectra' AS ds_1a,
    DS_1B + '| Count of peptides with two spectra / count of peptides with three spectra' AS ds_1b,
    DS_2A + '| Number of MS1 scans taken over middle 50% of separation' AS ds_2a,
    DS_2B + '| Number of MS2 scans taken over middle 50% of separation' AS ds_2b,
    DS_3A + '| Median of MS1 max / MS1 sampled abundance' AS ds_3a,
    DS_3B + '| Median of MS1 max / MS1 sampled abundance; limit to bottom 50% of peptides by abundance' AS ds_3b,
    IS_1A + '| Occurrences of MS1 jumping >10x' AS is_1a,
    IS_1B + '| Occurrences of MS1 falling >10x' AS is_1b,
    IS_2 + '| Median precursor m/z for all peptides' AS is_2,
    IS_3A + '| Count of 1+ peptides / count of 2+ peptides' AS is_3a,
    IS_3B + '| Count of 3+ peptides / count of 2+ peptides' AS is_3b,
    IS_3C + '| Count of 4+ peptides / count of 2+ peptides' AS is_3c,
    MS1_1 + ' milliseconds| Median MS1 ion injection time' AS ms1_1,
    MS1_2A + '| Median S/N value for MS1 spectra from run start through middle 50% of separation' AS ms1_2a,
    MS1_2B + '| Median TIC value for identified peptides from run start through middle 50% of separation' AS ms1_2b,
    MS1_3A + '| Dynamic range estimate using 95th percentile peptide peak apex intensity / 5th percentile' AS ms1_3a,
    MS1_3B + '| Median peak apex intensity for all peptides' AS ms1_3b,
    MS1_5A + ' Th| Median of precursor mass error' AS ms1_5a,
    MS1_5B + ' Th| Median of absolute value of precursor mass error' AS ms1_5b,
    MS1_5C + ' ppm| Median of precursor mass error' AS ms1_5c,
    MS1_5D + ' ppm| Interquartile distance in ppm-based precursor mass error' AS ms1_5d,
    MS2_1 + ' milliseconds| Median MS2 ion injection time for identified peptides' AS ms2_1,
    MS2_2 + '| Median S/N value for identified MS2 spectra' AS ms2_2,
    MS2_3 + '| Median number of peaks in all MS2 spectra' AS ms2_3,
    MS2_4A + '| Fraction of all MS2 spectra identified; low abundance quartile (determined using MS1 intensity of identified peptides)' AS ms2_4a,
    MS2_4B + '| Fraction of all MS2 spectra identified; second quartile (determined using MS1 intensity of identified peptides)' AS ms2_4b,
    MS2_4C + '| Fraction of all MS2 spectra identified; third quartile (determined using MS1 intensity of identified peptides)' AS ms2_4c,
    MS2_4D + '| Fraction of all MS2 spectra identified; high abundance quartile (determined using MS1 intensity of identified peptides)' AS ms2_4d,
    P_1A + '| Median peptide ID score (-Log10(MSGF_SpecProb) or X!Tandem hyperscore)' AS p_1a,
    P_1B + '| Median peptide ID score ( Log10(MSGF_SpecProb) or X!Tandem Peptide_Expectation_Value_Log(e))' AS p_1b,
    P_2A + '| Number of tryptic peptides; total spectra count' AS p_2a,
    P_2B + '| Number of tryptic peptides; unique peptide & charge count' AS p_2b,
    P_2C + '| Number of tryptic peptides; unique peptide count' AS p_2c,
    P_3 + '| Ratio of unique semi-tryptic / unique fully tryptic peptides' AS p_3,
    Phos_2A + '| Number of tryptic phosphopeptides; total spectra count' AS phos_2a,
    Phos_2C + '| Number of tryptic phosphopeptides; unique peptide count' AS phos_2c,
    Keratin_2A + '| Number of keratin peptides (full or partial trypsin); total spectra count' AS keratin_2a,
    Keratin_2C + '| Number of keratin peptides (full or partial trypsin); unique peptide count' AS keratin_2c,
    P_4A + '| Ratio of unique fully tryptic peptides / total unique peptides' AS p_4a,
    P_4B + '| Ratio of total missed cleavages (among unique peptides) / total unique peptides' AS p_4b,
    Trypsin_2A + '| Number of peptides from trypsin; total spectra count' AS trypsin_2a,
    Trypsin_2C + '| Number of peptides from trypsin; unique peptide count' AS trypsin_2c,
    MS2_RepIon_All + '| Number of peptides (PSMs) where all reporter ions were seen' AS ms2_rep_ion_all,
    MS2_RepIon_1Missing + '| Number of peptides (PSMs) where all but 1 of the reporter ions were seen' AS ms2_rep_ion_1missing,
    MS2_RepIon_2Missing + '| Number of peptides (PSMs) where all but 2 of the reporter ions were seen' AS ms2_rep_ion_2missing,
    MS2_RepIon_3Missing + '| Number of peptides (PSMs) where all but 3 of the reporter ions were seen' AS ms2_rep_ion_3missing,
    smaqc_last_affected,
    psm_source_job,
    QCDM + '| Overall confidence using model developed by Brett Amidan' AS qcdm,
    qcdm_last_affected,
    mass_error_ppm,
    mass_error_ppm_refined,
    mass_error_ppm_viper,
    amts_10pct_fdr,
    amts_25pct_fdr,
    QCART + '| Overall confidence using model developed by Allison Thompson and Ryan Butner' AS qcart
    FROM (SELECT InstName.IN_Group AS Instrument_Group,
            InstName.IN_name AS Instrument,
            DS.Acq_Time_Start,
            DQC.Dataset_ID,
            DS.Dataset_Num AS Dataset,
            DRN.DRN_name AS dataset_rating,
            DS.DS_rating AS dataset_rating_id,
            DFP.Dataset_Folder_Path AS Dataset_Folder_Path,
            'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + IN_Name AS QC_Metric_Stats,
            DQC.Quameter_Job,
            dbo.number_to_string(DQC.XIC_WideFrac, 3) AS XIC_WideFrac,
            dbo.number_to_string(DQC.XIC_FWHM_Q1, 3) AS XIC_FWHM_Q1,
            dbo.number_to_string(DQC.XIC_FWHM_Q2, 3) AS XIC_FWHM_Q2,
            dbo.number_to_string(DQC.XIC_FWHM_Q3, 3) AS XIC_FWHM_Q3,
            dbo.number_to_string(DQC.XIC_Height_Q2, 3) AS XIC_Height_Q2,
            dbo.number_to_string(DQC.XIC_Height_Q3, 3) AS XIC_Height_Q3,
            dbo.number_to_string(DQC.XIC_Height_Q4, 3) AS XIC_Height_Q4,
            dbo.number_to_string(DQC.RT_Duration, 3) AS RT_Duration,
            dbo.number_to_string(DQC.RT_TIC_Q1, 3) AS RT_TIC_Q1,
            dbo.number_to_string(DQC.RT_TIC_Q2, 3) AS RT_TIC_Q2,
            dbo.number_to_string(DQC.RT_TIC_Q3, 3) AS RT_TIC_Q3,
            dbo.number_to_string(DQC.RT_TIC_Q4, 3) AS RT_TIC_Q4,
            dbo.number_to_string(DQC.RT_MS_Q1, 3) AS RT_MS_Q1,
            dbo.number_to_string(DQC.RT_MS_Q2, 3) AS RT_MS_Q2,
            dbo.number_to_string(DQC.RT_MS_Q3, 3) AS RT_MS_Q3,
            dbo.number_to_string(DQC.RT_MS_Q4, 3) AS RT_MS_Q4,
            dbo.number_to_string(DQC.RT_MSMS_Q1, 3) AS RT_MSMS_Q1,
            dbo.number_to_string(DQC.RT_MSMS_Q2, 3) AS RT_MSMS_Q2,
            dbo.number_to_string(DQC.RT_MSMS_Q3, 3) AS RT_MSMS_Q3,
            dbo.number_to_string(DQC.RT_MSMS_Q4, 3) AS RT_MSMS_Q4,
            dbo.number_to_string(DQC.MS1_TIC_Change_Q2, 3) AS MS1_TIC_Change_Q2,
            dbo.number_to_string(DQC.MS1_TIC_Change_Q3, 3) AS MS1_TIC_Change_Q3,
            dbo.number_to_string(DQC.MS1_TIC_Change_Q4, 3) AS MS1_TIC_Change_Q4,
            dbo.number_to_string(DQC.MS1_TIC_Q2, 3) AS MS1_TIC_Q2,
            dbo.number_to_string(DQC.MS1_TIC_Q3, 3) AS MS1_TIC_Q3,
            dbo.number_to_string(DQC.MS1_TIC_Q4, 3) AS MS1_TIC_Q4,
            dbo.number_to_string(DQC.MS1_Count, 0) AS MS1_Count,
            dbo.number_to_string(DQC.MS1_Freq_Max, 3) AS MS1_Freq_Max,
            dbo.number_to_string(DQC.MS1_Density_Q1, 0) AS MS1_Density_Q1,
            dbo.number_to_string(DQC.MS1_Density_Q2, 0) AS MS1_Density_Q2,
            dbo.number_to_string(DQC.MS1_Density_Q3, 0) AS MS1_Density_Q3,
            dbo.number_to_string(DQC.MS2_Count, 0) AS MS2_Count,
            dbo.number_to_string(DQC.MS2_Freq_Max, 3) AS MS2_Freq_Max,
            dbo.number_to_string(DQC.MS2_Density_Q1, 0) AS MS2_Density_Q1,
            dbo.number_to_string(DQC.MS2_Density_Q2, 0) AS MS2_Density_Q2,
            dbo.number_to_string(DQC.MS2_Density_Q3, 0) AS MS2_Density_Q3,
            dbo.number_to_string(DQC.MS2_PrecZ_1, 3) AS MS2_PrecZ_1,
            dbo.number_to_string(DQC.MS2_PrecZ_2, 3) AS MS2_PrecZ_2,
            dbo.number_to_string(DQC.MS2_PrecZ_3, 3) AS MS2_PrecZ_3,
            dbo.number_to_string(DQC.MS2_PrecZ_4, 3) AS MS2_PrecZ_4,
            dbo.number_to_string(DQC.MS2_PrecZ_5, 3) AS MS2_PrecZ_5,
            dbo.number_to_string(DQC.MS2_PrecZ_more, 3) AS MS2_PrecZ_more,
            dbo.number_to_string(DQC.MS2_PrecZ_likely_1, 3) AS MS2_PrecZ_likely_1,
            dbo.number_to_string(DQC.MS2_PrecZ_likely_multi, 3) AS MS2_PrecZ_likely_multi,
            DQC.Quameter_Last_Affected AS Quameter_Last_Affected,
            DQC.SMAQC_Job,
            dbo.number_to_string(DQC.C_1A, 3) AS C_1A,
            dbo.number_to_string(DQC.C_1B, 3) AS C_1B,
            dbo.number_to_string(DQC.C_2A, 3) AS C_2A,
            dbo.number_to_string(DQC.C_2B, 3) AS C_2B,
            dbo.number_to_string(DQC.C_3A, 3) AS C_3A,
            dbo.number_to_string(DQC.C_3B, 3) AS C_3B,
            dbo.number_to_string(DQC.C_4A, 3) AS C_4A,
            dbo.number_to_string(DQC.C_4B, 3) AS C_4B,
            dbo.number_to_string(DQC.C_4C, 3) AS C_4C,
            dbo.number_to_string(DQC.DS_1A, 3) AS DS_1A,
            dbo.number_to_string(DQC.DS_1B, 3) AS DS_1B,
            dbo.number_to_string(DQC.DS_2A, 0) AS DS_2A,
            dbo.number_to_string(DQC.DS_2B, 0) AS DS_2B,
            dbo.number_to_string(DQC.DS_3A, 3) AS DS_3A,
            dbo.number_to_string(DQC.DS_3B, 3) AS DS_3B,
            dbo.number_to_string(DQC.IS_1A, 0) AS IS_1A,
            dbo.number_to_string(DQC.IS_1B, 0) AS IS_1B,
            dbo.number_to_string(DQC.IS_2, 3) AS IS_2,
            dbo.number_to_string(DQC.IS_3A, 3) AS IS_3A,
            dbo.number_to_string(DQC.IS_3B, 3) AS IS_3B,
            dbo.number_to_string(DQC.IS_3C, 3) AS IS_3C,
            dbo.number_to_string(DQC.MS1_1, 3) AS MS1_1,
            dbo.number_to_string(DQC.MS1_2A, 3) AS MS1_2A,
            dbo.number_to_string(DQC.MS1_2B, 3) AS MS1_2B,
            dbo.number_to_string(DQC.MS1_3A, 3) AS MS1_3A,
            dbo.number_to_string(DQC.MS1_3B, 3) AS MS1_3B,
            dbo.number_to_string(DQC.MS1_5A, 3) AS MS1_5A,
            dbo.number_to_string(DQC.MS1_5B, 3) AS MS1_5B,
            dbo.number_to_string(DQC.MS1_5C, 3) AS MS1_5C,
            dbo.number_to_string(DQC.MS1_5D, 3) AS MS1_5D,
            dbo.number_to_string(DQC.MS2_1, 3) AS MS2_1,
            dbo.number_to_string(DQC.MS2_2, 3) AS MS2_2,
            dbo.number_to_string(DQC.MS2_3, 0) AS MS2_3,
            dbo.number_to_string(DQC.MS2_4A, 3) AS MS2_4A,
            dbo.number_to_string(DQC.MS2_4B, 3) AS MS2_4B,
            dbo.number_to_string(DQC.MS2_4C, 3) AS MS2_4C,
            dbo.number_to_string(DQC.MS2_4D, 3) AS MS2_4D,
            dbo.number_to_string(DQC.P_1A, 3) AS P_1A,
            dbo.number_to_string(DQC.P_1B, 3) AS P_1B,
            dbo.number_to_string(DQC.P_2A, 0) AS P_2A,
            dbo.number_to_string(DQC.P_2B, 0) AS P_2B,
            dbo.number_to_string(DQC.P_2C, 0) AS P_2C,
            dbo.number_to_string(DQC.P_3, 3) AS P_3,
            dbo.number_to_string(DQC.Phos_2A, 0) AS Phos_2A,
            dbo.number_to_string(DQC.Phos_2C, 0) AS Phos_2C,
            dbo.number_to_string(DQC.Keratin_2A, 0) AS Keratin_2A,
            dbo.number_to_string(DQC.Keratin_2C, 0) AS Keratin_2C,
            dbo.number_to_string(DQC.P_4A, 3) AS P_4A,
            dbo.number_to_string(DQC.P_4B, 3) AS P_4B,
            dbo.number_to_string(DQC.Trypsin_2A, 0) AS Trypsin_2A,
            dbo.number_to_string(DQC.Trypsin_2C, 0) AS Trypsin_2C,
            dbo.number_to_string(DQC.MS2_RepIon_All, 0) AS MS2_RepIon_All,
            dbo.number_to_string(DQC.MS2_RepIon_1Missing, 0) AS MS2_RepIon_1Missing,
            dbo.number_to_string(DQC.MS2_RepIon_2Missing, 0) AS MS2_RepIon_2Missing,
            dbo.number_to_string(DQC.MS2_RepIon_3Missing, 0) AS MS2_RepIon_3Missing,
            DQC.Last_Affected AS SMAQC_Last_Affected,
            dbo.number_to_string(DQC.QCDM, 3) AS QCDM,
            DQC.QCDM_Last_Affected,
            DQC.psm_source_job,
            dbo.number_to_string(DQC.MassErrorPPM, 3) AS Mass_Error_PPM,
            dbo.number_to_string(DQC.MassErrorPPM_Refined, 3) AS Mass_Error_PPM_Refined,
            dbo.number_to_string(DQC.MassErrorPPM_VIPER, 3) AS Mass_Error_PPM_VIPER,
            DQC.AMTs_10pct_FDR,
            DQC.AMTs_25pct_FDR,
            dbo.number_to_string(DQC.QCART, 3) AS QCART
    FROM T_Dataset_QC DQC
         INNER JOIN T_Dataset DS
           ON DQC.Dataset_ID = DS.Dataset_ID
         INNER JOIN T_Instrument_Name InstName
           ON DS.DS_instrument_name_ID = InstName.Instrument_ID
         INNER JOIN T_Dataset_Rating_Name DRN
           ON DS.DS_rating = DRN.DRN_state_ID
         LEFT OUTER JOIN dbo.V_Dataset_Folder_Paths DFP
           ON DQC.Dataset_ID = DFP.Dataset_ID
    ) DataQ

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metrics_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
