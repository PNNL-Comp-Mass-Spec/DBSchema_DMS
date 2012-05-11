/****** Object:  StoredProcedure [dbo].[AddUpdateRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddUpdateRequestedRun
/****************************************************
**
**	Desc:	Adds a new entry to the requested dataset table
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	01/11/2002
**			02/15/2003
**			12/05/2003 grk - added wellplate stuff
**			01/05/2004 grk - added internal standard stuff
**			03/01/2004 grk - added manual identity calculation (removed identity column)
**			03/10/2004 grk - repaired manual identity calculation to include history table
**			07/15/2004 grk - added verification of experiment location aux info
**			11/26/2004 grk - changed type of @comment from text to varchar
**			01/12/2004 grk - fixed null return on check existing when table is empty
**			10/12/2005 grk - Added stuff for new work package and proposal fields.
**			02/21/2006 grk - Added stuff for EUS proposal and user tracking.
**			11/09/2006 grk - Fixed error message handling (Ticket #318)
**			01/12/2007 grk - added verification mode
**			01/31/2007 grk - added verification for @operPRN (Ticket #371)
**			03/19/2007 grk - added @defaultPriority (Ticket #421) (set it back to 0 on 04/25/2007)
**			04/25/2007 grk - get new ID from UDF (Ticket #446)
**			04/30/2007 grk - added better name validation (Ticket #450)
**			07/11/2007 grk - factored out EUS proposal validation (Ticket #499)
**			07/11/2007 grk - modified to look up EUS fields from sample prep request (Ticket #499)
**			07/17/2007 grk - Increased size of comment field (Ticket #500)
**			07/30/2007 mem - Now checking dataset type (@msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**			09/06/2007 grk - factored out instrument name and dataset type validation to ValidateInstrumentAndDatasetType (Ticket #512)
**			09/06/2007 grk - added call to LookupInstrumentRunInfoFromExperimentSamplePrep (Ticket #512)
**			09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**			02/13/2008 mem - Now checking for @badCh = '[space]' (Ticket #602)
**			04/09/2008 grk - Added secondary separation field (Ticket #658)
**			03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          06/03/2009 grk - look up work package (Ticket #739) 
**			07/27/2009 grk - added lookup for wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**			02/28/2010 grk - added add-auto mode
**			03/02/2010 grk - added status field to requested run
**			03/10/2010 grk - fixed issue with status validation
**			03/27/2010 grk - fixed problem creating new requests with "Completed" status.
**			04/20/2010 grk - fixed problem with experiment lookup validation
**			04/21/2010 grk - try-catch for error handling
**			05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @operPRN contains a person's real name rather than their username
**			08/27/2010 mem - Now auto-switching @instrumentName to be instrument group instead of instrument name
**			09/01/2010 mem - Added parameter @SkipTransactionRollback
**			09/09/2010 mem - Added parameter @AutoPopulateUserListIfBlank
**			07/29/2011 mem - Now querying T_Requested_Run with both @reqName and @status when the mode is update or check_update
**			11/29/2011 mem - Tweaked warning messages when checking for existing request
**			12/05/2011 mem - Updated @transName to use a custom transaction name
**			12/12/2011 mem - Updated call to ValidateEUSUsage to treat @eusUsageType as an input/output parameter
**			               - Added parameter @callingUser, which is passed to AlterEventLogEntryUser
**			12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in @comment
**			01/09/2012 grk - added @secSep to LookupInstrumentRunInfoFromExperimentSamplePrep
**
*****************************************************/
(
	@reqName varchar(128),
	@experimentNum varchar(64),
	@operPRN varchar(64),
	@instrumentName varchar(64),				-- Will typically contain an instrument group, not an instrument name; could also contain "(lookup)"
	@workPackage varchar(50),
	@msType varchar(20),
	@instrumentSettings varchar(512) = 'na',
	@wellplateNum varchar(64) = 'na',
	@wellNum varchar(24) = 'na',
	@internalStandard varchar(50) = 'na',
	@comment varchar(1024) = 'na',
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@mode varchar(12) = 'add',					-- 'add', 'check_add', 'update', 'check_update', or 'add-auto'
	@request int output,
	@message varchar(512) output,
	@secSep varchar(64) = 'LC-ISCO-Standard',
	@MRMAttachment varchar(128),
	@status VARCHAR(24) = 'Active',				-- 'Active', 'Inactive', 'Completed'
	@SkipTransactionRollback tinyint = 0,		-- This is set to 1 when stored procedure AddUpdateDataset calls this stored procedure
	@AutoPopulateUserListIfBlank tinyint = 0,	-- When 1, then will auto-populate @eusUsersList if it is empty and @eusUsageType = 'USER'
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @msg varchar(512)
	declare @InstrumentMatch varchar(64)
		
	-- default priority at which new requests will be created
	declare @defaultPriority int
	set @defaultPriority = 0
	
	BEGIN TRY

	---------------------------------------------------
	--
	---------------------------------------------------
	--
	DECLARE @requestOrigin CHAR(4)
	SET @requestOrigin = 'user'
	--
	IF @mode = 'add-auto'
	BEGIN
		SET @mode = 'add'
		SET @requestOrigin = 'auto'
	END  
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	if LEN(@reqName) < 1
		RAISERROR ('Request name was blank', 11, 110)
	--
	if LEN(@experimentNum) < 1
		RAISERROR ('Experiment number was blank', 11, 111)
	--
	if LEN(@operPRN) < 1
		RAISERROR ('Operator payroll number/HID was blank', 11, 113)
	--
	if LEN(@instrumentName) < 1
		RAISERROR ('Instrument group was blank', 11, 114)
	--
	if LEN(@msType) < 1
		RAISERROR ('Dataset type was blank', 11, 115)
	--
	if LEN(@workPackage) < 1
		RAISERROR ('Work package was blank', 11, 116)
	
	-- Assure that @comment is not null and assure that it doesn't have &quot;
	set @comment = IsNull(@comment, '')
	If @comment LIKE '%&quot;%'
		Set @comment = Replace(@comment, '&quot;', '"')

	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- validate name
	---------------------------------------------------

	declare @badCh varchar(128)
	set @badCh =  dbo.ValidateChars(@reqName, '')
	if @badCh <> ''
	begin
		If @badCh = '[space]'
			RAISERROR ('Requested run name may not contain spaces', 11, 1)
		Else
			RAISERROR ('Requested run name may not contain the character(s) "%s"', 11, 1, @badCh)
	end
		
	---------------------------------------------------
	-- Is entry already in database?
	-- Note that if a request is recycled, the old and new requests
	--  will have the same name but different IDs
	-- When @mode is Update, we should first look for an existing request
	--  with name @reqName and status @status
	-- If a match is not found, then simply look for a request with the same name
	---------------------------------------------------

	declare @requestID int = 0
	declare @oldEusProposalID varchar(10) = ''
	declare @oldStatus varchar(24) = ''
	declare @MatchFound tinyint = 0 
	
	If @mode IN ('update', 'check_update')
	Begin
		SELECT 
			@requestID = ISNULL(ID, 0), 
			@oldEusProposalID = RDS_EUS_Proposal_ID,
			@oldStatus = RDS_Status
		FROM T_Requested_Run
		WHERE RDS_Name = @reqName AND
		      RDS_Status = @status
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Error trying to find existing request: "$s"', 11, 7, @reqName)

		if @myRowCount > 0
			Set @MatchFound = 1
	End
	
	if @MatchFound = 0
	Begin
		SELECT 
			@requestID = ISNULL(ID, 0), 
			@oldEusProposalID = RDS_EUS_Proposal_ID,
			@oldStatus = RDS_Status
		FROM T_Requested_Run
		WHERE RDS_Name = @reqName
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Error trying to find existing request: "$s"', 11, 7, @reqName)
	End
	
	
	-- need non-null request even if we are just checking
	--
	set @request = @requestID

	-- cannot create an entry that already exists
	--
	if @requestID <> 0 and (@mode IN ('add', 'check_add'))
		RAISERROR ('Cannot add: Requested Run "%s" already in database; cannot add', 11, 4, @reqName)

	-- cannot update a non-existent entry
	--
	if @requestID = 0 and (@mode IN ('update', 'check_update'))
		RAISERROR ('Cannot update: Requested Run "%s" is not in database; cannot update', 11, 4, @reqName)
	
	---------------------------------------------------
	-- Confirm that the new status value is valid
	---------------------------------------------------
	--
	IF @mode IN ('add', 'check_add') AND @status ='Completed'
		SET @status = 'Active'
	--
	IF @mode IN ('add', 'check_add') AND (NOT (@status IN ('Active', 'Inactive', 'Completed')))
		RAISERROR ('Status "%s" is not valid', 11, 37, @status)
	--
	IF @mode IN ('update', 'check_update') AND (NOT (@status IN ('Active', 'Inactive', 'Completed')))
		RAISERROR ('Status "%s" is not valid', 11, 38, @status)
	--
	IF @mode IN ('update', 'check_update') AND (@status = 'Completed' AND @oldStatus <> 'Completed' )
	Begin
		set @msg = 'Cannot set status of request to "Completed" when existing status is "' + @oldStatus + '"'
		RAISERROR (@msg, 11, 39)
	End
	--
	IF @mode IN ('update', 'check_update') AND (@oldStatus = 'Completed' AND @status <> 'Completed')
		RAISERROR ('Cannot change status of a request that has been consumed by a dataset', 11, 40)

	Declare @StatusID int = 0
	
	SELECT @StatusID = State_ID
	FROM T_Requested_Run_State_Name
	WHERE (State_Name = @status)

	---------------------------------------------------
	-- get experiment ID from experiment number 
	-- (and validate that it exists in database)
	-- Also set wellplate and well from experiment
	-- if called for
	---------------------------------------------------

	declare @experimentID int
	SET @experimentID = 0

	SELECT 
		@experimentID = Exp_ID, 
		@wellplateNum = case when @wellplateNum = '(lookup)' then EX_wellplate_num else @wellplateNum end,
		@wellNum = case when @wellNum = '(lookup)' then EX_well_num else @wellNum end
	FROM T_Experiments
	WHERE Experiment_Num = @experimentNum
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
		RAISERROR ('Error looking up experiment', 11, 17)
	--
	if @experimentID = 0
		RAISERROR ('Could not find entry in database for experimentNum "%s"', 11, 18, @experimentNum)

	---------------------------------------------------
	-- verify user ID for operator PRN
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
			RAISERROR ('Could not find entry in database for operator PRN "%s"', 11, 19, @operPRN)
			return 51019
		End
	end
	
	---------------------------------------------------
	-- Lookup instrument run info fields 
	-- (only effective for experiments
	-- that have associated sample prep requests)
	---------------------------------------------------

	exec @myError = LookupInstrumentRunInfoFromExperimentSamplePrep
						@experimentNum,
						@instrumentName output,
						@msType output,
						@instrumentSettings output,
						@secSep output,
						@msg output
	if @myError <> 0
		RAISERROR ('LookupInstrumentRunInfoFromExperimentSamplePrep: %s', 11, 1, @msg)


	---------------------------------------------------
	-- Determine the Instrument Group
	---------------------------------------------------
	
	Declare @InstrumentGroup varchar(64) = ''
	
	-- Set the instrument group to @instrumentName for now
	set @InstrumentGroup = @instrumentName
	
	IF NOT EXISTS (SELECT * FROM T_Instrument_Group WHERE IN_Group = @InstrumentGroup)
	Begin
		-- Try to update instrument group using T_Instrument_Name
		SELECT @InstrumentGroup = IN_Group
		FROM T_Instrument_Name
		WHERE IN_Name = @instrumentName
	End
	
	---------------------------------------------------
	-- validate instrument group and dataset type
	---------------------------------------------------
	declare @datasetTypeID int
	--
	exec @myError = ValidateInstrumentGroupAndDatasetType
							@msType,
							@instrumentGroup,
							@datasetTypeID output,
							@msg output 
	if @myError <> 0
		RAISERROR ('ValidateInstrumentGroupAndDatasetType: %s', 11, 1, @msg)

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
		RAISERROR ('Error trying to look up separation type ID', 11, 98)
	--
	if @sepID = 0
		RAISERROR ('Could not resolve separation type to ID', 11, 99)

	---------------------------------------------------
	-- Resolve ID for MRM attachment
	---------------------------------------------------
	--
	declare @mrmAttachmentID int
	--
	set @MRMAttachment = ISNULL(@MRMAttachment, '')
	if @MRMAttachment <> ''
	begin
		SELECT @mrmAttachmentID = ID
		FROM T_Attachments
		WHERE Attachment_Name = @MRMAttachment
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Error trying to look up attachement ID', 11, 73)
	end
	
	---------------------------------------------------
	-- Lookup EUS field (only effective for experiments that have associated sample prep requests)
	-- This will update the data in @eusUsageType, @eusProposalID, or @eusUsersList if it is "(lookup)"
	---------------------------------------------------
	--
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
						@AutoPopulateUserListIfBlank
						
	if @myError <> 0
		RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)

	If IsNull(@msg, '') <> ''
		Set @message = @msg

	---------------------------------------------------
	--
	---------------------------------------------------
	declare @transName varchar(256)
	set @transName = 'AddUpdateRequestedRun_' + @reqName

	---------------------------------------------------
	-- Lookup misc fields (only effective for experiments
	-- that have associated sample prep requests)
	---------------------------------------------------
	exec @myError = LookupOtherFromExperimentSamplePrep 
						@experimentNum, 
						@workPackage output, 
						@msg  output
						
	if @myError <> 0
		RAISERROR ('LookupOtherFromExperimentSamplePrep: %s', 11, 1, @msg)	

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin
		-- Start transaction
		--
		begin transaction @transName
		
		INSERT INTO T_Requested_Run
			(
				RDS_name, 
				RDS_Oper_PRN, 
				RDS_comment, 
				RDS_created, 
				RDS_instrument_name, 
				RDS_type_ID, 
				RDS_instrument_setting, 
				RDS_priority, 
				Exp_ID,
				RDS_WorkPackage, 
				RDS_Well_Plate_Num,
				RDS_Well_Num,
				RDS_internal_standard,
				RDS_EUS_Proposal_ID,
				RDS_EUS_UsageType,
				RDS_Sec_Sep,
				RDS_MRM_Attachment,
				RDS_Origin,
				RDS_Status
			) 
			VALUES 
			(
				@reqName, 
				@operPRN, 
				@comment, 
				GETDATE(), 
				@instrumentGroup, 
				@datasetTypeID, 
				@instrumentSettings, 
				@defaultPriority, -- priority
				@experimentID,
				@workPackage,
				@wellplateNum,
				@wellNum,
				@internalStandard,
				@eusProposalID,
				@eusUsageTypeID,
				@secSep,
				@mrmAttachmentID,
				@requestOrigin,
				@status
			)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Insert operation failed: "%s"', 11, 7, @reqName)
		
		set @request = IDENT_CURRENT('T_Requested_Run')

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
		Begin
			Exec AlterEventLogEntryUser 11, @request, @StatusID, @callingUser
		End

		-- assign users to the request
		--
		exec @myError = AssignEUSUsersToRequestedRun
								@request,
								@eusProposalID,
								@eusUsersList,
								@msg output
		--
		if @myError <> 0
			RAISERROR ('AssignEUSUsersToRequestedRun: %s', 11, 19, @msg)

		commit transaction @transName
		
	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin	
		begin transaction @transName

		set @myError = 0
		--
		UPDATE T_Requested_Run 
		SET 
			RDS_Oper_PRN = @operPRN, 
			RDS_comment = @comment, 
			RDS_instrument_name = @instrumentGroup, 
			RDS_type_ID = @datasetTypeID, 
			RDS_instrument_setting = @instrumentSettings, 
			Exp_ID = @experimentID,
			RDS_WorkPackage = @workPackage, 
			RDS_Well_Plate_Num = @wellplateNum,
			RDS_Well_Num = @wellNum,
			RDS_internal_standard = @internalStandard,
			RDS_EUS_Proposal_ID = @eusProposalID,
			RDS_EUS_UsageType = @eusUsageTypeID,
			RDS_Sec_Sep = @secSep,
			RDS_MRM_Attachment = @mrmAttachmentID,
			RDS_Status = @status,
			RDS_created = CASE WHEN @oldStatus = 'Inactive' AND @status = 'Active' THEN GETDATE() ELSE RDS_created END
		WHERE (ID = @requestID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Update operation failed: "%s"', 11, 4, @reqName)

		-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
		Begin
			Exec AlterEventLogEntryUser 11, @requestID, @StatusID, @callingUser
		End
		
		-- assign users to the request
		--
		exec @myError = AssignEUSUsersToRequestedRun
								@requestID,
								@eusProposalID,
								@eusUsersList,
								@msg output
		--
		if @myError <> 0
			RAISERROR ('AssignEUSUsersToRequestedRun: %s', 11, 20, @msg)

		commit transaction @transName
	end -- update mode

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0 And IsNull(@SkipTransactionRollback, 0) = 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRun] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateRequestedRun] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateRequestedRun] TO [PNL\D3M580] AS [dbo]
GO
