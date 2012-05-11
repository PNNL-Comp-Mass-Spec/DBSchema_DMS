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
**    
*****************************************************/
(
	@Job int = 0,
	@MSGFThreshold float,
	@FDRThreshold float = 1,
	@SpectraSearched int,				-- Number of spectra that were searched
	@TotalPSMs int,						-- Stats based on @MSGFThreshold (Number of identified spectra)
	@UniquePeptides int,				-- Stats based on @MSGFThreshold
	@UniqueProteins int,				-- Stats based on @MSGFThreshold
	@TotalPSMsFDRFilter int = 0,		-- Stats based on @FDRThreshold  (Number of identified spectra)
	@UniquePeptidesFDRFilter int = 0,	-- Stats based on @FDRThreshold
	@UniqueProteinsFDRFilter int = 0,	-- Stats based on @FDRThreshold
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
		       @SpectraSearched AS Spectra_Searched,
		       @TotalPSMs AS Total_PSMs_MSGF,
		       @UniquePeptides AS Unique_Peptides_MSGF,
		       @UniqueProteins AS Unique_Proteins_MSGF,
		       @TotalPSMsFDRFilter AS Total_PSMs_FDR,
		       @UniquePeptidesFDRFilter AS Unique_Peptides_FDR,
		       @UniqueProteinsFDRFilter AS Unique_Proteins_FDR
		
		Goto Done
	End

	
	-----------------------------------------------
	-- Add/Update T_Analysis_Job_PSM_Stats using a MERGE statement
	-----------------------------------------------
	--
	MERGE T_Analysis_Job_PSM_Stats AS target
	USING 
		(SELECT @Job AS Job,
                @MSGFThreshold AS MSGF_Threshold,
                @FDRThreshold AS FDR_Threshold,
                @SpectraSearched AS Spectra_Searched,
                @TotalPSMs AS Total_PSMs_MSGF,
                @UniquePeptides AS Unique_Peptides_MSGF,
                @UniqueProteins AS Unique_Proteins_MSGF,
                @TotalPSMsFDRFilter AS Total_PSMs_FDR,
		        @UniquePeptidesFDRFilter AS Unique_Peptides_FDR,
		        @UniqueProteinsFDRFilter AS Unique_Proteins_FDR
		) AS Source (Job, MSGF_Threshold, FDR_Threshold, Spectra_Searched,
                     Total_PSMs_MSGF, Unique_Peptides_MSGF, Unique_Proteins_MSGF,
                     Total_PSMs_FDR, Unique_Peptides_FDR, Unique_Proteins_FDR)
	    ON (target.Job = Source.Job)
	
	WHEN Matched 
		THEN UPDATE 
			Set MSGF_Threshold = Source.MSGF_Threshold,
			    FDR_Threshold = Source.FDR_Threshold,
                Spectra_Searched = Source.Spectra_Searched,
                Total_PSMs = Source.Total_PSMs_MSGF, 
                Unique_Peptides = Source.Unique_Peptides_MSGF, 
                Unique_Proteins = Source.Unique_Proteins_MSGF,
                Total_PSMs_FDR_Filter = Source.Total_PSMs_FDR, 
                Unique_Peptides_FDR_Filter = Source.Unique_Peptides_FDR, 
                Unique_Proteins_FDR_Filter = Source.Unique_Proteins_FDR,
                Last_Affected = GetDate()
				
	WHEN Not Matched THEN
		INSERT (Job,
		        MSGF_Threshold,
		        FDR_Threshold,
		        Spectra_Searched,
		        Total_PSMs,
		        Unique_Peptides,
		        Unique_Proteins, 
		        Total_PSMs_FDR_Filter,
                Unique_Peptides_FDR_Filter,
                Unique_Proteins_FDR_Filter,
				Last_Affected 
			   )
		VALUES ( Source.Job,
		         Source.MSGF_Threshold,
		         Source.FDR_Threshold,
		         Source.Spectra_Searched,
                 Source.Total_PSMs_MSGF, 
                 Source.Unique_Peptides_MSGF, 
                 Source.Unique_Proteins_MSGF,
                 Source.Total_PSMs_FDR,
                 Source.Unique_Peptides_FDR, 
                 Source.Unique_Proteins_FDR,
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
GRANT EXECUTE ON [dbo].[StoreJobPSMStats] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreJobPSMStats] TO [svc-dms] AS [dbo]
GO
