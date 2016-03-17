/****** Object:  StoredProcedure [dbo].[UpdateDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateDatasets
/****************************************************
**
**	Desc:
**      Updates parameters to new values for datasets in list
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	jds
**	Date:	09/21/2006
**			03/28/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUserMultiID (Ticket #644)
**			08/19/2010 grk - try-catch for error handling
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			03/30/2015 mem - Tweak warning message grammar
**			10/07/2015 mem - Added @mode "preview"
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
    @datasetList varchar(6000),
    @state varchar(32) = '',
    @rating varchar(32) = '',
    @comment varchar(255) = '',
    @findText varchar(255) = '',
    @replaceText varchar(255) = '',
    @mode varchar(12) = 'update',		-- Can be update or preview
    @message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	declare @msg varchar(512)
	declare @list varchar(1024)

	declare @DatasetStateUpdated tinyint
	declare @DatasetRatingUpdated tinyint
	set @DatasetStateUpdated = 0
	set @DatasetRatingUpdated = 0

	declare @datasetCount int = 0

	Set @state = IsNull(@state, '')	
	If @state = ''
		Set @state = '[no change]'

	Set @rating = IsNull(@rating, '')	
	If @rating = ''
		Set @rating = '[no change]'

	Set @comment = IsNull(@comment, '')	
	If @comment = ''
		Set @comment = '[no change]'

	Set @findText = IsNull(@findText, '')	
	If @findText = ''
		Set @findText = '[no change]'

	Set @replaceText = IsNull(@replaceText, '')	
	If @replaceText = ''
		Set @replaceText = '[no change]'


	BEGIN TRY 

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	if @datasetList = ''
	begin
		set @msg = 'Dataset list is empty'
		print @msg
		RAISERROR (@msg, 11, 1)
	end


	if (@findText = '[no change]' and @replaceText <> '[no change]') OR (@findText <> '[no change]' and @replaceText = '[no change]')
	begin
		set @msg = 'The Find In Comment and Replace In Comment enabled flags must both be enabled or disabled'
		print @msg
		RAISERROR (@msg, 11, 2)
	end

	---------------------------------------------------
	--  Create temporary tables to hold the list of datasets
	---------------------------------------------------
 
 	CREATE TABLE #TDS (
		DatasetNum varchar(128) NOT NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Failed to create temporary dataset table'
		print @msg
		RAISERROR (@msg, 11, 3)
	end

	CREATE TABLE #TmpDatasetSchedulePredefine (
		Entry_ID int Identity(1,1),
		DatasetNum varchar(128) NOT NULL
	)
	
 	---------------------------------------------------
	-- Populate table from dataset list  
	---------------------------------------------------

	INSERT INTO #TDS (DatasetNum)
	SELECT DISTINCT Value
	FROM udfParseDelimitedList(@datasetList, ',')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error populating temporary dataset table'
		print @msg
		RAISERROR (@msg, 11, 4)
	end

 	---------------------------------------------------
	-- Verify that all datasets exist 
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT @list = @list + CASE
	                           WHEN @list = '' THEN DatasetNum
	                           ELSE ', ' + DatasetNum
	                       END
	FROM #TDS
	WHERE NOT DatasetNum IN ( SELECT Dataset_Num FROM T_Dataset )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error checking dataset existence'
		print @msg
		RAISERROR (@msg, 11, 20)
	end
	--
	if @list <> ''
	begin
		set @msg = 'The following datasets were not in the database: "' + @list + '"'
		print @msg
		RAISERROR (@msg, 11, 20)
	end
	
	SELECT @datasetCount = COUNT(*) 
	FROM #TDS
	
	set @message = 'Number of affected datasets: ' + cast(@datasetCount as varchar(12))

	---------------------------------------------------
	-- Resolve state name
	---------------------------------------------------
	declare @stateID int
	set @stateID = 0
	--
	if @state <> '[no change]'
	begin
		--
		SELECT @stateID = Dataset_state_ID
		FROM  T_DatasetStateName
		WHERE (DSS_name = @state)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up state name'
			print @msg
			RAISERROR (@msg, 11, 5)
		end
		--
		if @stateID = 0
		begin
			set @msg = 'Could not find state'
			print @msg
			RAISERROR (@msg, 11, 6)
		end
	end -- if @state

	
	---------------------------------------------------
	-- Resolve rating name
	---------------------------------------------------
	declare @ratingID int
	set @ratingID = 0
	--
	if @rating <> '[no change]'
	begin
		--
		SELECT @ratingID = DRN_state_ID
		FROM  T_DatasetRatingName
		WHERE (DRN_name = @rating)	
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up rating name'
			print @msg
			RAISERROR (@msg, 11, 7)
		end
		--
		if @ratingID = 0
		begin
			set @msg = 'Could not find rating'
			print @msg
			RAISERROR (@msg, 11, 8)
		end
	end -- if @rating

	
	If @Mode = 'preview'
	Begin

		SELECT Dataset_ID,
		       Dataset_Num,
		       DS_state_ID AS StateID,
		       CASE
		           WHEN @state <> '[no change]' THEN @stateID
		           ELSE DS_state_ID
		       END AS StateID_New,
		       DS_rating AS RatingID,
		       CASE
		           WHEN @rating <> '[no change]' THEN @ratingID
		           ELSE DS_rating
		       END AS RatingID_New,
		       DS_comment AS [Comment],
		       CASE
		           WHEN @comment <> '[no change]' THEN DS_comment + ' ' + @comment
		           ELSE DS_comment
		       END AS Comment_via_Append,
		       CASE
		           WHEN @findText <> '[no change]' AND
		                @replaceText <> '[no change]' THEN Replace(DS_comment, @findText, @replaceText)
		           ELSE DS_Comment
		       END AS Comment_via_Replace
		FROM T_Dataset
		WHERE (Dataset_Num IN ( SELECT DatasetNum FROM #TDS ))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
	End
	
 	---------------------------------------------------
	-- Update datasets from temporary table
	-- in cases where parameter has changed
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0

		---------------------------------------------------
		declare @transName varchar(32)
		set @transName = 'UpdateDatasets'
		begin transaction @transName

		-----------------------------------------------
		if @state <> '[no change]'
		begin
			UPDATE T_Dataset
			SET DS_state_ID = @stateID
			WHERE (Dataset_Num in (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				print @msg
				RAISERROR (@msg, 11, 9)
			end
			
			Set @DatasetStateUpdated = 1
		end

		-----------------------------------------------
		if @rating <> '[no change]'
		begin -- <UpdateRating>
			-- Find the datasets that have an existing rating of -5, -6, or -7
			INSERT INTO #TmpDatasetSchedulePredefine (DatasetNum)
			SELECT DS.Dataset_Num
			FROM T_Dataset DS
			     LEFT OUTER JOIN T_Analysis_Job J
			       ON DS.Dataset_ID = J.AJ_datasetID AND
			          J.AJ_DatasetUnreviewed = 0
			WHERE DS.Dataset_Num IN ( SELECT DatasetNum FROM #TDS ) AND
			      DS.DS_Rating IN (-5, -6, -7) AND
			      J.AJ_jobID IS NULL
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			
			UPDATE T_Dataset
			SET DS_rating = @ratingID
			WHERE (Dataset_Num in (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				print @msg
				RAISERROR (@msg, 11, 10)
			end
			
			Set @DatasetRatingUpdated = 1
			
			If Exists (Select * From #TmpDatasetSchedulePredefine) And @ratingID >= 2
			Begin -- <SchedulePredefines>
				Declare @EntryID int = 0
				Declare @CurrentDataset varchar(128)
				Declare @ContinueUpdate tinyint = 1
				
				While @ContinueUpdate > 0
				Begin -- <ForEach>
					SELECT TOP 1 @EntryID = Entry_ID, @CurrentDataset = DatasetNum
					FROM #TmpDatasetSchedulePredefine
					WHERE Entry_ID > @EntryID
					ORDER BY Entry_ID
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
					
					If @myRowCount = 0
						Set @ContinueUpdate = 0
					Else
						Exec SchedulePredefinedAnalyses @CurrentDataset
					
				End -- </ForEach>
				
			End -- </SchedulePredefines>
			
		end -- </UpdateRating>

		-----------------------------------------------
		if @comment <> '[no change]'
		begin
			UPDATE T_Dataset
			SET DS_comment = DS_comment + ' ' + @comment
			WHERE (Dataset_Num in (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				print @msg
				RAISERROR (@msg, 11, 11)
			end
		end

		-----------------------------------------------
		if @findText <> '[no change]' and @replaceText <> '[no change]'
		begin
			UPDATE T_Dataset 
			SET DS_comment = Replace(DS_comment, @findText, @replaceText)
			WHERE (Dataset_Num in (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				print @msg
				RAISERROR (@msg, 11, 12)
			end
		end

		commit transaction @transName
		
		
 		If Len(@callingUser) > 0 And (@DatasetStateUpdated <> 0 Or @DatasetRatingUpdated <> 0)
		Begin
			-- @callingUser is defined; call AlterEventLogEntryUserMultiID
			-- to alter the Entered_By field in T_Event_Log
			--

			-- Populate a temporary table with the list of Dataset IDs just updated
			CREATE TABLE #TmpIDUpdateList (
				TargetID int NOT NULL
			)
			
			CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
			
			INSERT INTO #TmpIDUpdateList (TargetID)
			SELECT DISTINCT Dataset_ID
			FROM T_Dataset
			WHERE (Dataset_Num IN (SELECT DatasetNum FROM #TDS))
			
			If @DatasetStateUpdated <> 0
				Exec AlterEventLogEntryUserMultiID 4, @stateID, @callingUser
				
			If @DatasetRatingUpdated <> 0
				Exec AlterEventLogEntryUserMultiID 8, @ratingID, @callingUser
		End
		
	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

	
	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = Convert(varchar(12), @datasetCount) + ' datasets updated'
	Exec PostUsageLogEntry 'UpdateDatasets', @UsageMessage

	return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateDatasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasets] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasets] TO [PNL\D3M580] AS [dbo]
GO
