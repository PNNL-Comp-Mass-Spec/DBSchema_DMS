/****** Object:  StoredProcedure [dbo].[AddMissingPredefinedJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.AddMissingPredefinedJobs
/****************************************************
**
**	Desc:	Looks for Datasets that don't have predefined analysis jobs
**			but possibly should.  Calls SchedulePredefinedAnalyses for each.  
**			This procedure is intended to be run once per day to add missing jobs
**			for datasets created within the last 30 days (but more than 12 hours ago)
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	05/23/2008 mem - Ticket #675
**			10/30/2008 mem - Updated to only create jobs for datasets in state 3=Complete
**			05/14/2009 mem - Added parameters @AnalysisToolNameFilter and @ExcludeDatasetsNotReleased
**			10/25/2010 mem - Added parameter @DatasetNameIgnoreExistingJobs
**			11/18/2010 mem - Now skipping datasets with a rating of -6 (Rerun, good data) when @ExcludeDatasetsNotReleased is non-zero
**			02/10/2011 mem - Added parameters @ExcludeUnreviewedDatasets and @InstrumentSkipList
**			05/24/2011 mem - Added parameter @IgnoreJobsCreatedBeforeDisposition
**						   - Added support for rating -7
**			08/05/2013 mem - Now passing @AnalysisToolNameFilter to EvaluatePredefinedAnalysisRules when @InfoOnly is non-zero
**						   - Added parameter @CampaignFilter
**			01/08/2014 mem - Now returning additional debug information when @InfoOnly > 0
**			06/18/2014 mem - Now passing default to udfParseDelimitedList
**			02/23/2016 mem - Add set XACT_ABORT on
**			03/03/2017 mem - Exclude datasets associated with the Tracking experiment
**			               - Exclude datasets of type Tracking
**			03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**
*****************************************************/
(
	@InfoOnly tinyint = 0,
	@MaxDatasetsToProcess int = 0,
	@DayCountForRecentDatasets int = 30,						-- Will examine datasets created within this many days of the present
	@PreviewOutputType varchar(12) = 'Show Jobs',				-- Used if @InfoOnly = 1; options are 'Show Rules' or 'Show Jobs'
	@AnalysisToolNameFilter varchar(128) = '',					-- Optional: if not blank, then only considers predefines and jobs that match the given tool name (can contain wildcards)
	@ExcludeDatasetsNotReleased tinyint = 1,					-- When non-zero, then excludes datasets with a rating of -5 (we always exclude datasets with a rating of -1, -2, and -10)
	@ExcludeUnreviewedDatasets tinyint = 1,						-- When non-zero, then excludes datasets with a rating of -10
	@InstrumentSkipList varchar(1024) = 'Agilent_GC_MS_01, TSQ_1, TSQ_3',		-- Comma-separated list of instruments to skip
	@message varchar(512) = '' output,
	@DatasetNameIgnoreExistingJobs varchar(128) = '',			-- If defined, then we'll create predefined jobs for this dataset even if it has existing jobs
	@IgnoreJobsCreatedBeforeDisposition tinyint = 1,			-- When non-zero, then ignore jobs created before the dataset was dispositioned
	@CampaignFilter varchar(128) = ''							-- Optional: if not blank, then filters on the given campaign name
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @continue tinyint
	declare @DatasetsProcessed int
	declare @DatasetsWithNewJobs int
	
	declare @EntryID int
	declare @DatasetID int
	declare @DatasetName varchar(256)

	declare @JobCountAdded int
	declare @StartDate datetime
		
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @MaxDatasetsToProcess = IsNull(@MaxDatasetsToProcess, 0)
	Set @DayCountForRecentDatasets = IsNull(@DayCountForRecentDatasets, 30)
	Set @PreviewOutputType = IsNull(@PreviewOutputType, 'Show Rules')
	Set @AnalysisToolNameFilter = IsNull(@AnalysisToolNameFilter, '')
	Set @ExcludeDatasetsNotReleased = IsNull(@ExcludeDatasetsNotReleased, 1)
	Set @ExcludeUnreviewedDatasets = IsNull(@ExcludeUnreviewedDatasets, 1)
	Set @InstrumentSkipList = IsNull(@InstrumentSkipList, '')
	set @message = ''
	Set @DatasetNameIgnoreExistingJobs = IsNull(@DatasetNameIgnoreExistingJobs, '')
	Set @IgnoreJobsCreatedBeforeDisposition = IsNull(@IgnoreJobsCreatedBeforeDisposition, 1)
	Set @CampaignFilter = IsNull(@CampaignFilter, '')

	If @DayCountForRecentDatasets < 1
		Set @DayCountForRecentDatasets = 1
	
	If @InfoOnly <> 0 And (Not @PreviewOutputType IN ('Show Rules', 'Show Jobs'))
	Begin
		set @message = 'Unknown value for @PreviewOutputType (' + @PreviewOutputType + '); should be "Show Rules" or "Show Jobs"'
		
		SELECT @Message as Message
		
		set @myError = 51001
		Goto Done
	End
	
	---------------------------------------------------
	-- Create two temporary tables
	---------------------------------------------------

	CREATE TABLE #Tmp_DatasetsToProcess (
		Entry_ID int NOT NULL Identity(1,1),
		Dataset_ID int NOT NULL,
		Process_Dataset tinyint
	)
	
	CREATE TABLE #TmpDSRatingExclusionList (
		Rating int
	)
	
	-- Populate #TmpDSRatingExclusionList
	INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-1)		-- No Data (Blank/Bad)
	INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-2)		-- Data Files Missing
	
	If @ExcludeUnreviewedDatasets <> 0
		INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-10)		-- Unreviewed
	
	If @ExcludeDatasetsNotReleased <> 0
	Begin
		INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-5)	-- Not Released
		INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-6)	-- Rerun (Good Data)
		INSERT INTO #TmpDSRatingExclusionList (Rating) Values (-7)	-- Rerun (Superseded)
	End

	---------------------------------------------------
	-- Find datasets that were created within the last @DayCountForRecentDatasets days
	-- (but over 12 hours ago) that do not have analysis jobs
	-- Also excludes datasets with an undesired state or undesired rating
	-- Optionally only matches analysis tools with names matching @AnalysisToolNameFilter
	---------------------------------------------------
	--
	-- First construct a list of all recent datasets that have an instrument class
	-- that has an active predefined job
	-- Optionally filter on campaign
	--
	INSERT INTO #Tmp_DatasetsToProcess( Dataset_ID, Process_Dataset )
	SELECT DISTINCT DS.Dataset_ID, 1 AS Process_Dataset
	FROM T_Dataset DS
	     INNER JOIN T_DatasetTypeName DSType
	       ON DSType.DST_Type_ID = DS.DS_type_ID
	     INNER JOIN T_Instrument_Name InstName
	       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
	     INNER JOIN T_Experiments E
	       ON DS.Exp_ID = E.Exp_ID
	     INNER JOIN T_Campaign C
	       ON E.EX_campaign_ID = C.Campaign_ID
	WHERE (NOT DS.DS_rating IN (SELECT Rating FROM #TmpDSRatingExclusionList)) AND
	      (DS.DS_state_ID = 3) AND
	      (@CampaignFilter = '' Or C.Campaign_Num Like @CampaignFilter) AND
	      (NOT DSType.DST_name IN ('Tracking')) AND
	      (NOT E.Experiment_Num in ('Tracking')) AND	      
	      (DS.DS_created BETWEEN DATEADD(day, -@DayCountForRecentDatasets, GETDATE()) AND 
	                             DATEADD(hour, - 12, GETDATE())) AND
	      InstName.IN_Class IN ( SELECT DISTINCT InstClass.IN_class
	                             FROM T_Predefined_Analysis PA
	                                  INNER JOIN T_Instrument_Class InstClass
	                                    ON PA.AD_instrumentClassCriteria = InstClass.IN_class
	                             WHERE (PA.AD_enabled <> 0) AND
	                                   (@AnalysisToolNameFilter = '' OR
	                                    PA.AD_analysisToolName LIKE @AnalysisToolNameFilter) )
	ORDER BY DS.Dataset_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myError <> 0
	Begin
		Set @message = 'Error populating #Tmp_DatasetsToProcess'
		Goto Done
	End

	-- Now exclude any datasets that have analysis jobs in T_Analysis_Job
	-- Filter on @AnalysisToolNameFilter if not empty
	--
	UPDATE #Tmp_DatasetsToProcess
	Set Process_Dataset = 0
	FROM #Tmp_DatasetsToProcess DS
	     INNER JOIN ( SELECT AJ.AJ_datasetID AS Dataset_ID
	                  FROM T_Analysis_Job AJ
	                       INNER JOIN T_Analysis_Tool Tool
	                         ON AJ.AJ_analysisToolID = Tool.AJT_toolID
	    WHERE (@AnalysisToolNameFilter = '' OR Tool.AJT_toolName LIKE @AnalysisToolNameFilter) AND
	                        (@IgnoreJobsCreatedBeforeDisposition = 0 OR AJ.AJ_DatasetUnreviewed = 0 )
	                 ) JL
	       ON DS.Dataset_ID = JL.Dataset_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myError <> 0
	Begin
		Set @message = 'Error excluding unwanted datasets from #Tmp_DatasetsToProcess'
		Goto Done
	End

	-- Exclude datasets from instruments in @InstrumentSkipList
	If @InstrumentSkipList <> ''
	Begin
		UPDATE #Tmp_DatasetsToProcess
		SET Process_Dataset = 0
		FROM #Tmp_DatasetsToProcess Target
		 INNER JOIN T_Dataset DS
		       ON Target.Dataset_ID = DS.Dataset_ID
		     INNER JOIN T_Instrument_Name InstName 
		     ON InstName.Instrument_ID = DS.DS_instrument_name_ID
    	     INNER JOIN udfParseDelimitedList(@InstrumentSkipList, default, 'AddMissingPredefinedJobs') AS ExclusionList 
    	       ON InstName.IN_name = ExclusionList.Value
	End
	
	-- Add dataset @DatasetNameIgnoreExistingJobs
	If @DatasetNameIgnoreExistingJobs <> ''
	Begin
		UPDATE #Tmp_DatasetsToProcess
		SET Process_Dataset = 1
		FROM #Tmp_DatasetsToProcess Target
		     INNER JOIN T_Dataset DS
		  ON Target.Dataset_ID = DS.Dataset_ID
		WHERE DS.Dataset_Num = @DatasetNameIgnoreExistingJobs
	End
		
	If @InfoOnly <> 0
	Begin
		SELECT InstName.IN_name,
			    DS.Dataset_ID,
			    DS.Dataset_Num,
			    DS.DS_created,
			    DS.DS_comment,
			    DS.DS_state_ID,
			    DS.DS_rating,
			    DTP.Process_Dataset
		FROM #Tmp_DatasetsToProcess DTP
			    INNER JOIN T_Dataset DS
			    ON DTP.Dataset_ID = DS.Dataset_ID
			    INNER JOIN T_Instrument_Name InstName
			    ON DS.DS_instrument_name_ID = InstName.Instrument_ID
		WHERE DTP.Process_Dataset = 1
		ORDER BY InstName.IN_name, DS.Dataset_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		IF @InfoOnly > 1
			SELECT 'Ignored' As Comment,
			        InstName.IN_name,
					DS.Dataset_ID,
					DS.Dataset_Num,
					DS.DS_created,
					DS.DS_comment,
					DS.DS_state_ID,
					DS.DS_rating,
					DTP.Process_Dataset
			FROM #Tmp_DatasetsToProcess DTP
					INNER JOIN T_Dataset DS
					ON DTP.Dataset_ID = DS.Dataset_ID
					INNER JOIN T_Instrument_Name InstName
					ON DS.DS_instrument_name_ID = InstName.Instrument_ID
			WHERE DTP.Process_Dataset = 0
			ORDER BY InstName.IN_name, DS.Dataset_ID
	End

	-- Count the number of entries with Process_Dataset = 1 in #Tmp_DatasetsToProcess
	SELECT @myRowCount = COUNT(*)
	FROM #Tmp_DatasetsToProcess
	WHERE Process_Dataset = 1
	
	If @myRowCount = 0
	Begin
		Set @message = 'All recent (valid) datasets with potential predefined jobs already have existing analysis jobs'
		If @InfoOnly <> 0
			SELECT @message AS Message
	End
	Else
	Begin -- <a>

		-- Remove any extra datasets from #Tmp_DatasetsToProcess
		DELETE FROM #Tmp_DatasetsToProcess
		WHERE Process_Dataset = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		---------------------------------------------------
		-- Loop through the datasets in #Tmp_DatasetsToProcess
		-- Call EvaluatePredefinedAnalysisRules or SchedulePredefinedAnalyses for each one
		---------------------------------------------------
		
		Set @DatasetsProcessed = 0
		Set @DatasetsWithNewJobs = 0
		
		Set @EntryID = 0
		Set @continue = 1
		
		While @continue = 1
		Begin -- <b>
			SELECT TOP 1 @EntryID = DTP.Entry_ID,
			             @DatasetID = DTP.Dataset_ID,
			             @DatasetName = DS.Dataset_Num
			FROM #Tmp_DatasetsToProcess DTP
			     INNER JOIN T_Dataset DS
			       ON DTP.Dataset_ID = DS.Dataset_ID
			WHERE Entry_ID > @EntryID
			ORDER BY Entry_ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount < 1
				Set @continue = 0
			Else
			Begin -- <c>
				Begin Try

					If @InfoOnly <> 0
					Begin
						Set @CurrentLocation = 'Calling SchedulePredefinedAnalyses for ' + @DatasetName
						
						Exec EvaluatePredefinedAnalysisRules @DatasetName, @PreviewOutputType, @message = @message output, @ExcludeDatasetsNotReleased=@ExcludeDatasetsNotReleased, @AnalysisToolNameFilter=@AnalysisToolNameFilter
					End
					
					
					Set @CurrentLocation = 'Calling SchedulePredefinedAnalyses for ' + @DatasetName
					Set @StartDate = GetDate()
					
					Exec @myError = SchedulePredefinedAnalyses @DatasetName, @AnalysisToolNameFilter=@AnalysisToolNameFilter, @ExcludeDatasetsNotReleased=@ExcludeDatasetsNotReleased, @infoOnly=@infoOnly
					
					If @myError = 0 And @infoOnly = 0
					Begin -- <e1>
						-- See if jobs were actually added by querying T_Analysis_Job
						
						Set @JobCountAdded = 0
						
						SELECT @JobCountAdded = COUNT(*)
						FROM T_Analysis_Job 
						WHERE AJ_DatasetID = @DatasetID AND 
								AJ_Created >= @StartDate
						--
						SELECT @myError = @@error, @myRowCount = @@rowcount
						
						If @JobCountAdded > 0
						Begin -- <f>
							UPDATE T_Analysis_Job
							SET AJ_Comment = IsNull(AJ_Comment, '') + ' (missed predefine)'
							WHERE AJ_DatasetID = @DatasetID AND 
								    AJ_Created >= @StartDate
							--
							SELECT @myError = @@error, @myRowCount = @@rowcount

							If @myRowCount <> @JobCountAdded
							Begin
								Set @message = 'Added ' + Convert(varchar(12), @JobCountAdded) + ' missing predefined analysis job(s) for dataset ' + @DatasetName + ', but updated the comment for ' + convert(varchar(12), @myRowCount) + ' job(s); mismatch is unexpected'
								Exec PostLogEntry 'Error', @message, 'AddMissingPredefinedJobs'
							End

							Set @message = 'Added ' + Convert(varchar(12), @JobCountAdded) + ' missing predefined analysis job'
							If @JobCountAdded <> 1
								Set @message = @message + 's'
								
							Set @message = @message + ' for dataset ' + @DatasetName
							
							Exec PostLogEntry 'Warning', @message, 'AddMissingPredefinedJobs'
							
							Set @DatasetsWithNewJobs = @DatasetsWithNewJobs + 1
						End
					End -- </e1>
					Else
					Begin -- <e2>
						-- Error code 1 means no matching rules; that's OK
						-- Log an error for any other error codes
						
						If @myError <> 1 And @infoOnly = 0
						Begin
							Set @message = 'Error calling SchedulePredefinedAnalyses for dataset ' + @DatasetName + '; error code ' + Convert(varchar(12), @myError)
							Exec PostLogEntry 'Error', @message, 'AddMissingPredefinedJobs'
							Set @message = ''
						End
					End -- </e2>				
				
						
				End Try
				Begin Catch
					-- Error caught; log the error then abort processing
					Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'AddMissingPredefinedJobs')
					exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
											@ErrorNum = @myError output, @message = @message output
											
				End Catch

				Set @DatasetsProcessed = @DatasetsProcessed + 1
			End -- </c>
			
			If @MaxDatasetsToProcess > 0 And @DatasetsProcessed >= @MaxDatasetsToProcess
				Set @continue = 0
		End -- </b>

		If @DatasetsProcessed > 0 And @infoOnly = 0
		Begin
			Set @message = 'Added predefined analysis jobs for ' + Convert(varchar(12), @DatasetsWithNewJobs) + ' dataset'
			If @DatasetsWithNewJobs <> 1
				Set @message = @message + 's'
			
			Set @message = @message + ' (processed ' + Convert(varchar(12), @DatasetsProcessed) + ' dataset'
			If @DatasetsProcessed <> 1
				Set @message = @message + 's'
				
			Set @message = @message + ')'

			If @DatasetsWithNewJobs > 0 And @InfoOnly = 0
				Exec PostLogEntry 'Normal', @message, 'AddMissingPredefinedJobs'

		End
		
	End -- </a>
	
Done:
	return @myError


GO
GRANT EXECUTE ON [dbo].[AddMissingPredefinedJobs] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddMissingPredefinedJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddMissingPredefinedJobs] TO [Limited_Table_Write] AS [dbo]
GO
