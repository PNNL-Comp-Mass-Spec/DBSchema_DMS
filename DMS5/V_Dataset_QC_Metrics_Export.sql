/****** Object:  View [dbo].[V_Dataset_QC_Metrics_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Dataset_QC_Metrics_Export
AS
SELECT InstName.IN_Group AS instrument_group,
       InstName.IN_name AS instrument,
       DS.acq_time_start,
       DQC.dataset_id,
       DS.Dataset_Num AS dataset,
       DRN.DRN_name AS dataset_rating,
       DS.DS_rating AS dataset_rating_id,
       DQC.p_2c,
       DQC.MassErrorPPM AS mass_error_ppm,
       DQC.MassErrorPPM_VIPER AS mass_error_ppm_viper,
       DQC.amts_10pct_fdr,
       DQC.amts_25pct_fdr,
       DQC.xic_fwhm_q2,
       DQC.XIC_WideFrac AS xic_wide_frac,
       DQC.phos_2c,
       DQC.quameter_job,
       DQC.xic_fwhm_q1,
       DQC.xic_fwhm_q3,
       DQC.xic_height_q2,
       DQC.xic_height_q3,
       DQC.xic_height_q4,
       DQC.rt_duration,
       DQC.rt_tic_q1,
       DQC.rt_tic_q2,
       DQC.rt_tic_q3,
       DQC.rt_tic_q4,
       DQC.rt_ms_q1,
       DQC.rt_ms_q2,
       DQC.rt_ms_q3,
       DQC.rt_ms_q4,
       DQC.rt_msms_q1,
       DQC.rt_msms_q2,
       DQC.rt_msms_q3,
       DQC.rt_msms_q4,
       DQC.ms1_tic_change_q2,
       DQC.ms1_tic_change_q3,
       DQC.ms1_tic_change_q4,
       DQC.ms1_tic_q2,
       DQC.ms1_tic_q3,
       DQC.ms1_tic_q4,
       DQC.ms1_count,
       DQC.ms1_freq_max,
       DQC.ms1_density_q1,
       DQC.ms1_density_q2,
       DQC.ms1_density_q3,
       DQC.ms2_count,
       DQC.ms2_freq_max,
       DQC.ms2_density_q1,
       DQC.ms2_density_q2,
       DQC.ms2_density_q3,
       DQC.MS2_PrecZ_1            AS ms2_prec_z_1,
       DQC.MS2_PrecZ_2            AS ms2_prec_z_2,
       DQC.MS2_PrecZ_3            AS ms2_prec_z_3,
       DQC.MS2_PrecZ_4            AS ms2_prec_z_4,
       DQC.MS2_PrecZ_5            AS ms2_prec_z_5,
       DQC.MS2_PrecZ_more         AS ms2_prec_z_more,
       DQC.MS2_PrecZ_likely_1     AS ms2_prec_z_likely_1,
       DQC.MS2_PrecZ_likely_multi AS ms2_prec_z_likely_multi,
       DQC.Quameter_Last_Affected AS quameter_last_affected,
       DQC.smaqc_job,
       DQC.c_1a,
       DQC.c_1b,
       DQC.c_2a,
       DQC.c_2b,
       DQC.c_3a,
       DQC.c_3b,
       DQC.c_4a,
       DQC.c_4b,
       DQC.c_4c,
       DQC.ds_1a,
       DQC.ds_1b,
       DQC.ds_2a,
       DQC.ds_2b,
       DQC.ds_3a,
       DQC.ds_3b,
       DQC.is_1a,
       DQC.is_1b,
       DQC.is_2,
       DQC.is_3a,
       DQC.is_3b,
       DQC.is_3c,
       DQC.ms1_1,
       DQC.ms1_2a,
       DQC.ms1_2b,
       DQC.ms1_3a,
       DQC.ms1_3b,
       DQC.ms1_5a,
       DQC.ms1_5b,
       DQC.ms1_5c,
       DQC.ms1_5d,
       DQC.ms2_1,
       DQC.ms2_2,
       DQC.ms2_3,
       DQC.ms2_4a,
       DQC.ms2_4b,
       DQC.ms2_4c,
       DQC.ms2_4d,
       DQC.p_1a,
       DQC.p_1b,
       DQC.p_2a,
       DQC.p_2b,
       DQC.p_3,
       DQC.phos_2a,
       DQC.keratin_2a,
       DQC.keratin_2c,
       DQC.p_4a,
       DQC.p_4b,
       DQC.trypsin_2a,
       DQC.trypsin_2c,
       DQC.MS2_RepIon_All       AS ms2_rep_ion_all,
       DQC.MS2_RepIon_1Missing  AS ms2_rep_ion_1missing,
       DQC.MS2_RepIon_2Missing  AS ms2_rep_ion_2missing,
       DQC.MS2_RepIon_3Missing  AS ms2_rep_ion_3missing,
       DQC.MassErrorPPM_Refined AS mass_error_ppm_refined,
       DQC.Last_Affected AS smaqc_last_affected,
       DQC.psm_source_job,
       DQC.qcdm,
       DQC.qcdm_last_affected,
       DQC.qcart
FROM T_Dataset_QC DQC
     INNER JOIN T_Dataset DS
       ON DQC.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName DRN
       ON DS.DS_rating = DRN.DRN_state_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metrics_Export] TO [DDL_Viewer] AS [dbo]
GO
