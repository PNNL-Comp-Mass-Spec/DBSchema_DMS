/****** Object:  StoredProcedure [dbo].[AddUpdateDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateDataset
/****************************************************
**
**	Desc:	Adds new dataset entry to DMS database
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	grk
**	Date:	02/13/2003
**			01/10/2002
**			12/10/2003 grk - added wellplate, internal standards, and LC column stuff
**			01/11/2005 grk - added bad dataset stuff
**			02/23/2006 grk - added LC cart tracking stuff and EUS stuff
**			01/12/2007 grk - added verification mode
**			02/16/2007 grk - added validation of dataset name (Ticket #390)
**			04/30/2007 grk - added better name validation (Ticket #450)
**			07/26/2007 mem - Now checking dataset type (@msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**			09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**			10/08/2007 jds - Added support for new mode 'add_trigger'.  Validation was taken from other stored procs from the 'add' mode
**			12/07/2007 mem - Now disallowing updates for datasets with a rating of -10 = Unreviewed (use UpdateDatasetDispositions instead)
**			01/08/2008 mem - Added check for @eusProposalID, @eusUsageType, or @eusUsersList being blank or 'no update' when @Mode = 'add' and @requestID is 0
**			02/13/2008 mem - Now sending @datasetNum to function ValidateChars and checking for @badCh = '[space]' (Ticket #602)
**			02/15/2008 mem - Increased size of @folderName to varchar(128) (Ticket #645)
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUser (Ticket #644)
**			04/09/2008 mem - Added call to AlterEventLogEntryUser to handle dataset rating entries (event log target type 8)
**			05/23/2008 mem - Now calling SchedulePredefinedAnalyses if the dataset rating is changed from -5 to 5 and no jobs exist yet for this dataset (Ticket #675)
**			04/08/2009 jds - Added support for the additional parameters @secSep and @MRMAttachment to the AddUpdateRequestedRun stored procedure (Ticket #727)
**			09/16/2009 mem - Now checking dataset type (@msType) against T_Instrument_Allowed_Dataset_Type (Ticket #748)
**			01/14/2010 grk - assign storage path on creation of dataset
**			02/28/2010 grk - added add-auto mode for requested run
**			03/02/2010 grk - added status field to requested run
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@experimentNum varchar(64),
	@operPRN varchar(64),
	@instrumentName varchar(64),
	@msType varchar(20),
	@LCColumnNum varchar(64),
	@wellplateNum varchar(64) = 'na',
	@wellNum varchar(64) = 'na',
	@secSep varchar(64) = 'na',
	@internalStandards varchar(64) = 'none',
	@comment varchar(512) = 'na',
	@rating varchar(32) = 'Unknown',
	@LCCartName varchar(128),
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@requestID int = 0,
	@mode varchar(12) = 'add', -- or 'update', 'bad', 'check_update', 'check_add', 'add_trigger'
	@message varchar(512) output,
   	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @msg varchar(256)
	declare @folderName varchar(128)

	set @message = ''

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(IsNull(@secSep, '')) < 1
	begin
		set @myError = 51017
		set @msg = 'Separation type was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	if LEN(IsNull(@LCColumnNum, '')) < 1
	begin
		set @myError = 51016
		set @msg = 'LC Column number was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	if LEN(IsNull(@datasetNum, '')) < 1
	begin
		set @myError = 51010
		set @msg = 'Dataset number was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	set @folderName = @datasetNum
	--
	if LEN(IsNull(@experimentNum, '')) < 1
	begin
		set @myError = 51011
		set @msg = 'Experiment number was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	if LEN(IsNull(@folderName, '')) < 1
	begin
		set @myError = 51012
		set @msg = 'Folder name was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	if LEN(IsNull(@operPRN, '')) < 1
	begin
		set @myError = 51013
		set @msg = 'Operator payroll number/HID was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	if LEN(IsNull(@instrumentName, '')) < 1
	begin
		set @myError = 51014
		set @msg = 'Instrument name was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	if LEN(IsNull(@msType, '')) < 1
	begin
		set @myError = 51015
		set @msg = 'Dataset type was blank'
		RAISERROR (@msg, 10, 1)
	end
	--
	if @myError <> 0
		return @myError
		
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

		RAISERROR (@msg, 10, 1)
		return 51001
	end

	if (@datasetNum like '%raw') or (@datasetNum like '%wiff') 
	begin
		set @msg = 'Dataset name may not end in "raw" or "wiff"'
		RAISERROR (@msg, 10, 1)
		return 51002
	end

	---------------------------------------------------
	-- Resolve id for rating
	---------------------------------------------------

	declare @ratingID int

	if @Mode = 'bad'
	begin
		set @ratingID = -1 -- "No Data"
		set @Mode = 'add'
	end
	else
	begin
		execute @ratingID = GetDatasetRatingID @rating
		if @ratingID = 0
		begin
			set @msg = 'Could not find entry in database for rating "' + @rating + '"'
			RAISERROR (@msg, 10, 1)
			return 51018
		end
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
		if (@mode = 'update' or @mode = 'check_update')
		begin
			set @msg = 'Cannot update: Dataset "' + @datasetNum + '" is not in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end
	else
	begin
		-- cannot create an entry that already exists
		--
		if (@mode = 'add' or @mode = 'check_add' or @mode = 'add_trigger')
		begin
			set @msg = 'Cannot add: Dataset "' + @datasetNum + '" already in database '
			RAISERROR (@msg, 10, 1)
			return 51004
		end

		-- do not allow a rating change from 'Unreviewed' to any other rating within this procedure
		--
		if @curDSRatingID = -10 And @rating <> 'Unreviewed'
		begin
			set @msg = 'Cannot change dataset rating from Unreviewed with this mechanism; use the Dataset Disposition process instead ("http://dms.pnl.gov/dms/dataset_disposition_list_report.asp" or SP UpdateDatasetDispositions)'
			RAISERROR (@msg, 10, 1)
			return 51004
		end		
	end

	

	---------------------------------------------------
	-- Resolve ID for LC Column
	---------------------------------------------------
	
	declare @columnID int
	set @columnID = -1
	--
	SELECT @columnID = ID
	FROM T_LC_Column
	WHERE (SC_Column_Number = @LCColumnNum)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up column ID'
		RAISERROR (@msg, 10, 1)
		return 51093
	end
	if @columnID = -1
	begin
		set @msg = 'Could not resolve column number to ID'
		RAISERROR (@msg, 10, 1)
		return 51094
	end

	---------------------------------------------------
	-- Resolve ID for @secSep
	---------------------------------------------------

	declare @sepID int
	set @sepID = 0
	--
	SELECT @sepID = SS_ID
	FROM T_Secondary_Sep
	WHERE SS_name = @secSep	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up separation type ID'
		RAISERROR (@msg, 10, 1)
		return 51098
	end
	if @sepID = 0
	begin
		set @msg = 'Could not resolve separation type to ID'
		RAISERROR (@msg, 10, 1)
		return 51099
	end

	---------------------------------------------------
	-- Resolve ID for @internalStandards
	---------------------------------------------------
	if @internalStandards = ''
		set @internalStandards = 'none'

	declare @intStdID int
	set @intStdID = -1
	--
	SELECT @intStdID = Internal_Std_Mix_ID
	FROM [T_Internal_Standards]
	WHERE [Name] = @internalStandards	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying to look up internal standards ID'
		RAISERROR (@msg, 10, 1)
		return 51095
	end
	if @intStdID = -1
	begin
		set @msg = 'Could not resolve internal standards to ID'
		RAISERROR (@msg, 10, 1)
		return 51096
	end

	---------------------------------------------------
	-- Resolve experiment ID
	---------------------------------------------------

	declare @experimentID int
	execute @experimentID = GetExperimentID @experimentNum
	if @experimentID = 0
	begin
		set @msg = 'Could not find entry in database for experiment "' + @experimentNum + '"'
		RAISERROR (@msg, 10, 1)
		return 51012
	end

	---------------------------------------------------
	-- Resolve dataset type ID
	---------------------------------------------------

	declare @datasetTypeID int
	execute @datasetTypeID = GetDatasetTypeID @msType
	if @datasetTypeID = 0
	begin
		set @msg = 'Could not find entry in database for dataset type'
		RAISERROR (@msg, 10, 1)
		return 51013
	end

	---------------------------------------------------
	-- Resolve instrument ID
	---------------------------------------------------

	declare @instrumentID int
	execute @instrumentID = GetinstrumentID @instrumentName
	if @instrumentID = 0
	begin
		set @msg = 'Could not find entry in database for instrument "' + @instrumentName + '"'
		RAISERROR (@msg, 10, 1)
		return 51014
	end

	---------------------------------------------------
	-- Verify that dataset type is valid for given instrument
	---------------------------------------------------

	declare @allowedDatasetTypes varchar(255)

	If Not Exists (SELECT * FROM T_Instrument_Allowed_Dataset_Type WHERE Instrument = @instrumentName AND Dataset_Type = @msType)
	begin
		Set @allowedDatasetTypes = ''
		
		SELECT @allowedDatasetTypes = @allowedDatasetTypes + ', ' + Dataset_Type
		FROM T_Instrument_Allowed_Dataset_Type 
		WHERE Instrument = @instrumentName
		ORDER BY Dataset_Type

		-- Remove the leading two characters
		If Len(@allowedDatasetTypes) > 0
			Set @allowedDatasetTypes = Substring(@allowedDatasetTypes, 3, Len(@allowedDatasetTypes))
		
		set @msg = 'Dataset Type "' + @msType + '" is invalid for instrument "' + @instrumentName + '"; valid types are "' + @allowedDatasetTypes + '"'
		RAISERROR (@msg, 10, 1)
		return 51014
	end

	---------------------------------------------------
	-- Check for instrument changing when dataset not in new state
	---------------------------------------------------
	--
	if (@mode = 'update' or @mode = 'check_update') and @instrumentID <> @curDSInstID and @curDSStateID <> 1
	begin
		set @msg = 'Cannot change instrument if dataset not in "new" state'
		RAISERROR (@msg, 10, 1)
		return 51023
	end
	
	---------------------------------------------------
	-- Resolve user ID for operator PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @operPRN
	if @userID = 0
	begin
		set @msg = 'Could not find entry in database for operator PRN "' + @operPRN + '"'
		RAISERROR (@msg, 10, 1)
		return 51019
	end

	---------------------------------------------------
	-- assign storage path ID
	---------------------------------------------------
	--
	declare @storagePathID int
	set @storagePathID = 2 -- index of "none" in table
	--
	SELECT
	  @storagePathID = t_storage_path.SP_path_ID
	FROM
	  T_Instrument_Name
	  INNER JOIN t_storage_path ON T_Instrument_Name.IN_storage_path_ID = t_storage_path.SP_path_ID
	WHERE
		T_Instrument_Name.Instrument_ID = @instrumentID
	--
	IF @storagePathID = 2
	begin
		set @msg = 'Valid storage path could not be found'
		RAISERROR (@msg, 10, 1)
		return 51043
	end

	---------------------------------------------------
	-- Verify acceptable combination of EUS fields
	---------------------------------------------------
	
	if (@mode = 'add' or @mode = 'check_add' or @mode = 'add_trigger') AND @requestID <> 0 AND (@eusProposalID <> '' OR @eusUsageType <> '' OR @eusUsersList <> '')
	begin
		set @msg = 'Either a Request must be specified, or EMSL user parameters must be specified, but not both'
		RAISERROR (@msg, 10, 1)
		return 51043
	end

	---------------------------------------------------
	-- action for add trigger mode
	---------------------------------------------------
	if @Mode = 'add_trigger'
	begin -- <AddTrigger>

		--**Check code taken from ConsumeScheduledRun stored procedure**
		---------------------------------------------------
		-- Validate that experiments match
		---------------------------------------------------
	
		-- get experiment ID from dataset
		-- this was already done above

		-- get experiment ID from scheduled run
		--
		declare @reqExperimentID int
		set @reqExperimentID = 0
		--
		SELECT   @reqExperimentID = Exp_ID
		FROM T_Requested_Run
		WHERE ID = @requestID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to look up experiment for request'
			RAISERROR (@message, 10, 1)
			return 51086
		end
	
		-- validate that experiments match
		--
		if @experimentID <> @reqExperimentID and @requestID <> 0
		begin
			set @message = 'Experiment in dataset does not match with one in scheduled run'
			RAISERROR (@message, 10, 1)
			return 51072
		end


		--**Check code taken from UpdateCartParameters stored procedure**
		---------------------------------------------------
		-- Resolve ID for LC Cart and update requested run table
		---------------------------------------------------

		declare @cartID int
		set @cartID = 0
		--
		SELECT @cartID = ID
		FROM T_LC_Cart
		WHERE (Cart_Name = @LCCartName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to look up cart ID'
			RAISERROR (@msg, 10, 1)
			return 52133
		end
		else 
		if @cartID = 0
		begin
			set @msg = 'Could not resolve cart name to ID'
			RAISERROR (@msg, 10, 1)
			return 52135
		end


		if @requestID = 0
		begin -- <b1>
			--**Check code taken from AddUpdateRequestedRun stored procedure**
			---------------------------------------------------
			-- Lookup EUS field (only effective for experiments
			-- that have associated sample prep requests)
			---------------------------------------------------
			exec @myError = LookupEUSFromExperimentSamplePrep	
							@experimentNum,
							@eusUsageType output,
							@eusProposalID output,
							@eusUsersList output,
							@msg output
			if @myError <> 0
			begin
				RAISERROR (@msg, 10, 1)
				return @myError
			end

			---------------------------------------------------
			-- validate EUS type, proposal, and user list
			---------------------------------------------------
			declare @eusUsageTypeID int
			exec @myError = ValidateEUSUsage
							@eusUsageType,
							@eusProposalID output,
							@eusUsersList output,
							@eusUsageTypeID output,
							@msg output
			if @myError <> 0
			begin
				RAISERROR (@msg, 10, 1)
				return @myError
			end
		end -- </b1>
		else
		begin -- <b2>
			--**Check code taken from UpdateCartParameters stored procedure**
			---------------------------------------------------
			-- verify that request ID is correct
			---------------------------------------------------
			declare @tmp int
			set @tmp = 0
			--
			SELECT @tmp = ID
			FROM T_Requested_Run
			WHERE (ID = @requestID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Error trying verify request ID'
				RAISERROR (@msg, 10, 1)
				return @myError
			end
			if @tmp = 0
			begin
				set @msg = 'Request ID not found'
				RAISERROR (@msg, 10, 1)
				return 52131
			end

		end -- </b2>

		declare @DSCreatorPRN varchar(256)
		set @DSCreatorPRN = suser_sname()

		

		declare @rslt int
		declare @Run_Start varchar(10)
		declare @Run_Finish varchar(10)
		set @Run_Start = ''
		set @Run_Finish = ''

		exec @rslt = CreateXmlDatasetTriggerFile
			@datasetNum,
			@experimentNum,
			@instrumentName,
			@secSep,
			@LCCartName,
			@LCColumnNum,
			@wellplateNum,
			@wellNum,
			@msType,
			@operPRN,
			@DSCreatorPRN,
			@comment,
			@rating,
			@requestID,
			@eusUsageType,
			@eusProposalID,
			@eusUsersList,
			@Run_Start,
			@Run_Finish,
			@message output

		if @rslt > 0 
		begin
			set @msg = 'There was an error while creating the XML Trigger file: ' + @message
			RAISERROR (@msg, 10, 1)
			return 51055
		end
	end -- </AddTrigger>

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	
	if @Mode = 'add' 
	begin -- <AddMode>
		-- Start transaction
		--
		declare @transName varchar(32)
		set @transName = 'AddNewDataset'
		begin transaction @transName

		Set @newDSStateID = 1
		
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
				DS_internal_standard_ID
				) 
			VALUES (
				@datasetNum,
				@operPRN,
				@comment,
				getdate(),
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
				@intStdID
				)
 
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert operation failed: "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		set @datasetID = IDENT_CURRENT('T_Dataset')

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
		Begin
			Exec AlterEventLogEntryUser 4, @datasetID, @newDSStateID, @callingUser
			
			Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser
		End
		
		---------------------------------------------------
		-- if scheduled run is not specified, create one
		---------------------------------------------------
		declare @result int

		if @requestID = 0
		begin -- <b3>
			/*
			**
			** The following validation code, added by MEM 1/9/2008, is likely correct, but is commented out for safety
			**
		
			If @eusUsageType = '' or @eusUsageType = 'no update'
			begin
				set @msg = 'You must provide a Usage Type when the Request ID is 0'
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51030
			end


			If @eusUsageType = 'USER'
			Begin
				-- Usage Type is USER
				-- Both @eusProposalID and @eusUsersList must be non-blank
				
				If @eusProposalID = '' or @eusProposalID = 'no update'
				begin
					set @msg = 'You must provide a Proposal ID when the Request ID is 0 and the Usage Type is "USER"'
					RAISERROR (@msg, 10, 1)
					rollback transaction @transName
					return 51031
				end

				If @eusUsersList = '' or @eusUsersList = 'no update'
				begin
					set @msg = 'You must define the EMSL Users when the Request ID is 0 and the Usage Type is "USER"'
					RAISERROR (@msg, 10, 1)
					rollback transaction @transName
					return 51032
				end
			End
			Else
			Begin
				-- Usage Type is not USER
				-- Both @eusProposalID and @eusUsersList must be blank
				
				If @eusProposalID = 'no update' or @eusProposalID = '(lookup)'
					Set @eusProposalID = ''
				
				If @eusUsersList = 'no update' or @eusUsersList = '(lookup)'
					Set @eusUsersList = ''
					
					
				If @eusProposalID <> ''
				begin
					set @msg = 'Proposal ID must be blank when the Request ID is 0 and the Usage Type is not USER'
					RAISERROR (@msg, 10, 1)
					rollback transaction @transName
					return 51033
				end

				If @eusUsersList <> ''
				begin
					set @msg = 'User List must be blank when the Request ID is 0 and the Usage Type is not USER'
					RAISERROR (@msg, 10, 1)
					rollback transaction @transName
					return 51034
				end
			End

			*/

			declare @reqName varchar(128)
			set @reqName = 'AutoReq_' + @datasetNum
			EXEC @result = dbo.AddUpdateRequestedRun 
									@reqName = @reqName,
									@experimentNum = @experimentNum,
									@operPRN = @operPRN,
									@instrumentName = @instrumentName,
									@workPackage = 'none',
									@msType = @msType,
									@instrumentSettings = 'na',
									@wellplateNum = 'na',
									@wellNum = 'na',
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
									@status = 'Completed'
			--
			set @myError = @result
			--
			if @myError <> 0
			begin
				set @msg = 'Create scheduled run failed: "' + @datasetNum + '" with Proposal ID "' + @eusProposalID + '", Usage Type "' + @eusUsageType + '", and Users List "' + @eusUsersList + '" ->' + @message
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51024
			end
		end -- </b3>

		---------------------------------------------------
		-- if a cart name is specified, update it for the 
		-- requested run
		---------------------------------------------------
		if @LCCartName <> '' and @LCCartName <> 'no update'
		begin
			exec @result = UpdateCartParameters
								'CartName',
								@requestID,
								@LCCartName output,
								@message output
			--
			set @myError = @result
			--
			if @myError <> 0
			begin
				set @msg = 'Update cart name update failed: "' + @datasetNum + '"->' + @message
				RAISERROR (@msg, 10, 1)
				rollback transaction @transName
				return 51021
			end
		end
		
		---------------------------------------------------
		-- consume the scheduled run 
		---------------------------------------------------
		set @datasetID = 0
		SELECT 
			@datasetID = Dataset_ID
		FROM T_Dataset 
		WHERE (Dataset_Num = @datasetNum)

		exec @result = ConsumeScheduledRun @datasetID, @requestID, @message output
		--
		set @myError = @result
		--
		if @myError <> 0
		begin
			set @msg = 'Consume operation failed: "' + @datasetNum + '"->' + @message
			RAISERROR (@msg, 10, 1)
			rollback transaction @transName
			return 51016
		end

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
				DS_well_num = @wellNum, 
				DS_sec_sep = @secSep, 
				DS_folder_name = @folderName, 
				Exp_ID = @experimentID,
				DS_rating = @ratingID,
				DS_LC_column_ID = @columnID, 
				DS_wellplate_num = @wellplateNum, 
				DS_internal_standard_ID = @intStdID
		WHERE (Dataset_Num = @datasetNum)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed: "' + @datasetNum + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		
		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0 AND @ratingID <> IsNull(@curDSRatingID, -1000)
			Exec AlterEventLogEntryUser 8, @datasetID, @ratingID, @callingUser
			
		-- If rating changed from -5 to 5, then check if any jobs exist for this dataset
		-- If no jobs are found, then call SchedulePredefinedAnalyses for this dataset
		If @ratingID >= 2 and IsNull(@curDSRatingID, -1000) = -5
		Begin
			If Not Exists (SELECT * FROM T_Analysis_Job WHERE (AJ_datasetID = @datasetID))
			Begin
				Exec SchedulePredefinedAnalyses @datasetNum
				
				-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in 
				--  T_Event_Log for any newly created jobs for this dataset
				If Len(@callingUser) > 0
				Begin
					Declare @JobStateID int
					Set @JobStateID = 1
					
					CREATE TABLE #TmpIDUpdateList (
						TargetID int NOT NULL
					)
					
					INSERT INTO #TmpIDUpdateList (TargetID)
					SELECT AJ_JobID
					FROM T_Analysis_Job
					WHERE (AJ_datasetID = @datasetID)
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount

					Exec AlterEventLogEntryUserMultiID 5, @JobStateID, @callingUser
				End

			End
		End
		
		
	end -- </UpdateMode>

	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataset] TO [PNL\D3M580] AS [dbo]
GO
