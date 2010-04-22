/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateRequestedRunAssignments
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
**	Auth	grk
**	Date	01/26/2003
**			12/11/2003 grk - removed LCMS cart modes
**			07/27/2007 mem - When @mode = 'instrument, then checking dataset type (@datasetTypeName) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #503)
**						   - Added output parameter @message to report the number of items updated
**			09/16/2009 mem - Now checking dataset type (@datasetTypeName) against T_Instrument_Allowed_Dataset_Type (Ticket #748)
**    
*****************************************************/
	@mode varchar(32), -- 'priority', 'instrument', 'delete'
	@newValue varchar(512),
	@reqRunIDList varchar(2048),
	@message varchar(512)='' output
As

	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @msg varchar(512)
	declare @continue int
	declare @RequestID int

	declare @instrumentID int
	declare @instrumentName varchar(128)

	declare @datasetTypeID int
	declare @datasetTypeName varchar(64)
	declare @RequestIDCount int
	declare @RequestIDFirst int

	declare @allowedDatasetTypes varchar(255)
	
	set @message = ''
	
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
	Begin
		Set @msg = 'Error parsing Request ID List'
		RAISERROR (@msg, 10, 1)
		return @myError
	End
	
	If @myRowCount = 0
	Begin
		-- @reqRunIDList was empty; nothing to do
		Set @msg = 'Request ID list was empty; nothing to do'
		RAISERROR (@msg, 10, 1)
		return 51312
	End

	if @mode = 'instrument'
	Begin -- <a>
		Set @instrumentName = @newValue
		
		-- Make sure the Run Type (i.e. Dataset Type) defined for each of the run requests
		-- is appropriate for instrument @instrumentName
		-- 

		---------------------------------------------------
		-- Resolve instrument ID
		---------------------------------------------------

		execute @instrumentID = GetinstrumentID @instrumentName
		if @instrumentID = 0
		begin
			set @msg = 'Could not find entry in database for instrument "' + @instrumentName + '"'
			RAISERROR (@msg, 10, 1)
			return 51313
		end

		---------------------------------------------------
		-- Populate a temporary table with the dataset type names
		-- associated with the requests in #TmpRequestIDs
		---------------------------------------------------
		
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
		--  Dataset Type against T_Instrument_Allowed_Dataset_Type
		
		SELECT @DatasetTypeID = Min(DatasetTypeID)-1
		FROM #TmpDatasetTypeList
		
		Set @continue = 1
		While @continue = 1
		Begin -- <b>
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
			Begin -- <c>
				---------------------------------------------------
				-- Verify that dataset type is valid for given instrument
				---------------------------------------------------				

				If Not Exists (SELECT * FROM T_Instrument_Allowed_Dataset_Type WHERE Instrument = @instrumentName AND Dataset_Type = @DatasetTypeName)
				begin
					Set @allowedDatasetTypes = ''
					
					SELECT @allowedDatasetTypes = @allowedDatasetTypes + ', ' + Dataset_Type
					FROM T_Instrument_Allowed_Dataset_Type 
					WHERE Instrument = @instrumentName
					ORDER BY Dataset_Type

					-- Remove the leading two characters
					If Len(@allowedDatasetTypes) > 0
						Set @allowedDatasetTypes = Substring(@allowedDatasetTypes, 3, Len(@allowedDatasetTypes))

					set @msg = 'Dataset Type "' + @DatasetTypeName + '" is invalid for instrument "' + @instrumentName + '"; valid types are "' + @allowedDatasetTypes + '"'
					If @RequestIDCount > 1
						set @msg = @msg + '; ' + Convert(varchar(12), @RequestIDCount) + ' conflicting Request IDs, starting with ID ' + Convert(varchar(12), @RequestIDFirst)
					Else
						set @msg = @msg + '; conflicting Request ID is ' + Convert(varchar(12), @RequestIDFirst)
					
					RAISERROR (@msg, 10, 1)
					return 51315
				end
	
			End -- </c>
		End -- </b>
	End -- </a>
					

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
	if @mode = 'instrument'
	begin
		UPDATE T_Requested_Run
		SET	RDS_instrument_name = @newValue
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed the instrument to ' + @newValue + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
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
										@message output

				if @myError <> 0
				begin -- <d>
					Set @msg = 'Error deleting Request ID ' + Convert(varchar(12), @RequestID) + ': ' + @message
					RAISERROR (@msg, 10, 1)
					return 51310
				end	-- </d>
				
				Set @CountDeleted = @CountDeleted + 1
			End -- </c>
		End -- </b>
	
		Set @message = 'Deleted ' + Convert(varchar(12), @CountDeleted) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	end -- </a>
	
	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [DMS_RunScheduler] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAssignments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunAssignments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunAssignments] TO [PNL\D3M580] AS [dbo]
GO
