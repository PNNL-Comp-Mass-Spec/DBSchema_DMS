/****** Object:  StoredProcedure [dbo].[store_job_psm_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[store_job_psm_stats]
/****************************************************
**
**  Desc:
**      Updates the PSM stats in T_Analysis_Job_PSM_Stats for the specified analysis job
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   02/21/2012 mem - Initial version
**          05/08/2012 mem - Add parameters @fdrThreshold, @totalPSMsFDRFilter, @uniquePeptidesFDRFilter, and @uniqueProteinsFDRFilter
**          01/17/2014 mem - Add parameter @msgfThresholdIsEValue
**          01/21/2016 mem - Add parameters @percentMSnScansNoPSM and @maximumScanGapAdjacentMSn
**          09/28/2016 mem - Add three @uniquePhosphopeptide parameters, two @missedCleavageRatio parameters, @trypticPeptides, @keratinPeptides, and @trypsinPeptides
**          07/15/2020 mem - Add parameters @dynamicReporterIon, @percentPSMsMissingNTermReporterIon, and @percentPSMsMissingReporterIon
**          07/15/2020 mem - Add parameter @uniqueAcetylPeptidesFDR
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          04/08/2024 mem - Add parameter @uniqueUbiquitinPeptidesFDR
**          05/16/2024 mem - Update T_Cached_Dataset_Stats for the dataset associated with this job
**
*****************************************************/
(
    @job int = 0,
    @msgfThreshold float,
    @fdrThreshold float = 1,
    @spectraSearched int,                         -- Number of spectra that were searched
    @totalPSMs int,                               -- Stats based on @msgfThreshold (Number of identified spectra)
    @uniquePeptides int,                          -- Stats based on @msgfThreshold
    @uniqueProteins int,                          -- Stats based on @msgfThreshold
    @totalPSMsFDRFilter int = 0,                  -- Stats based on @fdrThreshold  (Number of identified spectra)
    @uniquePeptidesFDRFilter int = 0,             -- Stats based on @fdrThreshold
    @uniqueProteinsFDRFilter int = 0,             -- Stats based on @fdrThreshold
    @msgfThresholdIsEValue tinyint = 0,           -- Set to 1 if @msgfThreshold is actually an EValue
    @percentMSnScansNoPSM real = 0,               -- Percent (between 0 and 100) measuring the percent of MSn scans that did not have a filter passing PSM
    @maximumScanGapAdjacentMSn int = 0,           -- Maximum number of scans separating two MS2 spectra with search results; large gaps indicates that a processing thread in MSGF+ crashed and the results may be incomplete
    @uniquePhosphopeptideCountFDR int = 0,        -- Number of Phosphopeptides (any S, T, or Y that is phosphorylated); filtered using @fdrThreshold
    @uniquePhosphopeptidesCTermK int = 0,         -- Number of Phosphopeptides with K on the C-terminus
    @uniquePhosphopeptidesCTermR int = 0,         -- Number of Phosphopeptides with R on the C-terminus
    @missedCleavageRatio real = 0,                -- Value between 0 and 1; computed as the number of unique peptides with a missed cleavage / number of unique peptides
    @missedCleavageRatioPhospho real = 0,         -- Value between 0 and 1; like @missedCleavageRatio but for phosphopeptides
    @trypticPeptides int = 0,                     -- Number of tryptic peptides (partially or fully tryptic)
    @keratinPeptides int = 0,                     -- Number of peptides from Keratin
    @trypsinPeptides int = 0,                     -- Number of peptides from Trypsin
    @dynamicReporterIon tinyint = 0,              -- Set to 1 if TMT (or iTRAQ) was a dynamic modification, e.g. MSGFPlus_PartTryp_DynMetOx_TMT_6Plex_Stat_CysAlk_20ppmParTol.txt
    @percentPSMsMissingNTermReporterIon real = 0, -- When @dynamicReporterIon is 1, the percent of PSMs that have an N-terminus without TMT; value between 0 and 100
    @percentPSMsMissingReporterIon real = 0,      -- When @dynamicReporterIon is 1, the percent of PSMs that have an N-terminus or a K without TMT; value between 0 and 100
    @uniqueAcetylPeptidesFDR int = 0,             -- Number of peptides with an acetylated K; filtered using @fdrThreshold
    @uniqueUbiquitinPeptidesFDR int = 0,          -- Number of peptides with a ubiquitinated K; filtered using @fdrThreshold
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @job = IsNull(@job, 0)
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @fdrThreshold = IsNull(@fdrThreshold, 1)
    Set @msgfThresholdIsEValue = IsNull(@msgfThresholdIsEValue, 0)

    Set @percentMSnScansNoPSM = IsNull(@percentMSnScansNoPSM, 0)
    Set @maximumScanGapAdjacentMSn = IsNull(@maximumScanGapAdjacentMSn,0)

    Set @uniquePhosphopeptideCountFDR       = IsNull(@uniquePhosphopeptideCountFDR, 0)
    Set @uniquePhosphopeptidesCTermK        = IsNull(@uniquePhosphopeptidesCTermK, 0)
    Set @uniquePhosphopeptidesCTermR        = IsNull(@uniquePhosphopeptidesCTermR, 0)
    Set @missedCleavageRatio                = IsNull(@missedCleavageRatio, 0)
    Set @missedCleavageRatioPhospho         = IsNull(@missedCleavageRatioPhospho, 0)

    Set @trypticPeptides                    = IsNull(@trypticPeptides, 0)
    Set @keratinPeptides                    = IsNull(@keratinPeptides, 0)
    Set @trypsinPeptides                    = IsNull(@trypsinPeptides, 0)

    Set @dynamicReporterIon                 = IsNull(@dynamicReporterIon, 0)
    Set @percentPSMsMissingNTermReporterIon = IsNull(@percentPSMsMissingNTermReporterIon, 0)
    Set @percentPSMsMissingReporterIon      = IsNull(@percentPSMsMissingReporterIon, 0)

    Set @uniqueAcetylPeptidesFDR            = IsNull(@uniqueAcetylPeptidesFDR, 0)
    Set @uniqueUbiquitinPeptidesFDR         = IsNull(@uniqueUbiquitinPeptidesFDR, 0)

    ---------------------------------------------------
    -- Make sure @job is defined in T_Analysis_Job
    ---------------------------------------------------

    DECLARE @datasetID int = 0

    SELECT @datasetID = AJ_datasetID
    FROM T_Analysis_Job 
    WHERE AJ_jobID = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Job not found in T_Analysis_Job: ' + CONVERT(varchar(12), @job)
        return 50000
    End

    If @infoOnly <> 0
    Begin
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT @job                                AS Job,
               @msgfThreshold                      AS MSGF_Threshold,
               @fdrThreshold                       AS FDR_Threshold,
               @msgfThresholdIsEValue              AS MSGF_Threshold_Is_EValue,
               @spectraSearched                    AS Spectra_Searched,
               @totalPSMs                          AS Total_PSMs_MSGF,
               @uniquePeptides                     AS Unique_Peptides_MSGF,
               @uniqueProteins                     AS Unique_Proteins_MSGF,
               @totalPSMsFDRFilter                 AS Total_PSMs_FDR,
               @uniquePeptidesFDRFilter            AS Unique_Peptides_FDR,
               @uniqueProteinsFDRFilter            AS Unique_Proteins_FDR,
               @percentMSnScansNoPSM               AS Percent_MSn_Scans_NoPSM,
               @maximumScanGapAdjacentMSn          AS Maximum_ScanGap_Adjacent_MSn,
               @uniquePhosphopeptideCountFDR       AS Phosphopeptides,
               @uniquePhosphopeptidesCTermK        AS CTermK_Phosphopeptides,
               @uniquePhosphopeptidesCTermR        AS CTermR_Phosphopeptides,
               @missedCleavageRatio                AS Missed_Cleavage_Ratio_FDR,
               @missedCleavageRatioPhospho         AS MissedCleavageRatioPhospho,
               @trypticPeptides                    AS Tryptic_Peptides,
               @keratinPeptides                    AS Keratin_Peptides,
               @trypsinPeptides                    AS Trypsin_Peptides,
               @uniqueAcetylPeptidesFDR            AS Acetyl_Peptides,
               @uniqueUbiquitinPeptidesFDR         AS Ubiquitin_Peptides,
               @dynamicReporterIon                 AS Dynamic_Reporter_Ion,
               @percentPSMsMissingNTermReporterIon AS Percent_PSMs_Missing_NTermReporterIon,
               @percentPSMsMissingReporterIon      AS Percent_PSMs_Missing_ReporterIon

        Goto Done
    End


    -----------------------------------------------
    -- Add/Update T_Analysis_Job_PSM_Stats using a MERGE statement
    -----------------------------------------------

    ;
    MERGE T_Analysis_Job_PSM_Stats AS target
    USING
        (SELECT @job AS Job,
                @msgfThreshold AS MSGF_Threshold,
                @fdrThreshold AS FDR_Threshold,
                @msgfThresholdIsEValue AS MSGF_Threshold_Is_EValue,
                @spectraSearched AS Spectra_Searched,
                @totalPSMs AS Total_PSMs_MSGF,
                @uniquePeptides AS Unique_Peptides_MSGF,
                @uniqueProteins AS Unique_Proteins_MSGF,
                @totalPSMsFDRFilter AS Total_PSMs_FDR,
                @uniquePeptidesFDRFilter AS Unique_Peptides_FDR,
                @uniqueProteinsFDRFilter AS Unique_Proteins_FDR,
                @percentMSnScansNoPSM AS Percent_MSn_Scans_NoPSM,
                @maximumScanGapAdjacentMSn AS Maximum_ScanGap_Adjacent_MSn,
                @missedCleavageRatio AS Missed_Cleavage_Ratio_FDR,
                @trypticPeptides AS Tryptic_Peptides_FDR,
                @keratinPeptides AS Keratin_Peptides_FDR,
                @trypsinPeptides AS Trypsin_Peptides_FDR,
                @uniqueAcetylPeptidesFDR AS Acetyl_Peptides_FDR,
                @uniqueUbiquitinPeptidesFDR AS Ubiquitin_Peptides_FDR,
                @dynamicReporterIon AS Dynamic_Reporter_Ion,
                @percentPSMsMissingNTermReporterIon AS Percent_PSMs_Missing_NTermReporterIon,
                @percentPSMsMissingReporterIon AS Percent_PSMs_Missing_ReporterIon
        ) AS Source (Job, MSGF_Threshold, FDR_Threshold, MSGF_Threshold_Is_EValue, Spectra_Searched,
                     Total_PSMs_MSGF, Unique_Peptides_MSGF, Unique_Proteins_MSGF,
                     Total_PSMs_FDR, Unique_Peptides_FDR, Unique_Proteins_FDR,
                     Percent_MSn_Scans_NoPSM, Maximum_ScanGap_Adjacent_MSn, Missed_Cleavage_Ratio_FDR,
                     Tryptic_Peptides_FDR, Keratin_Peptides_FDR, Trypsin_Peptides_FDR,
                     Acetyl_Peptides_FDR, Ubiquitin_Peptides_FDR, Dynamic_Reporter_Ion,
                     Percent_PSMs_Missing_NTermReporterIon, Percent_PSMs_Missing_ReporterIon
                    )
        ON (target.Job = Source.Job)

    WHEN Matched
        THEN UPDATE
            Set MSGF_Threshold = Source.MSGF_Threshold,
                FDR_Threshold = Source.FDR_Threshold,
                MSGF_Threshold_Is_EValue = Source.MSGF_Threshold_Is_EValue,
                Spectra_Searched = Source.Spectra_Searched,
                Total_PSMs = Source.Total_PSMs_MSGF,
                Unique_Peptides = Source.Unique_Peptides_MSGF,
                Unique_Proteins = Source.Unique_Proteins_MSGF,
                Total_PSMs_FDR_Filter = Source.Total_PSMs_FDR,
                Unique_Peptides_FDR_Filter = Source.Unique_Peptides_FDR,
                Unique_Proteins_FDR_Filter = Source.Unique_Proteins_FDR,
                Percent_MSn_Scans_NoPSM = Source.Percent_MSn_Scans_NoPSM,
                Maximum_ScanGap_Adjacent_MSn = Source.Maximum_ScanGap_Adjacent_MSn,
                Missed_Cleavage_Ratio_FDR = Source.Missed_Cleavage_Ratio_FDR,
                Tryptic_Peptides_FDR = Source.Tryptic_Peptides_FDR,
                Keratin_Peptides_FDR = Source.Keratin_Peptides_FDR,
                Trypsin_Peptides_FDR = Source.Trypsin_Peptides_FDR,
                Acetyl_Peptides_FDR = Source.Acetyl_Peptides_FDR,
                Ubiquitin_Peptides_FDR = Source.Ubiquitin_Peptides_FDR,
                Dynamic_Reporter_Ion = Source.Dynamic_Reporter_Ion,
                Percent_PSMs_Missing_NTermReporterIon = Source.Percent_PSMs_Missing_NTermReporterIon,
                Percent_PSMs_Missing_ReporterIon = Source.Percent_PSMs_Missing_ReporterIon,
                Last_Affected = GetDate()

    WHEN Not Matched THEN
        INSERT (Job,
                MSGF_Threshold,
                FDR_Threshold,
                MSGF_Threshold_Is_EValue,
                Spectra_Searched,
                Total_PSMs,
                Unique_Peptides,
                Unique_Proteins,
                Total_PSMs_FDR_Filter,
                Unique_Peptides_FDR_Filter,
                Unique_Proteins_FDR_Filter,
                Percent_MSn_Scans_NoPSM,
                Maximum_ScanGap_Adjacent_MSn,
                Missed_Cleavage_Ratio_FDR,
                Tryptic_Peptides_FDR,
                Keratin_Peptides_FDR,
                Trypsin_Peptides_FDR,
                Acetyl_Peptides_FDR,
                Ubiquitin_Peptides_FDR,
                Dynamic_Reporter_Ion,
                Percent_PSMs_Missing_NTermReporterIon,
                Percent_PSMs_Missing_ReporterIon,
                Last_Affected
               )
        VALUES ( Source.Job,
                 Source.MSGF_Threshold,
                 Source.FDR_Threshold,
                 Source.MSGF_Threshold_Is_EValue,
                 Source.Spectra_Searched,
                 Source.Total_PSMs_MSGF,
                 Source.Unique_Peptides_MSGF,
                 Source.Unique_Proteins_MSGF,
                 Source.Total_PSMs_FDR,
                 Source.Unique_Peptides_FDR,
                 Source.Unique_Proteins_FDR,
                 Source.Percent_MSn_Scans_NoPSM,
                 Source.Maximum_ScanGap_Adjacent_MSn,
                 Source.Missed_Cleavage_Ratio_FDR,
                 Source.Tryptic_Peptides_FDR,
                 Source.Keratin_Peptides_FDR,
                 Source.Trypsin_Peptides_FDR,
                 Source.Acetyl_Peptides_FDR,
                 Source.Ubiquitin_Peptides_FDR,
                 Source.Dynamic_Reporter_Ion,
                 Source.Percent_PSMs_Missing_NTermReporterIon,
                 Source.Percent_PSMs_Missing_ReporterIon,
                 GetDate()
               )
    ;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating T_Analysis_Job_PSM_Stats'
        goto Done
    end

    If @uniquePhosphopeptideCountFDR = 0
    Begin
        -----------------------------------------------
        -- No phosphopeptide results for this job
        -- Make sure T_Analysis_Job_PSM_Stats_Phospho does not have this job
        -----------------------------------------------
        --
        DELETE FROM T_Analysis_Job_PSM_Stats_Phospho
        WHERE Job = @job
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        -----------------------------------------------
        -- Add/Update T_Analysis_Job_PSM_Stats_Phospho using a MERGE statement
        -----------------------------------------------
        --
        ;
        MERGE T_Analysis_Job_PSM_Stats_Phospho AS target
        USING
            (SELECT @job AS Job,
                    @uniquePhosphopeptideCountFDR AS Phosphopeptides,
                    @uniquePhosphopeptidesCTermK AS CTermK_Phosphopeptides,
                    @uniquePhosphopeptidesCTermR AS CTermR_Phosphopeptides,
                    @missedCleavageRatioPhospho AS MissedCleavageRatio
            ) AS Source (Job, Phosphopeptides, CTermK_Phosphopeptides, CTermR_Phosphopeptides, MissedCleavageRatio)
            ON (target.Job = Source.Job)

        WHEN Matched
            THEN UPDATE
                Set Phosphopeptides = Source.Phosphopeptides,
                    CTermK_Phosphopeptides = Source.CTermK_Phosphopeptides,
                    CTermR_Phosphopeptides = Source.CTermR_Phosphopeptides,
                    MissedCleavageRatio = Source.MissedCleavageRatio,
                    Last_Affected = GetDate()

        WHEN Not Matched THEN
            INSERT (Job,
                    Phosphopeptides,
                    CTermK_Phosphopeptides,
                    CTermR_Phosphopeptides,
                    MissedCleavageRatio,
                    Last_Affected
                )
            VALUES ( Source.Job,
                    Source.Phosphopeptides,
                    Source.CTermK_Phosphopeptides,
                    Source.CTermR_Phosphopeptides,
                    Source.MissedCleavageRatio,
                    GetDate()
                )
        ;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error updating T_Analysis_Job_PSM_Stats'
            goto Done
        end
    End

    Set @message = 'PSM stats storage successful'

    -----------------------------------------------
    -- Schedule the cached data in T_Cached_Dataset_Stats to get updated
    -----------------------------------------------
    --
    UPDATE T_Cached_Dataset_Stats
    SET Update_Required = 1
    WHERE Dataset_ID = @datasetID

Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in store_job_psm_stats'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        If @infoOnly = 0
            Exec post_log_entry 'Error', @message, 'store_job_psm_stats'
    End

    If Len(@message) > 0 AND @infoOnly <> 0
        Print @message

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[store_job_psm_stats] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_job_psm_stats] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_job_psm_stats] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_job_psm_stats] TO [svc-dms] AS [dbo]
GO
