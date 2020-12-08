/****** Object:  StoredProcedure [dbo].[AddUpdateTrackingDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateTrackingDataset]
/****************************************************
**
**  Desc:
**    Adds new or edits existing tracking dataset
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	07/03/2012
**			07/19/2012 grk - Extended interval update range around dataset date
**			05/08/2013 mem - Now setting @wellplateNum and @wellNum to Null instead of 'na'
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/13/2017 mem - Rename @operPRN to @requestorPRN when calling AddUpdateRequestedRun
**						   - Use SCOPE_IDENTITY()
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@datasetNum varchar(128) = 'TrackingDataset1',
	@experimentNum varchar(64) = 'Placeholder',
	@operPRN varchar(64) = 'D3J410',
	@instrumentName varchar(64),
	@runStart VARCHAR(32) = '6/1/2012',
	@runDuration VARCHAR(16) = '10',
	@comment varchar(512) = 'na',
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50) = 'CAP_DEV',
	@eusUsersList varchar(1024) = '',
	@mode varchar(12) = 'add',				-- Can be 'add', 'update', 'bad', 'check_update', 'check_add'
	@message varchar(512) output,
   	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	declare @msg varchar(256)
	declare @folderName varchar(128)
	declare @AddingDataset tinyint = 0

	declare @result int
	declare @Warning varchar(256)
	declare @ExperimentCheck varchar(128)

	set @message = ''
	set @Warning = ''

	DECLARE @requestID int = 0				-- Only valid if @mode is 'add', or 'check_add'; ignored if @mode is 'update' or 'check_update'
	DECLARE @wellplateNum varchar(64) = NULL
	DECLARE @wellNum varchar(64) = NULL
	DECLARE @secSep varchar(64) = 'none'
	DECLARE @rating varchar(32) = 'Unknown'

	DECLARE @columnID INT = 0
	DECLARE @intStdID INT = 0
	DECLARE @ratingID INT = 1 -- 'No Interest'

	DECLARE @msType varchar(50) = 'Tracking'

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------

	Declare @authorized tinyint = 0
	Exec @authorized = VerifySPAuthorized 'AddUpdateTrackingDataset', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	BEGIN TRY

	declare @RefDate DATETIME = GETDATE()
	DECLARE @acqStart DATETIME = @runStart
	DECLARE @acqEnd DATETIME = DATEADD(MINUTE, 10, @acqStart) -- default
	IF @runDuration <> '' OR @runDuration < 1
	BEGIN
		SET @acqEnd = DATEADD(MINUTE, CONVERT(INT, @runDuration), @acqStart)
	END

	DECLARE @datasetTypeID INT
	execute @datasetTypeID = GetDatasetTypeID @msType

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if IsNull(@mode, '') = ''
	begin
		set @msg = '@mode was blank'
		RAISERROR (@msg, 11, 17)
	end
	--
	if IsNull(@datasetNum, '') = ''
	begin
		set @msg = 'Dataset name was blank'
		RAISERROR (@msg, 11, 10)
	end
	--
	set @folderName = @datasetNum
	--
	if IsNull(@experimentNum, '') = ''
	begin
		set @msg = 'Experiment name was blank'
		RAISERROR (@msg, 11, 11)
	end
	--
	if IsNull(@folderName, '') = ''
	begin
		set @msg = 'Folder name was blank'
		RAISERROR (@msg, 11, 12)
	end
	--
	if IsNull(@operPRN, '') = ''
	begin
		set @msg = 'Operator payroll number/HID was blank'
		RAISERROR (@msg, 11, 13)
	end
	--
	if IsNull(@instrumentName, '') = ''
	begin
		set @msg = 'Instrument name was blank'
		RAISERROR (@msg, 11, 14)
	end

	-- Assure that @comment is not null and assure that it doesn't have &quot;
	set @comment = IsNull(@comment, '')
	If @comment LIKE '%&quot;%'
		Set @comment = Replace(@comment, '&quot;', '"')

	Set @eusProposalID = IsNull(@eusProposalID, '')
	Set @eusUsageType = IsNull(@eusUsageType, '')
	Set @eusUsersList = IsNull(@eusUsersList, '')

	---------------------------------------------------
	-- Determine if we are adding or check_adding a dataset
	---------------------------------------------------
	If @mode IN ('add', 'check_add')
		Set @AddingDataset = 1
	Else
		SEt @AddingDataset = 0

	---------------------------------------------------
	-- validate dataset name
	---------------------------------------------------

	declare @badCh varchar(128)
	set @badCh =  dbo.ValidateChars(@datasetNum, '')
	if @badCh <> ''
	begin
		If @badCh = '[space]'
			set @msg = 'Dataset name may not contain spaces'
		Else
			set @msg = 'Dataset name may not contain the character(s) "' + @badCh + '"'

		RAISERROR (@msg, 11, 1)
	end

	if (@datasetNum like '%raw') or (@datasetNum like '%wiff')
	begin
		set @msg = 'Dataset name may not end in "raw" or "wiff"'
		RAISERROR (@msg, 11, 2)
	end

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @datasetID int
	declare @curDSTypeID int
	declare @curDSInstID int
	declare @curDSStateID int
	declare @curDSRatingID int
	declare @newDSStateID int

	set @datasetID = 0
	SELECT
		@datasetID = Dataset_ID,
		@curDSInstID = DS_instrument_name_ID,
		@curDSStateID = DS_state_ID,
		@curDSRatingID = DS_Rating
    FROM T_Dataset
	WHERE (Dataset_Num = @datasetNum)

	Set @datasetID = IsNull(@datasetID, 0)

	if @datasetID = 0
	begin
		-- cannot update a non-existent entry
		--
		if @mode IN ('update', 'check_update')
		begin
			set @msg = 'Cannot update: Dataset "' + @datasetNum + '" is not in database '
			RAISERROR (@msg, 11, 4)
		end
	end
	else
	begin
		-- cannot create an entry that already exists
		--
		if @AddingDataset = 1
		begin
			set @msg = 'Cannot add: Dataset "' + @datasetNum + '" since already in database '
			RAISERROR (@msg, 11, 5)
		end
	end

	---------------------------------------------------
	-- Resolve experiment ID
	---------------------------------------------------

	declare @experimentID int
	execute @experimentID = GetExperimentID @experimentNum
	if @experimentID = 0
	begin
		set @msg = 'Could not find entry in database for experiment "' + @experimentNum + '"'
		RAISERROR (@msg, 11, 12)
	end

	---------------------------------------------------
	-- Resolve instrument ID
	---------------------------------------------------

	declare @instrumentID int
	declare @InstrumentGroup varchar(64) = ''
	declare @DefaultDatasetTypeID int

	execute @instrumentID = GetinstrumentID @instrumentName
	if @instrumentID = 0
	begin
		set @msg = 'Could not find entry in database for instrument "' + @instrumentName + '"'
		RAISERROR (@msg, 11, 14)
	end

	---------------------------------------------------
	-- Resolve user ID for operator PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @operPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @operPRN contains simply the username
        --
        SELECT @operPRN = U_PRN
        FROM T_Users
	    WHERE ID = @userID
    End
    Else
    Begin
		-- Could not find entry in database for PRN @operPRN
		-- Try to auto-resolve the name

		Declare @MatchCount int
		Declare @NewPRN varchar(64)

		exec AutoResolveNameToPRN @operPRN, @MatchCount output, @NewPRN output, @userID output

		If @MatchCount = 1
		Begin
			-- Single match found; update @operPRN
			Set @operPRN = @NewPRN
		End
		Else
		Begin
			set @msg = 'Could not find entry in database for operator PRN "' + @operPRN + '"'
			RAISERROR (@msg, 11, 19)
		End
	End

	---------------------------------------------------
	-- Verify acceptable combination of EUS fields
	---------------------------------------------------

	if @requestID <> 0 AND @AddingDataset = 1
	begin
		If (@eusProposalID <> '' OR @eusUsageType <> '' OR @eusUsersList <> '')
		Begin
			If @eusUsageType = '(lookup)' and @eusProposalID = '(lookup)' and @eusUsersList = '(lookup)'
				Set @Warning = ''
			else
				Set @Warning = 'Warning: ignoring proposal ID, usage type, and user list since request "' + Convert(varchar(12), @requestID) + '" was specified'

			-- When a request is specified, force @eusProposalID, @eusUsageType, and @eusUsersList to be blank
			-- Previously, we would raise an error here
			Set @eusProposalID = ''
			Set @eusUsageType = ''
			Set @eusUsersList = ''
		End
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------

	if @Mode = 'add'
	begin -- <AddMode>

		---------------------------------------------------
		-- Lookup storage path ID
		---------------------------------------------------
		--
		declare @storagePathID int

		set @storagePathID = 0
		--
		Exec @storagePathID = GetInstrumentStoragePathForNewDatasets @instrumentID, @RefDate, @AutoSwitchActiveStorage=1, @infoOnly=0
		--
		IF @storagePathID = 0
		begin
			set @storagePathID = 2 -- index of "none" in table
			set @msg = 'Valid storage path could not be found'
			RAISERROR (@msg, 11, 43)
		end


		-- Start transaction
		--
		declare @transName varchar(32)
		set @transName = 'AddNewDataset'
		begin transaction @transName

		Set @newDSStateID = 3

		-- insert values into a new row
		--
		INSERT INTO T_Dataset(
			Dataset_Num,
			DS_Oper_PRN,
			DS_comment,
			DS_created,
			DS_instrument_name_ID,
			DS_type_ID,
			DS_well_num,
			DS_sec_sep,
			DS_state_ID,
			DS_folder_name,
			DS_storage_path_ID,
			Exp_ID,
			DS_rating,
			DS_LC_column_ID,
			DS_wellplate_num,
			DS_internal_standard_ID,
			Acq_Time_Start,
			Acq_Time_End
		) VALUES (
			@datasetNum,
			@operPRN,
			@comment,
			@RefDate,
			@instrumentID,
			@datasetTypeID,
			@wellNum,
			@secSep,
			@newDSStateID,
			@folderName,
			@storagePathID,
			@experimentID,
			@ratingID,
			@columnID,
			@wellplateNum,
			@intStdID,
			@acqStart,
			@acqEnd
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert operation failed: "' + @datasetNum + '"'
			RAISERROR (@msg, 11, 7)
		end

		-- Get the ID of the newly added dataset
		--
		set @datasetID = SCOPE_IDENTITY()

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
		Begin
			Exec AlterEventLogEntryUser 4, @datasetID, @newDSStateID, @callingUser

			Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser
		End


		---------------------------------------------------
		-- if scheduled run is not specified, create one
		---------------------------------------------------

		if @requestID = 0
		begin -- <b3>

			if IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
				Set @warning = @message

			declare @reqName varchar(128)
			set @reqName = 'AutoReq_' + @datasetNum
			EXEC @result = dbo.AddUpdateRequestedRun
									@reqName = @reqName,
									@experimentNum = @experimentNum,
									@requestorPRN = @operPRN,
									@instrumentName = @instrumentName,
									@workPackage = 'none',
									@msType = @msType,
									@instrumentSettings = 'na',
									@wellplateNum = NULL,
									@wellNum = NULL,
									@internalStandard = 'na',
									@comment = 'Automatically created by Dataset entry',
									@eusProposalID = @eusProposalID,
									@eusUsageType = @eusUsageType,
									@eusUsersList = @eusUsersList,
									@mode = 'add-auto',
									@request = @requestID output,
									@message = @message output,
									@secSep = @secSep,
									@MRMAttachment = '',
									@status = 'Completed',
									@SkipTransactionRollback = 1,
									@AutoPopulateUserListIfBlank = 1,		-- Auto populate @eusUsersList if blank since this is an Auto-Request
									@callingUser = @callingUser
			--
			set @myError = @result
			--
			if @myError <> 0
			begin
				set @msg = 'Create AutoReq run request failed: "' + @datasetNum + '" with Proposal ID "' + @eusProposalID + '", Usage Type "' + @eusUsageType + '", and Users List "' + @eusUsersList + '" ->' + @message
				RAISERROR (@msg, 11, 24)
			end
		end -- </b3>

		---------------------------------------------------
		-- consume the scheduled run
		---------------------------------------------------
		set @datasetID = 0
		SELECT
			@datasetID = Dataset_ID
		FROM T_Dataset
		WHERE (Dataset_Num = @datasetNum)

		if IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
				Set @warning = @message

		exec @result = ConsumeScheduledRun @datasetID, @requestID, @message output, @callingUser
		--
		set @myError = @result
		--
		if @myError <> 0
		begin
			set @msg = 'Consume operation failed: "' + @datasetNum + '"->' + @message
			RAISERROR (@msg, 11, 16)
		end
/* ??? */
		commit transaction @transName
	end -- </AddMode>

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update'
	begin -- <UpdateMode>
		set @myError = 0
		--
		UPDATE T_Dataset
		SET
				DS_Oper_PRN = @operPRN,
				DS_comment = @comment,
				DS_instrument_name_ID = @instrumentID,
				DS_type_ID = @datasetTypeID,
				DS_folder_name = @folderName,
				Exp_ID = @experimentID,
				Acq_Time_Start = @acqStart,
				Acq_Time_End = @acqEnd
		WHERE (Dataset_Num = @datasetNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @datasetNum + '"'
			RAISERROR (@msg, 11, 4)
		end

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0 AND @ratingID <> IsNull(@curDSRatingID, -1000)
			Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser

	end -- </UpdateMode>


	-- Update @message if @warning is not empty
	If IsNull(@Warning, '') <> ''
	Begin
		If IsNull(@message, '') = ''
			Set @message = @Warning
		Else
			If @message <> @warning
				Set @message = @warning + '; ' + @message
	End

	---------------------------------------------------
	-- update interval table
	---------------------------------------------------
	DECLARE @nd DATETIME = DATEADD(MONTH, 1, @RefDate)
	DECLARE @st DATETIME = DATEADD(MONTH, -1, @RefDate)
	EXEC UpdateDatasetInterval @instrumentName, @st, @nd, @message OUTPUT, 0

	END TRY
	BEGIN CATCH
		EXEC FormatErrorMessage @message output, @myError output

		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		Exec PostLogEntry 'Error', @message, 'AddUpdateTrackingDataset'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateTrackingDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateTrackingDataset] TO [DMS2_SP_User] AS [dbo]
GO
