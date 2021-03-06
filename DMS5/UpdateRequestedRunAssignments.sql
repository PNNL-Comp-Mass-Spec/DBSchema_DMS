/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunAssignments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateRequestedRunAssignments]
/****************************************************
**
**	Desc:
**      Update the specified requested runs to change priority, instrument group, separation group, dataset type, or assigned instrument
**
**      This procedure is called via two mechanisms:
**      1) Via POST calls to requested_run/operation/ , originating from https://dms2.pnl.gov/requested_run_admin/report
**         - See file requested_run_admin_cmds.php at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/master/application/views/cmd/requested_run_admin_cmds.php
**           and file lcmd.js at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/d2eab881133cfe4c71f17b06b09f52fc4e61c8fb/javascript/lcmd.js#L225
**      2) When the user clicks "Delete this request" or "Convert Request Into Fractions" at the bottom of a Requested Run Detail report
**         - See the detail_report_commands and sproc_args sections at https://dms2.pnl.gov/config_db/show_db/requested_run.db
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
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			05/31/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**			06/13/2017 mem - Do not log an error when a requested run cannot be deleted because it is associated with a dataset
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**          07/01/2019 mem - Change argument @reqRunIDList from varchar(2048) to varchar(max)
**			10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**			10/20/2020 mem - Rename mode 'instrument' to 'instrumentGroup'
**                         - Rename mode 'instrumentIgnoreType' to 'instrumentGroupIgnoreType'
**                         - Add mode 'assignedInstrument'
**          02/04/2021 mem - Provide a delimiter when calling GetInstrumentGroupDatasetTypeList
**    
*****************************************************/
(
	@mode varchar(32),                  -- 'priority', 'instrumentGroup', 'instrumentGroupIgnoreType', 'assignedInstrument', 'datasetType', 'delete', 'separationGroup'
	@newValue varchar(512),
	@reqRunIDList varchar(max),         -- Comma separated list of requested run IDs
	@message varchar(512)='' output,
	@callingUser varchar(128) = ''
)
As

	Set XACT_ABORT, nocount on
	
	Declare @myError int = 0
	Declare @myRowCount int = 0

	Declare @msg varchar(512)
	Declare @continue int
	Declare @requestID int

	Declare @newInstrumentGroup varchar(64) = ''
	Declare @newSeparationGroup varchar(64) = ''

    Declare @newAssignedInstrumentID int = 0;
    Declare @newQueueState int = 0

	Declare @newDatasetType varchar(64) = ''
	Declare @newDatasetTypeID int = 0
	
	Declare @datasetTypeID int
	Declare @datasetTypeName varchar(64)
	
	Declare @requestIDCount int
	Declare @requestIDFirst int

	Declare @allowedDatasetTypes varchar(255) = ''
	Declare @requestCount int = 0

	Declare @logErrors tinyint = 0

	Set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateRequestedRunAssignments', @raiseError = 1
	If @authorized = 0
	Begin;
		THROW 51000, 'Access denied', 1;
	End;

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
    Begin
		-- @reqRunIDList was empty; nothing to do
		RAISERROR ('Request ID list was empty; nothing to do', 11, 2)
    End

	Set @requestCount = @myRowCount

	-- Initial validation checks are complete; now enable @logErrors	
	Set @logErrors = 1

	If @mode IN ('instrumentGroup', 'instrumentGroupIgnoreType')
	Begin -- <a>
		
		---------------------------------------------------
		-- Validate the instrument group
		-- Note that as of 6/26/2013 mode 'instrument' does not appear to be used by the DMS website
        -- This unused mode was renamed to 'instrumentGroup' in October 2020
		-- Mode 'instrumentGroupIgnoreType' is used by http://dms2.pnl.gov/requested_run_admin/report
		---------------------------------------------------
		--
		-- Set the instrument group to @newValue for now
		Set @newInstrumentGroup = @newValue
		
		IF NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @newInstrumentGroup)
		Begin
			-- Try to update instrument group using T_Instrument_Name
			SELECT @newInstrumentGroup = IN_Group
			FROM T_Instrument_Name
			WHERE IN_Name = @newValue
		End
				
		---------------------------------------------------
		-- Make sure a valid instrument group was chosen (or auto-selected via an instrument name)
		-- This also assures the text is properly capitalized
		---------------------------------------------------

		SELECT @newInstrumentGroup = IN_Group
		FROM T_Instrument_Group
		WHERE IN_Group = @newInstrumentGroup
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
		Begin
			Set @logErrors = 0
			RAISERROR ('Could not find entry in database for instrument group (or instrument) "%s"', 11, 3, @newValue)
		End
		
		If @mode = 'instrumentGroup'
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
			
			SELECT @datasetTypeID = Min(DatasetTypeID)-1
			FROM #TmpDatasetTypeList
			
			Set @continue = 1
			While @continue = 1
			Begin -- <c>
				SELECT TOP 1 @datasetTypeID = DatasetTypeID,
							 @datasetTypeName = DatasetTypeName,
							 @requestIDCount = RequestIDCount,
							 @requestIDFirst = RequestIDFirst						 
				FROM #TmpDatasetTypeList
				WHERE DatasetTypeID > @datasetTypeID
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

					If Not Exists (SELECT * FROM T_Instrument_Group_Allowed_DS_Type WHERE IN_Group = @newInstrumentGroup AND Dataset_Type = @datasetTypeName)
					Begin
						SELECT @allowedDatasetTypes = dbo.GetInstrumentGroupDatasetTypeList(@newInstrumentGroup, ', ')

						Set @msg = 'Dataset Type "' + @datasetTypeName + '" is invalid for instrument group "' + @newInstrumentGroup + '"; valid types are "' + @allowedDatasetTypes + '"'
						If @requestIDCount > 1
							Set @msg = @msg + '; ' + Convert(varchar(12), @requestIDCount) + ' conflicting Request IDs, starting with ID ' + Convert(varchar(12), @requestIDFirst)
						Else
							Set @msg = @msg + '; conflicting Request ID is ' + Convert(varchar(12), @requestIDFirst)
						
						Set @logErrors = 0
						RAISERROR (@msg, 11, 4)
					End
		
				End -- </d>
			End -- </c>
		End -- </b>
	End -- </a>

    
	If @mode IN ('assignedInstrument')
	Begin
        If ISNULL(@newValue, '') = ''
        Begin
            -- Unassign the instrument
            Set @newQueueState = 1
        End
        Else
        Begin
		    ---------------------------------------------------
		    -- Determine the Instrument ID of the selected instrument
		    ---------------------------------------------------
		    --
		    SELECT @newAssignedInstrumentID = Instrument_ID
		    FROM T_Instrument_Name
		    WHERE IN_Name = @newValue
		    --	
		    SELECT @myError = @@error, @myRowCount = @@rowcount

		    If @myRowCount = 0
		    Begin
			    Set @logErrors = 0
			    RAISERROR ('Could not find entry in database for instrument "%s"', 11, 3, @newValue)
		    End

            Set @newQueueState = 2
        End
    End

	If @mode IN ('separationGroup')
	Begin
		
		---------------------------------------------------
		-- Validate the separation group
		-- Mode 'separationGroup' is used by http://dms2.pnl.gov/requested_run_admin/report
		---------------------------------------------------
		--
		-- Set the separation group to @newValue for now
		Set @newSeparationGroup = @newValue
		
		IF NOT EXISTS (SELECT * FROM T_Separation_Group WHERE Sep_Group = @newSeparationGroup)
		Begin
			-- Try to update Separation group using T_Secondary_Sep
			SELECT @newSeparationGroup = Sep_Group
			FROM T_Secondary_Sep
			WHERE SS_name = @newValue
		End
				
		---------------------------------------------------
		-- Make sure a valid separation group was chosen (or auto-selected via a separation name)
		-- This also assures the text is properly capitalized
		---------------------------------------------------

		SELECT @newSeparationGroup = Sep_Group
		FROM T_Separation_Group
		WHERE Sep_Group = @newSeparationGroup
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
		Begin
			Set @logErrors = 0
			RAISERROR ('Could not find entry in database for separation group "%s"', 11, 3, @newValue)
		End
		
	End


	If @mode IN ('datasetType')
	Begin
		
		---------------------------------------------------
		-- Validate the dataset type
		-- Mode 'datasetType' is used by http://dms2.pnl.gov/requested_run_admin/report
		---------------------------------------------------
		--
		-- Set the dataset type to @newValue for now
		Set @newDatasetType = @newValue
				
		---------------------------------------------------
		-- Make sure a valid dataset type was chosen
		---------------------------------------------------

		SELECT @newDatasetType = DST_name, 
		       @newDatasetTypeID = DST_Type_ID
		FROM T_DatasetTypeName
		WHERE (DST_name = @newDatasetType)
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @myRowCount = 0
		Begin
			Set @logErrors = 0
			RAISERROR ('Could not find entry in database for dataset type "%s"', 11, 3, @newValue)
		End
		
	End 

	-------------------------------------------------
	-- Apply the changes, as defined by @mode
	-------------------------------------------------
	
	If @mode = 'priority'
	Begin
		-- get priority numerical value
		--
		Declare @pri int
		Set @pri = cast(@newValue as int)
		
		-- If priority is being set to non-zero, clear note field also
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
	End

	-------------------------------------------------
	If @mode IN ('instrumentGroup', 'instrumentGroupIgnoreType')
	Begin
		
		UPDATE T_Requested_Run
		SET	RDS_instrument_group = @newInstrumentGroup
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed the instrument group to ' + @newInstrumentGroup + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	End

    ------------------------------------------------
	If @mode IN ('assignedInstrument')
	Begin		
		UPDATE T_Requested_Run
		SET	Queue_Instrument_ID = CASE WHEN @newQueueState > 1 THEN @newAssignedInstrumentID ELSE Queue_Instrument_ID END, 
            Queue_State = @newQueueState,
            Queue_Date = CASE WHEN @newQueueState > 1 THEN GetDate() ELSE Queue_Date END
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
        WHERE RR.RDS_Status = 'Active'
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
        If @myRowCount = 0
        Begin
            Set @message = 'Can only update the assigned instrument for Active requested runs; all of the selected items are Completed or Inactive'
        End
        Else
        Begin
		    Set @message = 'Changed the assigned instrument to ' + @newValue + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		    If @myRowcount > 1
			    Set @message = @message + 's'

            SELECT @myRowCount = COUNT(*)
            FROM T_Requested_Run RR INNER JOIN
			     #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
            WHERE RR.RDS_Status <> 'Active'

            If @myRowCount > 0
            Begin
                Set @message = @message + '; skipped ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.CheckPlural(@myRowCount, 'request', 'requests') + ' since not Active'
            End
        End
	End

	-------------------------------------------------
	If @mode IN ('separationGroup')
	Begin
		
		UPDATE T_Requested_Run
		SET	RDS_Sec_Sep = @newSeparationGroup
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed the separation group to ' + @newSeparationGroup + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	End

	-------------------------------------------------
	If @mode = 'datasetType'
	Begin
		
		UPDATE T_Requested_Run
		SET	RDS_type_ID = @newDatasetTypeID
		FROM T_Requested_Run RR INNER JOIN
			 #TmpRequestIDs ON RR.ID = #TmpRequestIDs.RequestID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Changed the dataset type to ' + @newDatasetType + ' for ' + Convert(varchar(12), @myRowCount) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	End
	
	-------------------------------------------------
	If @mode = 'delete'
	Begin -- <a>
		-- Step through the entries in #TmpRequestIDs and delete each
		SELECT @requestID = Min(RequestID)-1
		FROM #TmpRequestIDs
		
		Declare @countDeleted int = 0
		
		Set @continue = 1
		While @continue = 1
		Begin -- <b>
			SELECT TOP 1 @requestID = RequestID
			FROM #TmpRequestIDs
			WHERE RequestID > @requestID
			ORDER BY RequestID
			--	
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount = 0
				Set @continue = 0
			Else
			Begin -- <c>
				exec @myError = DeleteRequestedRun
									@requestID,
									@skipDatasetCheck=0,
									@message=@message OUTPUT,
									@callingUser=@callingUser

				If @myError <> 0
				Begin -- <d>
					If @message Like '%associated with dataset%'
					Begin
						-- Message is of the form
						-- Error deleting Request ID 123456: Cannot delete requested run 123456 because it is associated with dataset xyz 
						Set @logErrors = 0
					End
					
					Set @msg = 'Error deleting Request ID ' + Convert(varchar(12), @requestID) + ': ' + @message
					RAISERROR (@msg, 11, 5)
					
					Set @logErrors = 1
				End	-- </d>
				
				Set @countDeleted = @countDeleted + 1
			End -- </c>
		End -- </b>
	
		Set @message = 'Deleted ' + Convert(varchar(12), @countDeleted) + ' requested run'
		If @myRowcount > 1
			Set @message = @message + 's'
	End -- </a>
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	
		If @logErrors > 0
		Begin
			Declare @logMessage varchar(1024) = @message + '; Requests '
			If Len(@reqRunIDList) < 128
				Set @logMessage = @logMessage + @reqRunIDList
			Else
				Set @logMessage = @logMessage + Substring(@reqRunIDList, 1, 128) + ' ...'
				
			exec PostLogEntry 'Error', @logMessage, 'UpdateRequestedRunAssignments'
		End

	END CATCH

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @usageMessage varchar(512)
	Set @usageMessage = 'Updated ' + Convert(varchar(12), @requestCount) + ' requested run'
	If @requestCount <> 1
		Set @usageMessage = @usageMessage + 's'
	Exec PostUsageLogEntry 'UpdateRequestedRunAssignments', @usageMessage

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
