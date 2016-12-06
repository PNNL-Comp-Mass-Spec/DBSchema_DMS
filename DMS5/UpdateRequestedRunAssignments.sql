/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateRequestedRunAssignments
/****************************************************
**
**	Desc: 
**	Changes assignment properties (priority, instrument)
**	to given new value for given list of requested runs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	01/26/2003
**			12/11/2003 grk - removed LCMS cart modes
**			07/27/2007 mem - When @mode = 'instrument, then checking dataset type (@datasetTypeName) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #503)
**						   - Added output parameter @message to report the number of items updated
**			09/16/2009 mem - Now checking dataset type (@datasetTypeName) using Instrument_Allowed_Dataset_Type table (Ticket #748)
**			08/28/2010 mem - Now auto-switching @newValue to be instrument group instead of instrument name (when @mode = 'instrument')
**						   - Now validating dataset type for instrument using T_Instrument_Group_Allowed_DS_Type
**						   - Added try-catch for error handling
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			12/12/2011 mem - Added parameter @callingUser, which is passed to DeleteRequestedRun
**			06/26/2013 mem - Added mode 'instrumentIgnoreType' (doesn't validate dataset type when changing the instrument group) 
**					   mem - Added mode 'datasetType'
**			07/24/2013 mem - Added mode 'separationGroup'
**			02/23/2016 mem - Add set XACT_ABORT on
**			03/22/2016 mem - Now passing @skipDatasetCheck to DeleteRequestedRun
**    
*****************************************************/
(
	@mode varchar(32), -- 'priority', 'instrument', 'instrumentIgnoreType', 'datasetType', 'delete', 'separationGroup'
	@newValue varchar(512),
	@reqRunIDList varchar(2048),
	@message varchar(512)='' output,
	@callingUser varchar(128) = ''
)
As

	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @msg varchar(512)
	declare @continue int
	declare @RequestID int

	Declare @NewInstrumentGroup varchar(64) = ''
	Declare @NewSeparationGroup varchar(64) = ''

	Declare @NewDatasetType varchar(64) = ''
	Declare @NewDatasetTypeID int = 0
	
	declare @datasetTypeID int
	declare @datasetTypeName varchar(64)
	
	declare @RequestIDCount int
	declare @RequestIDFirst int

	declare @allowedDatasetTypes varchar(255) = ''
	Declare @RequestCount int = 0

	set @message = ''

	BEGIN TRY 
	
	---------------------------------------------------
	-- Populate a temporary table with the values in @reqRunIDList
	---------------------------------------------------

	CREATE TABLE #TmpRequestIDs (
		RequestID int
	)
	
	INSERT INTO #TmpRequestIDs (RequestID)
	SELECT Convert(int, Item)
	FROM MakeTableFromList(@reqRunIDList)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myError <> 0
		RAISERROR ('Error parsing Request ID List', 11, 1)
	
	If @myRowCount = 0
		-- @reqRunIDList was empty; nothing to do
		RAISERROR ('Request ID list was empty; nothing to do', 11, 2)

	Set @RequestCount = @myRowCount

	if @mode IN ('instrument', 'instrumentIgnoreType')
	Begin -- <a>
		
		---------------------------------------------------
		-- Validate the instrument group
		-- Note that as of 6/26/2013 mode 'instrument' does not appear to be used by the DMS website
		-- Mode 'instrumentIgnoreType' is used by http://dms2.pnl.gov/requested_run_admin/report
		---------------------------------------------------
		--
		-- Set the instrument group to @newValue for now
		set @NewInstrumentGroup = @newValue
		
		IF NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @NewInstrumentGroup)
		Begin
			-- Try to update instrument group using T_Instrument_Name
			SELECT @NewInstrumentGroup = IN_Group
			FROM T_Instrument_Name
			WHERE IN_Name = @newValue
		End
				
		---------------------------------------------------
		-- Make sure a valid instrument group was chosen (or auto-selected via an instrument name)
		-- This also assures the text is properly capitalized
		---------------------------------------------------

		SELECT @NewInstrumentGroup = IN_Group
		FROM T_Instrument_Group
		WHERE IN_Group = @NewInstrumentGroup
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		IF @myRowCount = 0
			RAISERROR ('Could not find entry in database for instrument group (or instrument) "%s"', 11, 3, @newValue)

		If @mode = 'instrument'
		Begin -- <b>
		
			---------------------------------------------------
			-- Make sure the Run Type (i.e. Dataset Type) defined for each of the run requests
			-- is appropriate for instrument (or instrument group) @instrumentName
			---------------------------------------------------
			--			
			-- Populate a temporary table with the dataset type names
			-- associated with the requests in #TmpRequestIDs
			
			CREATE TABLE #TmpDatasetTypeList (
				DatasetTypeName varchar(64),
				DatasetTypeID int,
				RequestIDCount int,
				RequestIDFirst int
			)

			INSERT INTO #TmpDatasetTypeList (
				DatasetTypeName, 
				DatasetTypeID, 
				RequestIDCount, 
				RequestIDFirst
			)
			SELECT DST.DST_Name AS DatasetTypeName, 
				DST.DST_Type_ID AS DatasetTypeID, 
				COUNT(RR.ID) AS RequestIDCount, 
				MIN(RR.ID) AS RequestIDFirst
			FROM #TmpRequestIDs INNER JOIN 
				T_Requested_Run RR ON #TmpRequestIDs.RequestID = RR.ID INNER JOIN
				T_DatasetTypeName DST ON RR.RDS_type_ID = DST.DST_Type_ID
			GROUP BY DST.DST_Name, DST.DST_Type_ID
			--	
			SELECT @myError = @@error, @myRowCount = @@rowcount

			-- Step through the entries in #TmpDatasetTypeList and verify each
			--  Dataset Type against T_Instrument_Group_Allowed_DS_Type
			
			SELECT @DatasetTypeID = Min(DatasetTypeID)-1
			FROM #TmpDatasetTypeList
			
			Set @continue = 1
			While @continue = 1
			Begin -- <c>
				SELECT TOP 1 @DatasetTypeID = DatasetTypeID,
							@DatasetTypeName = DatasetTypeName,
							@RequestIDCount = RequestIDCount,
							@RequestIDFirst = RequestIDFirst						 
				FROM #TmpDatasetTypeList
				WHERE DatasetTypeID > @DatasetTypeID
				ORDER BY DatasetTypeID
				--	
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myRowCount = 0
					Set @continue = 0
				Else
				Begin -- <d>
					---------------------------------------------------
					-- Verify that dataset type is valid for given instrument group
					---------------------------------------------------				

					If Not Exists (SELECT * FROM T_Instrument_Group_Allowed_DS_Type WHERE IN_Group = @NewInstrumentGroup AND Dataset_Type = @DatasetTypeName)
					begin
						SELECT @allowedDatasetTypes = dbo.GetInstrumentGroupDatasetTypeList(@NewInstrumentGroup)

						set @msg = 'Dataset Type "' + @DatasetTypeName + '" is invalid for instrument group "' + @NewInstrumentGroup + '"; valid types are "' + @allowedDatasetTypes + '"'
						If @RequestIDCount > 1
							set @msg = @msg + '; ' + Convert(varchar(12), @RequestIDCount) + ' conflicting Request IDs, starting with ID ' + Convert(varchar(12), @RequestIDFirst)
						Else
							set @msg = @msg + '; conflicting Request ID is ' + Convert(varchar(12), @RequestIDFirst)
						
						RAISERROR (@msg, 11, 4)
					end
		
				End -- </d>
			End -- </c>
		End -- </b>
	End -- </a>

	if @mode IN ('separationGroup')
	Begin
		
		---------------------------------------------------
		-- Validate the separation group
		-- Mode 'separationGroup' is used by http://dms2.pnl.gov/requested_run_admin/report
		---------------------------------------------------
		--
		-- Set the separation group to @newValue for now
		set @NewSeparationGroup = @newValue
		
		IF NOT EXISTS (SELECT * FROM T_Separation_Group WHERE Sep_Group = @NewSeparationGroup)
		Begin
			-- Try to update Separation group using T_Secondary_Sep
			SELECT @NewSeparationGroup = Sep_Group
			FROM T_Secondary_Sep
			WHERE SS_name = @newValue
		End
				
		---------------------------------------------------
		-- Make sure a valid separation group was chosen (or auto-selected via a separation name)
		-- This also assures the text is properly capitalized
		---------------------------------------------------

		SELECT @NewSeparationGroup = Sep_Group
		FROM T_Separation_Group
		WHERE Sep_Group = @NewSeparationGroup
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		IF @myRowCount = 0
			RAISERROR ('Could not find entry in database for separation group "%s"', 11, 3, @newValue)

	End


	if @mode IN ('datasetType')
	Begin
		
		---------------------------------------------------
		-- Validate the dataset type
		-- Mode 'datasetType' is used by http://dms2.pnl.gov/requested_run_admin/report
		---------------------------------------------------
		--
		-- Set the dataset type to @newValue for now
		set @NewDatasetType = @newValue
				
		---------------------------------------------------
		-- Make sure a valid dataset type was chosen
		---------------------------------------------------

		SELECT @NewDatasetType = DST_name, 
		       @NewDatasetTypeID = DST_Type_ID
		FROM T_DatasetTypeName
		WHERE (DST_name = @NewDatasetType)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		IF @myRowCount = 0
			RAISERROR ('Could not find entry in database for dataset type "%s"', 11, 3, @newValue)
		
	End 

	-------------------------------------------------
	-- Apply the changes, as defined by @mode
	-------------------------------------------------
	
	if @mode = 'priority'
	begin
		-- get priority numerical value
		--
		declare @pri int
		set @pri = cast(@newValue as int)
		
		-- if priority is being set to non-zero, clear note field also
		--
		UPDATE T_Requested_Run
		SET	RDS_priority = @pri, 
			RDS_note = CASE WHEN @pri > 0 THEN '' ELSE RDS_note END
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Set the priority to ' + Convert(varchar(12), @pri) + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'		
	end

	-------------------------------------------------
	if @mode IN ('instrument', 'instrumentIgnoreType')
	begin
		
		UPDATE T_Requested_Run
		SET	RDS_instrument_name = @NewInstrumentGroup
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed the instrument group to ' + @NewInstrumentGroup + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	end

	-------------------------------------------------
	if @mode IN ('separationGroup')
	begin
		
		UPDATE T_Requested_Run
		SET	RDS_Sec_Sep = @NewSeparationGroup
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed the separation group to ' + @NewSeparationGroup + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	end

	-------------------------------------------------
	if @mode = 'datasetType'
	begin
		
		UPDATE T_Requested_Run
		SET	RDS_type_ID = @NewDatasetTypeID
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed the dataset type to ' + @NewDatasetType + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	end
	
	-------------------------------------------------
	if @mode = 'delete'
	begin -- <a>
		-- Step through the entries in #TmpRequestIDs and delete each
		SELECT @RequestID = Min(RequestID)-1
		FROM #TmpRequestIDs
		
		Declare @CountDeleted int
		Set @CountDeleted = 0
		
		Set @continue = 1
		While @continue = 1
		Begin -- <b>
			SELECT TOP 1 @RequestID = RequestID
			FROM #TmpRequestIDs
			WHERE RequestID > @RequestID
			ORDER BY RequestID
			--	
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount = 0
				Set @continue = 0
			Else
			Begin -- <c>
				exec @myError = DeleteRequestedRun
									@RequestID,
									@skipDatasetCheck=0,
									@message=@message OUTPUT,
									@callingUser=@callingUser

				if @myError <> 0
				begin -- <d>
					Set @msg = 'Error deleting Request ID ' + Convert(varchar(12), @RequestID) + ': ' + @message
					RAISERROR (@msg, 11, 5)
				end	-- </d>
				
				Set @CountDeleted = @CountDeleted + 1
			End -- </c>
		End -- </b>
	
		Set @message = 'Deleted ' + Convert(varchar(12), @CountDeleted) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	end -- </a>
		
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
	Set @UsageMessage = 'Updated ' + Convert(varchar(12), @RequestCount) + ' requested run'
	If @RequestCount <> 1
		Set @UsageMessage = @UsageMessage + 's'
	Exec PostUsageLogEntry 'UpdateRequestedRunAssignments', @UsageMessage

	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunAssignments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunAssignments] TO [Limited_Table_Write] AS [dbo]
GO
