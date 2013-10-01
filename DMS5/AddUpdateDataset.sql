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
**			09/16/2009 mem - Now checking dataset type (@msType) against the Instrument_Allowed_Dataset_Type table (Ticket #748)
**			01/14/2010 grk - assign storage path on creation of dataset
**			02/28/2010 grk - added add-auto mode for requested run
**			03/02/2010 grk - added status field to requested run
**			05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @operPRN contains a person's real name rather than their username
**			07/27/2010 grk - try-catch for error handling
**			08/26/2010 mem - Now passing @callingUser to SchedulePredefinedAnalyses
**			08/27/2010 mem - Now calling ValidateInstrumentGroupAndDatasetType to validate the instrument type for the selected instrument's instrument group
**			09/01/2010 mem - Now passing @SkipTransactionRollback to AddUpdateRequestedRun
**			09/02/2010 mem - Now allowing @msType to be blank or invalid when @mode = 'add'; The assumption is that the dataset type will be auto-updated if needed based on the results from the DatasetQuality tool, which runs during dataset capture
**						   - Expanded @msType to varchar(50)
**			09/09/2010 mem - Now passing @AutoPopulateUserListIfBlank to AddUpdateRequestedRun
**						   - Relaxed EUS validation to ignore @eusProposalID, @eusUsageType, and @eusUsersList if @requestID is non-zero
**						   - Auto-updating RequestID, experiment, and EUS information for "Blank" datasets
**			03/10/2011 mem - Tweaked text added to dataset comment when dataset type is auto-updated or auto-defined
**			05/11/2011 mem - Now calling GetInstrumentStoragePathForNewDatasets
**			05/12/2011 mem - Now passing @RefDate and @AutoSwitchActiveStorage to GetInstrumentStoragePathForNewDatasets
**			05/24/2011 mem - Now checking for change of rating from -5, -6, or -7 to 5
**						   - Now ignoring AJ_DatasetUnreviewed jobs when determining whether or not to call SchedulePredefinedAnalyses
**			12/12/2011 mem - Updated call to ValidateEUSUsage to treat @eusUsageType as an input/output parameter
**			12/14/2011 mem - Now passing @callingUser to AddUpdateRequestedRun and ConsumeScheduledRun
**			12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**			01/11/2012 mem - Added parameter @AggregationJobDataset
**			02/29/2012 mem - Now auto-updating the @eus parameters if null
**			               - Now raising an error if other key parameters are null/empty
**			09/12/2012 mem - Now auto-changing HMS-HMSn to IMS-HMS-HMSn for IMS datasets
**						   - Now requiring that the dataset name be 90 characters or less (longer names can lead to "path-too-long" errors; Windows has a 254 character path limit)
**			11/21/2012 mem - Now requiring that the dataset name be at least 6 characters in length
**			01/22/2013 mem - Now updating the dataset comment if the default dataset type is invalid for the instrument group
**			04/02/2013 mem - Now updating @LCCartName (if not blank) when updating an existing dataset
**			05/08/2013 mem - Now setting @wellplateNum and @wellNum to Null if they are blank or 'na'
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@experimentNum varchar(64),
	@operPRN varchar(64),
	@instrumentName varchar(64),
	@msType varchar(50),
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
	@requestID int = 0,						-- Only valid if @mode is 'add', 'check_add', or 'add_trigger'; ignored if @mode is 'update' or 'check_update'
	@mode varchar(12) = 'add',				-- Can be 'add', 'update', 'bad', 'check_update', 'check_add', 'add_trigger'
	@message varchar(512) output,
   	@callingUser varchar(128) = '',
   	@AggregationJobDataset tinyint = 0			-- Set to 1 when creating an in-silico dataset to associate with an aggregation job
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @msg varchar(256)
	declare @folderName varchar(128)
	declare @AddingDataset tinyint = 0
	
	declare @result int
	declare @Warning varchar(256)
	declare @WarningAddon varchar(128)
	declare @ExperimentCheck varchar(128)
	
	set @message = ''
	set @Warning = ''

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------
	Set @internalStandards = IsNull(@internalStandards, '')
	if @internalStandards = '' Or @internalStandards = 'na'
		set @internalStandards = 'none'
	
	if IsNull(@mode, '') = ''
	begin
		set @msg = '@mode was blank'
		RAISERROR (@msg, 11, 17)
	end
		
	if IsNull(@secSep, '') = ''
	begin
		set @msg = 'Separation type was blank'
		RAISERROR (@msg, 11, 17)
	end
	--
	if IsNull(@LCColumnNum, '') = ''
	begin
		set @msg = 'LC Column name was blank'
		RAISERROR (@msg, 11, 16)
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
	--
	set @msType = IsNull(@msType, '')
	
	-- Allow @msType to be blank if @mode is Add or Bad but not if check_add or add_trigger or update
	if @msType = '' And NOT @mode In ('Add', 'Bad')
	begin
		set @msg = 'Dataset type was blank'
		RAISERROR (@msg, 11, 15)
	end
	--
	if IsNull(@LCCartName, '') = ''
	begin
		set @msg = 'LC Cart name was blank'
		RAISERROR (@msg, 11, 15)
	end

	-- Assure that @comment is not null and assure that it doesn't have &quot;
	set @comment = IsNull(@comment, '')
	If @comment LIKE '%&quot;%'
		Set @comment = Replace(@comment, '&quot;', '"')
	
	-- 
	If IsNull(@rating, '') = ''
	begin
		set @msg = 'Rating was blank'
		RAISERROR (@msg, 11, 15)
	end
	
	If IsNull(@wellplateNum, '') IN ('', 'na')
		set @wellplateNum = NULL
	
	If IsNull(@wellNum, '') IN ('', 'na')
		set @wellNum = NULL

	Set @eusProposalID = IsNull(@eusProposalID, '')
	Set @eusUsageType = IsNull(@eusUsageType, '')
	Set @eusUsersList = IsNull(@eusUsersList, '')
	
	Set @requestID = IsNull(@requestID, 0)
	
	---------------------------------------------------
	-- Determine if we are adding or check_adding a dataset
	---------------------------------------------------
	If @mode IN ('add', 'check_add', 'add_trigger')
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

	If Len(@datasetNum) > 90
	begin
		set @msg = 'Dataset name cannot be over 90 characters in length; currently ' + Convert(varchar(12), Len(@datasetNum)) + ' characters'
		RAISERROR (@msg, 11, 3)
	end
	
	If Len(@datasetNum) < 6
	begin
		set @msg = 'Dataset name must be at least 6 characters in length; currently ' + Convert(varchar(12), Len(@datasetNum)) + ' characters'
		RAISERROR (@msg, 11, 3)
	end
	
	---------------------------------------------------
	-- Resolve id for rating
	---------------------------------------------------

	declare @ratingID int

	if @Mode = 'bad'
	begin
		set @ratingID = -1 -- "No Data"
		set @Mode = 'add'
		set @AddingDataset = 1
	end
	else
	begin
		execute @ratingID = GetDatasetRatingID @rating
		if @ratingID = 0
		begin
			set @msg = 'Could not find entry in database for rating "' + @rating + '"'
			RAISERROR (@msg, 11, 18)
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

		-- do not allow a rating change from 'Unreviewed' to any other rating within this procedure
		--
		if @curDSRatingID = -10 And @rating <> 'Unreviewed'
		begin
			set @msg = 'Cannot change dataset rating from Unreviewed with this mechanism; use the Dataset Disposition process instead ("http://dms2.pnl.gov/dataset_disposition/report" or SP UpdateDatasetDispositions)'
			RAISERROR (@msg, 11, 6)
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
		RAISERROR (@msg, 11, 93)
	end
	if @columnID = -1
	begin
		set @msg = 'Could not resolve column number to ID'
		RAISERROR (@msg, 11, 94)
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
		RAISERROR (@msg, 11, 98)
	end
	if @sepID = 0
	begin
		set @msg = 'Could not resolve separation type to ID'
		RAISERROR (@msg, 11, 99)
	end

	---------------------------------------------------
	-- Resolve ID for @internalStandards
	---------------------------------------------------

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
		RAISERROR (@msg, 11, 95)
	end
	if @intStdID = -1
	begin
		set @msg = 'Could not resolve internal standards to ID'
		RAISERROR (@msg, 11, 96)
	end


	---------------------------------------------------
	-- If Dataset starts with "Blank", then make sure @experimentNum contains "Blank"
	---------------------------------------------------
	If @datasetNum Like 'Blank%' And @AddingDataset = 1
	Begin
		If NOT @ExperimentNum LIKE '%blank%'
			Set @ExperimentNum = 'blank'		
	End
	
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
	declare @msTypeOld varchar(50)
	
	execute @instrumentID = GetinstrumentID @instrumentName
	if @instrumentID = 0
	begin
		set @msg = 'Could not find entry in database for instrument "' + @instrumentName + '"'
		RAISERROR (@msg, 11, 14)
	end

	---------------------------------------------------
	-- Lookup the Instrument Group
	---------------------------------------------------
		
	SELECT @InstrumentGroup = IN_Group
	FROM T_Instrument_Name
	WHERE Instrument_ID = @instrumentID

	if @InstrumentGroup = ''
	begin
		set @msg = 'Instrument group not defined for instrument "' + @instrumentName + '"'
		RAISERROR (@msg, 11, 14)
	end

	---------------------------------------------------
	-- Lookup the default dataset type ID (could be null)
	---------------------------------------------------
		
	SELECT @DefaultDatasetTypeID = Default_Dataset_Type
	FROM T_Instrument_Group
	WHERE IN_Group = @InstrumentGroup

	
	---------------------------------------------------
	-- Resolve dataset type ID
	---------------------------------------------------

	declare @datasetTypeID int
	execute @datasetTypeID = GetDatasetTypeID @msType
	
	if @datasetTypeID = 0
	begin
		-- Could not resolve @msType to a dataset type
		-- If @mode is Add, we will auto-update @msType to the default
		--
		If @AddingDataset = 1 And IsNull(@DefaultDatasetTypeID, 0) > 0
		Begin
			-- Use the default dataset type
			Set @datasetTypeID = @DefaultDatasetTypeID
			
			Set @msTypeOld = @msType
			
			-- Update @msType			
			SELECT @msType = DST_name
			FROM T_DatasetTypeName
			WHERE (DST_Type_ID = @datasetTypeID)

			If @comment = 'na'
				Set @comment = ''
			
			If @msTypeOld <> ''
			Begin
				-- Update the comment since we changed the dataset type from @msTypeOld to @msType
				If @comment <> ''
					Set @comment = @comment + '; '
				
				Set @comment = @comment + 'Auto-switched invalid dataset type from ' + @msTypeOld + ' to default: ' + @msType
			End
			Else
			Begin
				-- @msTypeOld was blank
				-- Update the comment only if this is not an IMS dataset
				If Not @instrumentName Like 'IMS%'
				Begin
					If @comment <> ''
						Set @comment = @comment + '; '
					
					Set @comment = @comment + 'Auto-defined dataset type using default: ' + @msType
				End
			End						
		End
		Else
		Begin
			set @msg = 'Could not find entry in database for dataset type'
			RAISERROR (@msg, 11, 13)
		End
	end


	---------------------------------------------------
	-- Verify that dataset type is valid for given instrument group
	---------------------------------------------------

	declare @allowedDatasetTypes varchar(255)
		
	exec @result = ValidateInstrumentGroupAndDatasetType @msType, @InstrumentGroup, @datasetTypeID output, @msg output

	If @result <> 0 And @AddingDataset = 1 And IsNull(@DefaultDatasetTypeID, 0) > 0
	Begin
		-- Dataset type is not valid for this instrument group
		-- However, @mode is Add, so we will auto-update @msType
		--
		If @comment = 'na'
			Set @comment = ''
		
		If @comment <> ''
			Set @comment = @comment + '; '
		
		If @msType IN ('HMS-MSn', 'HMS-HMSn') And Exists (SELECT IGADST.Dataset_Type 
		                                                  FROM T_Instrument_Group ING INNER JOIN 
		                                                       T_Instrument_Name InstName ON ING.IN_Group = InstName.IN_Group INNER JOIN
                                                               T_Instrument_Group_Allowed_DS_Type IGADST ON ING.IN_Group = IGADST.IN_Group
                                                          WHERE InstName.IN_Name = @instrumentName AND IGADST.Dataset_Type = 'IMS-HMS-HMSn')
        Begin
			-- This is an IMS MS/MS dataset
			Set @msType = 'IMS-HMS-HMSn'
			execute @datasetTypeID = GetDatasetTypeID @msType
			
			Set @comment = @comment + 'Auto-switched dataset type from HMS-HMSn to ' + @msType
        End
        Else
        Begin
			-- Not an IMS dataset; change @datasetTypeID to zero so that the default dataset type is used
			Set @datasetTypeID = 0
		End
		
		If @datasetTypeID = 0
		Begin
			Set @datasetTypeID = @DefaultDatasetTypeID	

			Set @msTypeOld = @msType
			
			-- Update @msType			
			SELECT @msType = DST_name
			FROM T_DatasetTypeName
			WHERE (DST_Type_ID = @datasetTypeID)
			
			Set @comment = @comment + 'Auto-switched invalid dataset type from ' + @msTypeOld + ' to default: ' + @msType
		End
		
		-- Validate the new dataset type name (in case the default dataset type is invalid for this instrument group, which would indicate invalid data in table T_Instrument_Group)
		exec @result = ValidateInstrumentGroupAndDatasetType @msType, @InstrumentGroup, @datasetTypeID output, @msg output
		
		If @result <> 0
		Begin
			Set @comment = @comment + ' - Error: Default dataset type defined in T_Instrument_Group is invalid'
		End
	End
	
	if @result <> 0
	Begin
		-- @msg should already contain the details of the error
		If IsNull(@msg, '') = ''
			Set @msg = 'ValidateInstrumentGroupAndDatasetType returned non-zero result code: ' + Convert(varchar(12), @result)
		
		RAISERROR (@msg, 11, 15)
	End

	---------------------------------------------------
	-- Check for instrument changing when dataset not in new state
	---------------------------------------------------
	--
	if @mode IN ('update', 'check_update') and @instrumentID <> @curDSInstID and @curDSStateID <> 1
	begin
		set @msg = 'Cannot change instrument if dataset not in "new" state'
		RAISERROR (@msg, 11, 23)
	end
	
	---------------------------------------------------
	-- Resolve user ID for operator PRN
	---------------------------------------------------

	declare @userID int
	execute @userID = GetUserID @operPRN
	if @userID = 0
	begin
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
	end

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
				
		---------------------------------------------------
		-- If the dataset starts with "blank" but @requestID is non-zero, then this is likely incorrect
		-- Auto-update things if this is the case
		---------------------------------------------------
		If @datasetNum Like 'Blank%'
		Begin
			-- See if the experiment matches for this request; if it doesn't, change @requestID to 0
			Set @ExperimentCheck = ''
			
			SELECT @ExperimentCheck = E.Experiment_Num
			FROM T_Experiments E INNER JOIN
				T_Requested_Run RR ON E.Exp_ID = RR.Exp_ID
			WHERE (RR.ID = @requestID)
			
			If @ExperimentCheck <> @ExperimentNum
				Set @RequestID = 0
		End
	end


	---------------------------------------------------
	-- If the dataset starts with "blank" and @requestID is zero, perform some additional checks
	---------------------------------------------------
	If @requestID = 0 AND @AddingDataset = 1
	Begin
		-- If the EUS information is not defined, auto-define the EUS usage type as 'MAINTENANCE'
		If @datasetNum Like 'Blank%' And @eusProposalID = '' And @eusUsageType = ''
			set @eusUsageType = 'MAINTENANCE'
	End

		
	---------------------------------------------------
	-- action for add trigger mode
	---------------------------------------------------
	if @Mode = 'add_trigger'
	begin -- <AddTrigger>

		If @requestID <> 0
		Begin
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
			SELECT @reqExperimentID = Exp_ID
			FROM T_Requested_Run
			WHERE ID = @requestID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to look up experiment for request'
				RAISERROR (@message, 11, 86)
			end
		
			-- validate that experiments match
			--
			if @experimentID <> @reqExperimentID
			begin
				set @message = 'Experiment in dataset (' + @experimentNum + ') does not match with one in scheduled run (Request ' + Convert(varchar(12), @requestID) + ')'
				RAISERROR (@message, 11, 72)
			end
		End

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
			RAISERROR (@msg, 11, 33)
		end
		else 
		if @cartID = 0
		begin
			set @msg = 'Could not resolve cart name to ID'
			RAISERROR (@msg, 11, 35)
		end


		if @requestID = 0
		begin -- <b1>
		
			-- RequestID not specified
			-- Try to determine EUS information using Experiment name
			
			--**Check code taken from AddUpdateRequestedRun stored procedure**
			
			---------------------------------------------------
			-- Lookup EUS field (only effective for experiments that have associated sample prep requests)
			-- This will update the data in @eusUsageType, @eusProposalID, or @eusUsersList if it is "(lookup)"
			---------------------------------------------------
			exec @myError = LookupEUSFromExperimentSamplePrep	
							@experimentNum,
							@eusUsageType output,
							@eusProposalID output,
							@eusUsersList output,
							@msg output
							
			if @myError <> 0
				RAISERROR ('LookupEUSFromExperimentSamplePrep: %s', 11, 1, @msg)

			---------------------------------------------------
			-- validate EUS type, proposal, and user list
			---------------------------------------------------
			declare @eusUsageTypeID int
			exec @myError = ValidateEUSUsage
							@eusUsageType output,
							@eusProposalID output,
							@eusUsersList output,
							@eusUsageTypeID output,
							@msg output,
							@AutoPopulateUserListIfBlank = 0
							
			if @myError <> 0
				RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)
			
			If IsNull(@msg, '') <> ''
				Set @message = @msg
				
		end -- </b1>
		else
		begin -- <b2>
			
			---------------------------------------------------
			-- verify that request ID is correct
			---------------------------------------------------
			
			IF NOT EXISTS (SELECT * FROM T_Requested_Run WHERE ID = @requestID)
			begin
				set @msg = 'Request ID not found'
				RAISERROR (@msg, 11, 52)
			end

		end -- </b2>

		declare @DSCreatorPRN varchar(256)
		set @DSCreatorPRN = suser_sname()

		declare @rslt int
		declare @Run_Start varchar(10)
		declare @Run_Finish varchar(10)
		set @Run_Start = ''
		set @Run_Finish = ''

		if IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
			Set @warning = @message
			
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
			RAISERROR (@msg, 11, 55)
		end
	end -- </AddTrigger>

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
		declare @RefDate datetime
		
		set @storagePathID = 0
		set @RefDate = GetDate()
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

		If IsNull(@AggregationJobDataset, 0) = 1
			Set @newDSStateID = 3
		Else
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
				@intStdID
				)
 
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount <> 1
		begin
			set @msg = 'Insert operation failed: "' + @datasetNum + '"'
			RAISERROR (@msg, 11, 7)
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

		if @requestID = 0
		begin -- <b3>
		
			if IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
				Set @warning = @message

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
		-- if a cart name is specified, update it for the 
		-- requested run
		---------------------------------------------------
		if @LCCartName NOT IN ('', 'no update')
		begin
		
			if IsNull(@message, '') <> '' and IsNull(@warning, '') = ''
				Set @warning = @message

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
				set @msg = 'Update LC cart name failed: "' + @datasetNum + '"->' + @message
				RAISERROR (@msg, 11, 21)
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
				DS_type_ID = @datasetTypeID, 
				DS_well_num = @wellNum, 
				DS_sec_sep = @secSep, 
				DS_folder_name = @folderName, 
				Exp_ID = @experimentID,
				DS_rating = @ratingID,
				DS_LC_column_ID = @columnID, 
				DS_wellplate_num = @wellplateNum, 
				DS_internal_standard_ID = @intStdID
		WHERE Dataset_ID = @datasetID
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


		---------------------------------------------------
		-- if a cart name is specified, update it for the 
		-- requested run
		---------------------------------------------------
		if @LCCartName NOT IN ('', 'no update')
		begin

			-- Lookup the RequestID for this dataset
			SELECT @requestID = RR.ID
			FROM T_Dataset DS
			     INNER JOIN T_Requested_Run RR
			       ON DS.Dataset_ID = RR.DatasetID
			WHERE DS.Dataset_ID = @datasetID

			If IsNull(@requestID, 0) = 0
			Begin
				set @WarningAddon = 'Dataset is not associated with a requested run; cannot update the LC Cart Name'
				set @warning = dbo.AppendToText(@warning, @WarningAddon, 0, '; ')
			End
			Begin
				Set @WarningAddon = ''
				exec @result = UpdateCartParameters
									'CartName',
									@requestID,
									@LCCartName output,
									@WarningAddon output
				--
				set @myError = @result
				--
				if @myError <> 0
				begin
					set @WarningAddon = 'Update LC cart name failed: ' + @WarningAddon
					set @warning = dbo.AppendToText(@warning, @WarningAddon, 0, '; ')
					set @myError = 0
				end
			End	
		end
					
		-- If rating changed from -5, -6, or -7 to 5, then check if any jobs exist for this dataset
		-- If no jobs are found, then call SchedulePredefinedAnalyses for this dataset
		-- Skip jobs with AJ_DatasetUnreviewed=1 when looking for existing jobs (these jobs were created before the dataset was dispositioned)
		If @ratingID >= 2 and IsNull(@curDSRatingID, -1000) IN (-5, -6, -7)
		Begin
			If Not Exists (SELECT * FROM T_Analysis_Job WHERE (AJ_datasetID = @datasetID) AND AJ_DatasetUnreviewed = 0 )
			Begin
				Exec SchedulePredefinedAnalyses @datasetNum, @callingUser=@callingUser
				
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


	-- Update @message if @warning is not empty	
	If IsNull(@Warning, '') <> ''
	Begin
		If IsNull(@message, '') = ''
			Set @message = 'Warning: ' + @Warning
		Else
			If @message <> @warning
				Set @message = 'Warning: ' + @warning + '; ' + @message
	End


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateDataset] TO [PNL\D3M580] AS [dbo]
GO
