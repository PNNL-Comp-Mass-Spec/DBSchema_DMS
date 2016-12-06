/****** Object:  StoredProcedure [dbo].[StoreJobPSMStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure StoreJobPSMStats
/****************************************************
** 
**	Desc:	Updates the PSM stats in T_Analysis_Job_PSM_Stats for the specified analysis job
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	02/21/2012 mem - Initial version
**			05/08/2012 mem - Added @FDRThreshold, @TotalPSMsFDRFilter, @UniquePeptidesFDRFilter, and @UniqueProteinsFDRFilter
**			01/17/2014 mem - Added @MSGFThresholdIsEValue
**			01/21/2016 mem - Added @PercentMSnScansNoPSM and @MaximumScanGapAdjacentMSn
**			09/28/2016 mem - Added three @UniquePhosphopeptide parameters, two @MissedCleavageRatio parameters, and @TrypticPeptides, @KeratinPeptides, and @TrypsinPeptides
**    
*****************************************************/
(
	@Job int = 0,
	@MSGFThreshold float,
	@FDRThreshold float = 1,
	@SpectraSearched int,						-- Number of spectra that were searched
	@TotalPSMs int,								-- Stats based on @MSGFThreshold (Number of identified spectra)
	@UniquePeptides int,						-- Stats based on @MSGFThreshold
	@UniqueProteins int,						-- Stats based on @MSGFThreshold
	@TotalPSMsFDRFilter int = 0,				-- Stats based on @FDRThreshold  (Number of identified spectra)
	@UniquePeptidesFDRFilter int = 0,			-- Stats based on @FDRThreshold
	@UniqueProteinsFDRFilter int = 0,			-- Stats based on @FDRThreshold
	@MSGFThresholdIsEValue tinyint = 0,			-- Set to 1 if @MSGFThreshold is actually an EValue
	@PercentMSnScansNoPSM real = 0,				-- Percent (between 0 and 100) measuring the percent of MSn scans that did not have a filter passing PSM
	@MaximumScanGapAdjacentMSn int = 0,			-- Maximum number of scans separating two MS2 spectra with search results; large gaps indicates that a processing thread in MSGF+ crashed and the results may be incomplete
	@UniquePhosphopeptideCountFDR int = 0,		-- Number of Phosphopeptides; filtered using @FDRThreshold
	@UniquePhosphopeptidesCTermK int = 0,		-- Number of Phosphopeptides with K on the C-terminus
	@UniquePhosphopeptidesCTermR int = 0,		-- Number of Phosphopeptides with R on the C-terminus
	@MissedCleavageRatio real = 0,				-- Value between 0 and 1; computed as the number of unique peptides with a missed cleavage / number of unique peptides
	@MissedCleavageRatioPhospho real = 0,		-- Value between 0 and 1; like @MissedCleavageRatio but for phosphopeptides
	@TrypticPeptides int = 0,					-- Number of tryptic peptides (partially or fully tryptic)
	@KeratinPeptides int = 0,					-- Number of peptides from Keratin
	@TrypsinPeptides int = 0,					-- Number of peptides from Trypsin
	@message varchar(255) = '' output,
	@infoOnly tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @Job = IsNull(@Job, 0)
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)	
	Set @FDRThreshold = IsNull(@FDRThreshold, 1)
	Set @MSGFThresholdIsEValue = IsNull(@MSGFThresholdIsEValue, 0)
	
	Set @PercentMSnScansNoPSM = IsNull(@PercentMSnScansNoPSM, 0)
	Set @MaximumScanGapAdjacentMSn = IsNull(@MaximumScanGapAdjacentMSn,0)

	Set @UniquePhosphopeptideCountFDR = IsNull(@UniquePhosphopeptideCountFDR, 0)
	Set @UniquePhosphopeptidesCTermK = IsNull(@UniquePhosphopeptidesCTermK, 0)
	Set @UniquePhosphopeptidesCTermR = IsNull(@UniquePhosphopeptidesCTermR, 0)
	Set @MissedCleavageRatio = IsNull(@MissedCleavageRatio, 0)
	Set @MissedCleavageRatioPhospho = IsNull(@MissedCleavageRatioPhospho, 0)

	Set @TrypticPeptides = IsNull(@TrypticPeptides, 0)
	Set @KeratinPeptides = IsNull(@KeratinPeptides, 0)
	Set @TrypsinPeptides = IsNull(@TrypsinPeptides, 0)

	---------------------------------------------------
	-- Make sure @Job is defined in T_Analysis_Job
	---------------------------------------------------
	
	IF NOT EXISTS (SELECT * FROM T_Analysis_Job where AJ_jobID = @Job)
	Begin
		Set @message = 'Job not found in T_Analysis_Job: ' + CONVERT(varchar(12), @job)
		return 50000
	End
	
	If @infoOnly <> 0
	Begin
		-----------------------------------------------
		-- Preview the data, then exit
		-----------------------------------------------
		
		SELECT @Job AS Job,
		       @MSGFThreshold AS MSGF_Threshold,
		       @FDRThreshold AS FDR_Threshold,
		       @MSGFThresholdIsEValue AS MSGF_Threshold_Is_EValue,
		       @SpectraSearched AS Spectra_Searched,
		       @TotalPSMs AS Total_PSMs_MSGF,
		       @UniquePeptides AS Unique_Peptides_MSGF,
		       @UniqueProteins AS Unique_Proteins_MSGF,
		       @TotalPSMsFDRFilter AS Total_PSMs_FDR,
		       @UniquePeptidesFDRFilter AS Unique_Peptides_FDR,
		       @UniqueProteinsFDRFilter AS Unique_Proteins_FDR,	       
		       @PercentMSnScansNoPSM AS Percent_MSn_Scans_NoPSM,
		       @MaximumScanGapAdjacentMSn AS Maximum_ScanGap_Adjacent_MSn,
		       @UniquePhosphopeptideCountFDR AS Phosphopeptides,
		       @UniquePhosphopeptidesCTermK AS CTermK_Phosphopeptides,
		       @UniquePhosphopeptidesCTermR AS CTermR_Phosphopeptides,
		       @MissedCleavageRatio AS Missed_Cleavage_Ratio_FDR,
		       @MissedCleavageRatioPhospho AS MissedCleavageRatioPhospho,
		       @TrypticPeptides AS Tryptic_Peptides,
		       @KeratinPeptides AS Keratin_Peptides,
		       @TrypsinPeptides AS Trypsin_Peptides
		
		Goto Done
	End

	
	-----------------------------------------------
	-- Add/Update T_Analysis_Job_PSM_Stats using a MERGE statement
	-----------------------------------------------
	--
	;
	MERGE T_Analysis_Job_PSM_Stats AS target
	USING 
		(SELECT @Job AS Job,
                @MSGFThreshold AS MSGF_Threshold,
                @FDRThreshold AS FDR_Threshold,
                @MSGFThresholdIsEValue AS MSGF_Threshold_Is_EValue,
                @SpectraSearched AS Spectra_Searched,
                @TotalPSMs AS Total_PSMs_MSGF,
                @UniquePeptides AS Unique_Peptides_MSGF,
                @UniqueProteins AS Unique_Proteins_MSGF,
                @TotalPSMsFDRFilter AS Total_PSMs_FDR,
		        @UniquePeptidesFDRFilter AS Unique_Peptides_FDR,
		        @UniqueProteinsFDRFilter AS Unique_Proteins_FDR,
		        @PercentMSnScansNoPSM AS Percent_MSn_Scans_NoPSM,
		        @MaximumScanGapAdjacentMSn AS Maximum_ScanGap_Adjacent_MSn,
		        @MissedCleavageRatio AS Missed_Cleavage_Ratio_FDR,
		        @TrypticPeptides AS Tryptic_Peptides_FDR,
		        @KeratinPeptides AS Keratin_Peptides_FDR,
		        @TrypsinPeptides AS Trypsin_Peptides_FDR		        
		) AS Source (Job, MSGF_Threshold, FDR_Threshold, MSGF_Threshold_Is_EValue, Spectra_Searched,
                     Total_PSMs_MSGF, Unique_Peptides_MSGF, Unique_Proteins_MSGF,
                     Total_PSMs_FDR, Unique_Peptides_FDR, Unique_Proteins_FDR,
                     Percent_MSn_Scans_NoPSM, Maximum_ScanGap_Adjacent_MSn, Missed_Cleavage_Ratio_FDR,
                     Tryptic_Peptides_FDR, Keratin_Peptides_FDR, Trypsin_Peptides_FDR
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
	
	If @UniquePhosphopeptideCountFDR = 0
	Begin
		-----------------------------------------------
		-- No phosphopeptide results for this job
		-- Make sure T_Analysis_Job_PSM_Stats_Phospho does not have this job
		-----------------------------------------------
		--
		DELETE FROM T_Analysis_Job_PSM_Stats_Phospho
		WHERE Job = @Job
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
			(SELECT @Job AS Job,
					@UniquePhosphopeptideCountFDR AS Phosphopeptides,
					@UniquePhosphopeptidesCTermK AS CTermK_Phosphopeptides,
					@UniquePhosphopeptidesCTermR AS CTermR_Phosphopeptides,
					@MissedCleavageRatioPhospho AS MissedCleavageRatio
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
	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in StoreJobPSMStats'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		If @InfoOnly = 0
			Exec PostLogEntry 'Error', @message, 'StoreJobPSMStats'
	End
	
	If Len(@message) > 0 AND @InfoOnly <> 0
		Print @message


	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[StoreJobPSMStats] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreJobPSMStats] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreJobPSMStats] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreJobPSMStats] TO [svc-dms] AS [dbo]
GO
