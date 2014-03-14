/****** Object:  StoredProcedure [dbo].[AutoUpdateDatasetRatingViaQCMetrics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AutoUpdateDatasetRatingViaQCMetrics
/****************************************************
** 
**	Desc:	Looks for Datasets that have low QC metric values
**          and auto-updates their rating to Not_Released
**
**			If one more more entries is found, then updates @MatchingPRN and @MatchingUserID for the first match
**		
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	10/18/2012
**			01/16/2014 mem - Added parameter @ExperimentExclusion
**    
*****************************************************/
(
	@CampaignName varchar(128) = 'QC-Shew-Standard',					-- Campaign name to filter on; filter uses Like so the name can contain a wild card
	@ExperimentExclusion varchar(128) = '%Intact%',
	@DatasetCreatedMinimum datetime = '1/1/2000',
	@InfoOnly tinyint = 1,
	@message varchar(128) = '' output 
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @ThresholdP_2A int = 250
	Declare @ThresholdP_2C int = 100
	
	----------------------------------------------
	-- Validate the Inputs
	----------------------------------------------
	--
	-- Do not allow @CampaignName to be blank
	Set @CampaignName = IsNull(@CampaignName, '')
	If @CampaignName = ''
		Set @CampaignName = 'QC-Shew-Standard'
	
	Set @ExperimentExclusion = IsNull(@ExperimentExclusion, '')
	If @ExperimentExclusion = ''
		Set @ExperimentExclusion = 'FakeNonExistentExperiment'
		
	Set @DatasetCreatedMinimum = IsNull(@DatasetCreatedMinimum, '1/1/2000')
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @message = ''
	
	CREATE TABLE #Tmp_DatasetsToUpdate (
		Dataset_ID int not null
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_DatasetsToUpdate ON #Tmp_DatasetsToUpdate (Dataset_ID)

	----------------------------------------------
	-- Find Candidate Datasets
	----------------------------------------------
	INSERT INTO #Tmp_DatasetsToUpdate (Dataset_ID)
	SELECT DS.Dataset_ID
	FROM T_Dataset DS
	     INNER JOIN T_Instrument_Name InstName
	       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
	     INNER JOIN T_Dataset_QC DQC
	       ON DS.Dataset_ID = DQC.Dataset_ID
	     INNER JOIN T_Experiments E
	       ON DS.Exp_ID = E.Exp_ID
	     INNER JOIN T_Campaign C
	       ON E.EX_campaign_ID = C.Campaign_ID
	     INNER JOIN T_DatasetTypeName DTN
	       ON DS.DS_type_ID = DTN.DST_Type_ID
	WHERE DS.DS_rating = 5 AND
	      DQC.P_2A < @ThresholdP_2A AND      -- Number of tryptic peptides; total spectra count
	      DQC.P_2C < @ThresholdP_2C AND      -- Number of tryptic peptides; unique peptide count
	      DTN.DST_name LIKE '%msn%' AND
	      DS.DS_created >= @DatasetCreatedMinimum AND
	      C.Campaign_Num LIKE @CampaignName AND
	      NOT E.Experiment_Num LIKE @ExperimentExclusion		  
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @InfoOnly <> 0
	Begin
		-- Preview the datasets that would be updated
		
		SELECT C.Campaign_Num AS Campaign,
		       InstName.IN_name AS Instrument,
		       DS.DS_created AS Dataset_Created,
		       DS.Dataset_Num AS Dataset,
		       DTN.DST_name AS Dataset_Type,
		       DS.DS_comment AS [Comment],
		       DQC.P_2A,
		       DQC.P_2C
		FROM T_Dataset DS
		     INNER JOIN #Tmp_DatasetsToUpdate U
		       ON DS.Dataset_ID = U.Dataset_ID
		     INNER JOIN T_Instrument_Name InstName
		       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
		     INNER JOIN T_Dataset_QC DQC
		       ON DS.Dataset_ID = DQC.Dataset_ID
		     INNER JOIN T_Experiments E
		       ON DS.Exp_ID = E.Exp_ID
		     INNER JOIN T_Campaign C
		       ON E.EX_campaign_ID = C.Campaign_ID
		     INNER JOIN T_DatasetTypeName DTN
		       ON DS.DS_type_ID = DTN.DST_Type_ID
	    --
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		Set @message = 'Found ' + Convert(varchar(12), @myRowCount) + ' dataset'
		If @myRowCount <> 1
			Set @message = @message + 's'
		Set @message = @message + ' with'

	End
	Else
	Begin
		-- Update the rating
		
		UPDATE DS
		SET DS_Comment = CASE WHEN DS_comment = '' THEN ''
		                      ELSE DS_comment + '; '
		                 END + 'Not released: SMAQC P_2C = ' + CONVERT(varchar(12), Convert(int, DQC.P_2C)),
		    DS_Rating = - 5
		FROM T_Dataset DS
		     INNER JOIN #Tmp_DatasetsToUpdate U
		       ON DS.Dataset_ID = U.Dataset_ID
		     INNER JOIN T_Dataset_QC DQC
		       ON DS.Dataset_ID = DQC.Dataset_ID
	    --
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed ' + Convert(varchar(12), @myRowCount) + ' dataset'
		If @myRowCount <> 1
			Set @message = @message + 's'
		Set @message = @message + ' to Not Released since'
	
	End

	
	Set @message = @message + ' P_2A below ' + Convert(varchar(12), @ThresholdP_2A) + ' and P_2C below ' + Convert(varchar(12), @ThresholdP_2C)

	If @InfoOnly <> 0
		Print @message
	Else
	Begin
		If @myRowCount > 0
			Exec PostLogEntry 'Normal', @message, 'AutoUpdateDatasetRatingViaQCMetrics'
	End
	
	return @myError

GO
